import 'dart:async';

import 'package:flutter/material.dart';

abstract class Initializable {
    late Future<void> _initialized;
    final StreamController<dynamic> _progress = StreamController.broadcast();

    Initializable([void Function(Initializable)? then]) {
        this._initialized = this.construct().then((_) {
            then?.call(this);
            this._progress.add(1.0);
            this._progress.close();
        }).onError((error, stackTrace) {
            this._progress.addError(error!, stackTrace);
        });
    }

    @protected
    void reportProgress(double progress) => this._progress.add(progress);
    Stream<dynamic> get progress => this._progress.stream;

    Future<void> construct() async {}
    Future<void> ensureInitialized() => this._initialized;
}
