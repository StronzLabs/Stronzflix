import 'package:cast/cast.dart';
import 'package:flutter/material.dart';
import 'package:stronzflix/backend/api/media.dart';

class PlayerInfo extends ChangeNotifier {
    bool _isCasting = false;
    CastDevice? _device;

    bool get isCasting => this._isCasting;
    CastDevice? get device => this._device;

    Watchable? _watchable;
    Watchable get watchable => this._watchable!;

    int? _duration;
    int? _timestamp;
    int get duration => this._duration!;
    int get timestamp => this._timestamp!;
    bool get hasStarted => this._duration != null;

    Duration _startAt = Duration.zero;
    Duration get startAt => this._startAt;

    void setStartAt(Duration startAt) {
        this._startAt = startAt;
    }    

    void updateTimes(int duration, int timestamp) {
        this._duration = duration;
        this._timestamp = timestamp;
    }

    Future<List<CastDevice>>? _devices;
    Future<List<CastDevice>> get devices async {
        if(this._devices == null)
            this.startCastDiscovery();
        return this._devices!;
    }

    void startCastDiscovery() {
        this._devices = CastDiscoveryService().search();
        this._devices!.then((devices) {
            if(super.hasListeners)
                notifyListeners();
        }).onError((error, stackTrace) {
            this._devices = Future.value([]);
        });
    }

    void startWatching(Watchable watchable) {
        this._watchable = watchable;
    }

    void startCasting(CastDevice device) {
        this._isCasting = true;
        this._device = device;
        notifyListeners();
    }

    void stopCasting() {
        this._isCasting = false;
        this._device = null;
        notifyListeners();
    }

    void switchTo(Watchable watchable) {
        this._watchable = watchable;
        notifyListeners();
    }
}
