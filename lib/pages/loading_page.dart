import 'package:flutter/material.dart';
import 'package:stronzflix/backend/backend.dart';
import 'package:stronzflix/pages/home_page.dart';

class LoadingPage extends StatefulWidget {
    const LoadingPage({super.key});

    @override
    State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _animation;
    double _currentPercentage = 0.0;
    bool _hasError = false;

    @override
    void initState() {
        super.initState();
        this._controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
        );

        this._animation = Tween<double>(
            begin: this._currentPercentage,
            end: this._currentPercentage,
        ).animate(this._controller);

        Backend.load().listen((percentage) {
            super.setState(() {
                this._hasError = false;
                this._animation = Tween<double>(
                    begin: this._currentPercentage,
                    end: percentage,
                ).animate(this._controller);
                this._currentPercentage = percentage;
            });
            this._controller.forward(from: 0);
        },
        onError: (_) {
            super.setState(() {
                this._hasError = true;
            });
        },
        onDone: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage())
            );
        }
        );
    }

    @override
    void dispose() {
        this._controller.dispose();
        super.dispose();
    }

    Widget _buildError(BuildContext context) {
        return const Center(
            child: Row(
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
            )
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

    Widget _buildContent(BuildContext context) {
        if(this._hasError)
            return this._buildError(context);
        return this._buildLoading(context);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(30),
                child: Center(
                    child: this._buildContent(context),
                )
            )
        );
    }
}
