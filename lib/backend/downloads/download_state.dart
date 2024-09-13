import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/downloads/download_manager.dart';

class DownloadState extends ValueNotifier<double> {
    double get progress => super.value;
    final String name;

    bool _paused = false;
    bool get isPaused => this._paused;
    late Completer<void> _resume;
    Future<void> get resumeFuture => this._resume.future;

    bool _canceled = false;
    bool get isCanceled => this._canceled;

    bool _error = false;
    bool get hasError => this._error;

    final DownloadOptions options;
    
    DownloadState(this.name, this.options, [super.value = 0]);

    void resume() {
        if(this._paused) {
            this._paused = false;
            this._resume.complete();
            super.notifyListeners();
        }
    }

    void pause() {
        if(!this._paused) {
            this._paused = true;
            this._resume = Completer<void>();
            super.notifyListeners();
        }
    }

    void cancel() {
        this._canceled = true;
        DownloadManager.removeDownload(this);
        super.notifyListeners();
    }

    void setError() {
        this._error = true;
        super.notifyListeners();
    }
}
