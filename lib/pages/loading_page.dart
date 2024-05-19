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

    Stream<double> _doLoading() async* {
        bool shouldUpdate = await VersionChecker.shouldUpdate();
        if(shouldUpdate && super.mounted) {
            bool updating = await showDialog<bool?>(
                context: context,
                builder: (context) => const UpdateDialog()
            ) ?? false;
            super.setState(() => this._updating = updating);
            if(this._updating)
                return;
        }

        await Settings.load();

        List<Future> operations = [
            StreamingCommunity.instance.ensureInitialized(),
            VixxCloud.instance.ensureInitialized(),
            LocalSite.instance.ensureInitialized(),
            LocalPlayer.instance.ensureInitialized(),
            AnimeSaturn.instance.ensureInitialized(),
            Streampeaker.instance.ensureInitialized(),
        ];

        for (int i = 0; i < operations.length; i++) {
            yield (i + 1) / operations.length;
            await operations[i];
        }

        await KeepWatching.init();
        PeerManager.init();
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
