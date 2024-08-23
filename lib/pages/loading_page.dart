import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:media_kit/media_kit.dart';
import 'package:stronzflix/backend/api/bindings/animesaturn.dart';
import 'package:stronzflix/backend/api/bindings/streampeaker.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/bindings/streamingcommunity.dart';
import 'package:stronzflix/backend/api/bindings/vixxcloud.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/backend/storage/player_preferences.dart';
import 'package:stronzflix/backend/storage/saved_titles.dart';
import 'package:stronzflix/backend/peer/peer_manager.dart';
import 'package:stronzflix/backend/storage/settings.dart';
import 'package:stronzflix/backend/update/version.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';
import 'package:stronzflix/dialogs/update_dialog.dart';
import 'package:stronzflix/utils/platform.dart';
import 'package:window_manager/window_manager.dart';

class LoadingPage extends StatefulWidget {
    const LoadingPage({super.key});

    @override
    State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
    
    late final AnimationController _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
    );

    late Animation<double> _animation = Tween<double>(
        begin: this._currentPercentage,
        end: this._currentPercentage
    ).animate(this._controller);

    double _currentPercentage = 0.0;
    String? _error;
    Timer? _additionalInfoTimer;
    bool _showAdditionalInfo = false;

    String _splash = "Caricamento dei contenuti";
    bool _update = false;

    Future<Stream<double>?> _checkUpdate() async {
        bool shouldUpdate = await VersionChecker.shouldUpdate();
        if(!shouldUpdate)
            return null;

        if(!super.mounted)
            return null;

        Stream<double>? progressStream = await showDialog<Stream<double>?>(
            context: context,
            builder: (context) => const UpdateDialog()
        );
        return progressStream;
    }

    Stream<double> _load(List<Future> loadingPhase) async* {
        for (int i = 0; i < loadingPhase.length; i++) {
            yield (i + 1) / loadingPhase.length;
            await loadingPhase[i];
        }
    }

    Stream<double> _dynamicLoad(List<Stream<dynamic>> loadingPhase) async* {
        StreamController<dynamic> loading = StreamController.broadcast();
        int done = 0;
        List<StreamSubscription> subscriptions = loadingPhase.map((stream) {
            int index = loadingPhase.indexOf(stream);
            return stream.listen(
                (percentage) => loading.add([ index, percentage ]),
                onError: (error) => loading.addError(error),
                onDone: () {
                    loading.add([ index, 1.0 ]);
                    if(++done == loadingPhase.length)
                        loading.close();
                }
            );
        }).toList();
        
        List<double> advance = List.filled(loadingPhase.length, 0.0);
        await for (dynamic percentage in loading.stream) {
            if (percentage is List) {
                advance[percentage[0]] = percentage[1] / loadingPhase.length;
                yield advance.reduce((a, b) => a + b);
            }
            else {
                for (StreamSubscription<dynamic> subscription in subscriptions)
                    subscription.cancel();
                throw percentage;
            }
        }

        for (StreamSubscription<dynamic> subscription in subscriptions)
            subscription.cancel();
    }

    Future<bool> _checkConnection() async {
        if((await Connectivity().checkConnectivity()).contains(ConnectivityResult.none)) {
            if(super.mounted && !await ConfirmationDialog.ask(
                super.context,
                "Connessione Assente",
                "Non è presente una connessione ad internet. Vuoi continuare in modalità offline?"
            ))
                exit(0);
            return false;
        }
        return true;
    }

    Stream<double> _doLoading() async* {
        List<double> phasesWeights = [ 0.01, 0.97, 0.01, 0.01 ];
        double advance = 0.0;

        MediaKit.ensureInitialized();
        
        await for (double percentage in this._load([
            if(SPlatform.isDesktop)
                windowManager.ensureInitialized(),
            Settings.instance.ensureInitialized()
        ]))
            yield advance + percentage * phasesWeights[0];
        advance += phasesWeights[0];

        Settings.online = await this._checkConnection();
        if(!Settings.online) {
            Settings.site = LocalSite.instance;
            Settings.update();
            return;
        }

        Stream<double>? updatePercentage = await this._checkUpdate();
        if(updatePercentage != null) {
            super.setState(() => this._splash = "Aggiornamento in corso");
            this._update = true;
            await for (double percentage in updatePercentage)
                yield percentage;
            return;
        }

        this._additionalInfoTimer = Timer(const Duration(seconds: 5), () {
            if(!super.mounted)
                return;
            super.setState(() => this._showAdditionalInfo = true);
        });

        await for (double percentage in this._dynamicLoad([
            StreamingCommunity.instance.progress,
            LocalSite.instance.progress,
            AnimeSaturn.instance.progress,
        ]))
            yield advance + percentage * phasesWeights[1]; 
        advance += phasesWeights[1];

        await for (double percentage in this._load([
            LocalPlayer.instance.ensureInitialized(),
            Streampeaker.instance.ensureInitialized(),
            VixxCloud.instance.ensureInitialized(),
        ]))
            yield advance + percentage * phasesWeights[2];
        advance += phasesWeights[2];

        await for (double percentage in this._load([
            KeepWatching.instance.ensureInitialized(),
            SavedTitles.instance.ensureInitialized(),
            PlayerPreferences.instance.ensureInitialized(),
            PeerManager.init(),
        ]))
            yield advance + percentage * phasesWeights[3];
        advance += phasesWeights[3];

        yield advance;
    }

    @override
    void initState() {
        super.initState();

        this._doLoading().listen(
            (percentage) {
                super.setState(() {
                    this._animation = Tween<double>(
                        begin: this._currentPercentage,
                        end: percentage
                    ).animate(this._controller);
                    this._currentPercentage = percentage;
                });
                this._controller.forward(from: 0);
            },
            cancelOnError: true,
            onError: (error) => super.setState(() => this._error = error.toString()),
            onDone: () {
                if(!this._update)
                    Navigator.of(context).pushReplacementNamed("/home");
            }
        );
    }

    @override
    void dispose() {
        this._controller.dispose();
        this._additionalInfoTimer?.cancel();
        super.dispose();
    }

    Widget _buildError(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.error,
                            color: Colors.red,
                            size: 30,
                        ),
                        SizedBox(width: 10),
                        Text("Errore",
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.red
                            ),
                            textAlign: TextAlign.center
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.error,
                            color: Colors.red,
                            size: 30
                        )
                    ]
                ),
                Text("< ${this._error!} >",
                    style: const TextStyle(
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.wavy,
                        decorationColor: Colors.red,
                        decorationThickness: 2.0,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red
                    ),
                    textAlign: TextAlign.center
                ),
            ],
        );
    }

    Widget _buildLoading(BuildContext context) {
        return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Text(this._splash,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                    width: 700,
                    child: AnimatedBuilder(
                        animation: this._animation,
                        builder: (context, child) {
                            return LinearProgressIndicator(
                                value: this._animation.value,
                            );
                        }
                    )
                ),
                const SizedBox(height: 20),
                Text(this._showAdditionalInfo
                    ? "La sintonizzazione è in corso, potrebbero volerci alcuni minuti"
                    : "",
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                )
            ]
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(30),
                child: Stack(
                    alignment: Alignment.center,
                    children: [
                        Center(
                            child: SvgPicture.asset("assets/logo.svg",
                                width: 200,
                                height: 200,
                            ),
                        ),
                        Positioned(
                            top: MediaQuery.of(context).size.height / 2 + 75,
                            width: MediaQuery.of(context).size.width - 30,
                            child: this._error != null
                                    ? this._buildError(context)
                                    : this._buildLoading(context),
                        ),
                    ]
                )
            )
        );
    }
}
