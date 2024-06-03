import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stronzflix/backend/api/bindings/animesaturn.dart';
import 'package:stronzflix/backend/api/bindings/streampeaker.dart';
import 'package:stronzflix/backend/api/bindings/local.dart';
import 'package:stronzflix/backend/api/bindings/streamingcommunity.dart';
import 'package:stronzflix/backend/api/bindings/vixxcloud.dart';
import 'package:stronzflix/backend/keep_watching.dart';
import 'package:stronzflix/backend/peer/peer_manager.dart';
import 'package:stronzflix/backend/settings.dart';
import 'package:stronzflix/backend/version.dart';
import 'package:stronzflix/dialogs/confirmation_dialog.dart';
import 'package:stronzflix/dialogs/update_dialog.dart';

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
    bool _updating = false;
    Timer? _additionalInfoTimer;
    bool _showAdditionalInfo = false;

    Future<bool> _checkUpdate() async {
        bool shouldUpdate = await VersionChecker.shouldUpdate();
        if(!shouldUpdate)
            return false;

        if(!super.mounted)
            return false;

        bool updating = await showDialog<bool?>(
            context: context,
            builder: (context) => const UpdateDialog()
        ) ?? false;
        super.setState(() => this._updating = updating);
        return updating;
    }

    Stream<double> _load(List<Future> loadingPhase) async* {
        for (int i = 0; i < loadingPhase.length; i++) {
            yield (i + 1) / loadingPhase.length / 3;
            await loadingPhase[i];
        }
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
        double phases = 3.0;
        double step = 1.0 / 3.0;
        
        await for (double percentage in this._load([
            Settings.load()
        ]))
            yield step * 0 + percentage / phases;

        Settings.online = await this._checkConnection();
        if(!Settings.online) {
            Settings.site = LocalSite.instance.name;
            Settings.save();
            return;
        }

        if(await this._checkUpdate())
            return;

        this._additionalInfoTimer = Timer(const Duration(seconds: 5), () {
            if(!super.mounted)
                return;
            super.setState(() => this._showAdditionalInfo = true);
        });

        await for (double percentage in this._load([
            StreamingCommunity.instance.ensureInitialized(),
            VixxCloud.instance.ensureInitialized(),
            LocalSite.instance.ensureInitialized(),
            LocalPlayer.instance.ensureInitialized(),
            AnimeSaturn.instance.ensureInitialized(),
            Streampeaker.instance.ensureInitialized(),
        ]))
            yield step * 1 + percentage / phases;

        await for (double percentage in this._load([
            KeepWatching.init(),
            PeerManager.init(),
        ]))
            yield step * 2 + percentage / phases;
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
                if(!this._updating)
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
                            size: 50,
                        ),
                        SizedBox(width: 10),
                        Text("Errore di caricamento",
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.red
                            ),
                            textAlign: TextAlign.center
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.error,
                            color: Colors.red,
                            size: 50
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
                const Text("Caricamento dei contenuti",
                    style: TextStyle(
                        fontSize: 30,
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

    Widget _buildUpdating(BuildContext context) {
        return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Text("Aggiornamento in corso",
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                    ),
                    textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                SizedBox(
                    width: 700,
                    child: LinearProgressIndicator(),
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
                    children: [
                        Center(
                            child: SvgPicture.asset("assets/logo.svg",
                                width: 200,
                                height: 200,
                            ),
                        ),
                        Transform.translate(
                            offset: const Offset(0, 150),
                            child: Center(
                                child: this._updating
                                ? this._buildUpdating(context)
                                : this._error != null
                                    ? this._buildError(context)
                                    : this._buildLoading(context),
                            )
                        )
                    ]
                )
            )
        );
    }
}
