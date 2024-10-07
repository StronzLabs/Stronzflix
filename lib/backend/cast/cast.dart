import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stronzflix/backend/cast/castv2.dart';
import 'package:stronzflix/backend/cast/dlna.dart';

abstract class CasterDevice {
    String get name;

    const CasterDevice();
}

abstract class CasterInterface {
    const CasterInterface();

    Future<List<CasterDevice>> discovery();
    Future<void> connect(CasterDevice device);
    Future<void> disconnect();

    Future<bool> loadMedia(Uri uri);
    Future<void> play();
    Future<void> pause();
    Future<void> stop();
    Future<void> seekTo(Duration position);
    Future<void> setVolume(double volume);
}

class CasterMediaState {
    final bool? playing;
    final bool? buffering;
    final bool? completed;
    final Duration? position;
    final Duration? duration;

    const CasterMediaState({
        required this.playing,
        required this.buffering,
        required this.completed,
        required this.position,
        required this.duration,
    });
}

class CasterState extends ChangeNotifier {
    bool _discovering = false;
    bool get discovering => this._discovering;
    set discovering(bool value) {
        this._discovering = value;
        super.notifyListeners();
    }

    bool _connecting = false;
    bool get connecting => this._connecting;
    set connecting(bool value) {
        this._connecting = value;
        super.notifyListeners();
    }

    bool _connected = false;
    bool get connected => this._connected;
    set connected(bool value) {
        this._connected = value;
        super.notifyListeners();
    }

    List<CasterDevice> _devices = [];
    List<CasterDevice> get devices => this._devices;
    set devices(List<CasterDevice> value) {
        this._devices = value;
        super.notifyListeners();
    }

    CasterMediaState _mediaState = const CasterMediaState(
        playing: false,
        buffering: false,
        completed: false,
        position: Duration.zero,
        duration: Duration.zero,
    );
    CasterMediaState get mediaState => this._mediaState;
    set mediaState(CasterMediaState value) {
        this._mediaState = value;
        super.notifyListeners();
    }
}

class CastManager {

    static final CasterState state = CasterState();
    static get discovering => CastManager.state.discovering;
    static get connecting => CastManager.state.connecting;
    static get connected => CastManager.state.connected;
    static get devices => CastManager.state.devices;

    static final List<CasterInterface> _interfaces = [
        CastV2(),
        DLNA(),
    ];

    static CasterInterface? _activeInterface;

    static Future<List<CasterDevice>> discovery() async {
        CastManager.state.discovering = true;

        CastManager.state.devices = [
            for (CasterInterface interface in CastManager._interfaces)
                ...await interface.discovery()
        ];

        CastManager.state.discovering = false;
        return CastManager.state.devices;
    }

    static Future<void> connect(CasterDevice device) async {
        await CastManager.disconnect();
        CastManager.state.connecting = true;

        switch (device.runtimeType) {
            case CastV2Device:
                CastManager._activeInterface = CastManager._interfaces.firstWhere((interface) => interface is CastV2);
                break;
            case DlnaDevice:
                CastManager._activeInterface = CastManager._interfaces.firstWhere((interface) => interface is DLNA);
                break;
            default:
                throw UnimplementedError();
        }
        await CastManager._activeInterface!.connect(device);

        CastManager.state.connecting = false;
    }

    static Future<void> disconnect() async {
        await CastManager._activeInterface?.disconnect();
        CastManager.state.connected = false;
    }

    static Future<bool> loadMedia(Uri uri) async => await CastManager._activeInterface?.loadMedia(uri) ?? false;
    static Future<void> play() async => await CastManager._activeInterface?.play();
    static Future<void> pause() async => await CastManager._activeInterface?.pause();
    static Future<void> stop() async => await CastManager._activeInterface?.stop();
    static Future<void> seekTo(Duration position) async => await CastManager._activeInterface?.seekTo(position);
    static Future<void> setVolume(double volume) async => await CastManager._activeInterface?.setVolume(volume);
}
