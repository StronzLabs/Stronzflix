import 'dart:async';

import 'package:flutter/material.dart';

class LoadingDialog {
    static Future<T> load<T>(BuildContext context, Future<T> Function() future) async {
        return await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: FutureBuilder(
                    future: future(),
                    builder: ((context, snapshot) {
                        if(snapshot.connectionState == ConnectionState.done) {
                            Navigator.of(context).pop(snapshot.data);
                            return const SizedBox.shrink();
                        }

                        return const Center(
                            child: CircularProgressIndicator(),
                        );
                    })
                )
            )
        );
    }

    static Future<T> progress<T>(BuildContext context, Stream<double> Function() stream) async {
        return await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: StreamBuilder(
                    stream: stream(),
                    builder: ((context, snapshot) {
                        if(snapshot.connectionState == ConnectionState.done) {
                            Navigator.of(context).pop(snapshot.data);
                            return const SizedBox.shrink();
                        }

                        return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                const Text("Caricamento..."),
                                SizedBox(
                                    width: 200,
                                    child: LinearProgressIndicator(
                                        value: snapshot.data ?? 0,
                                    )
                                )
                            ]
                        );
                    })
                )
            )
        );
    }
}
