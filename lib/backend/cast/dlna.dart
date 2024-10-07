import 'dart:async';

import 'package:castscreen/castscreen.dart';
import 'package:stronzflix/backend/cast/cast.dart';

class DlnaDevice extends CasterDevice {
    final Device device;
    
    @override
    String get name => this.device.spec.friendlyName;

    const DlnaDevice(this.device);
} 

class DLNA extends CasterInterface {

    DlnaDevice? _device;

    Timer? _pollTimer;

    @override
    Future<List<CasterDevice>> discovery() async {
        List<Device> devices = await CastScreen.discoverDevice(
            port: 1901,
            ST: "urn:schemas-upnp-org:device:MediaRenderer:1",
        );
        return devices.map((device) => DlnaDevice(device)).toList();
    }
    
    @override
    Future<void> connect(CasterDevice device) async {
        if(device is! DlnaDevice)
            return;

        CastManager.state.connecting = true;

        CastManager.state.connected = await device.device.alive();
        if(CastManager.state.connected) {
            this._device = device;

            this._pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
                this._device?.device.getPositionInfo(const PositionInfoInput()).then((positionInfo) {
                    this._device?.device.getTransportInfo(const TransportInfoInput()).then((transportInfo) {
                        this._onStatus(positionInfo, transportInfo);
                    });
                });
            });
        }


        CastManager.state.connecting = false;
    }

    @override
    Future<void> disconnect() async {
        this._pollTimer?.cancel();
        CastManager.state.connected = false;
    }

    @override
    Future<bool> loadMedia(Uri uri) async {
        await this._device?.device.setAVTransportURI(SetAVTransportURIInput(uri.toString()));
        return true;
    }

    @override
    Future<void> pause() async {
        await this._device?.device.pause(const PauseInput());
    }

    @override
    Future<void> play() async {
        await this._device?.device.play(const PlayInput());
    }

    @override
    Future<void> seekTo(Duration position) async {
        int hours = position.inHours;
        int minutes = position.inMinutes % 60;
        int seconds = position.inSeconds % 60;
        await this._device?.device.seek(SeekInput(
            "REL_TIME",
            "${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
        ));
    }

    @override
    Future<void> setVolume(double volume) async {
        await this._device?.device.setVolume(SetVolumeInput((volume * 100).toInt()));
    }

    @override
    Future<void> stop() async {
        await this._device?.device.stop(const StopInput());
    }

    void _onStatus(PositionInfoOutput positionInfo, TransportInfoOutput transportInfo) {
        CasterMediaState mediaState = CasterMediaState(
            playing: transportInfo.CurrentTransportState == "PLAYING",
            buffering: transportInfo.CurrentTransportState == "TRANSITIONING",
            completed: positionInfo.TrackDuration == positionInfo.AbsTime,
            position: Duration(
                hours: int.parse(positionInfo.AbsTime.split(":")[0]),
                minutes: int.parse(positionInfo.AbsTime.split(":")[1]),
                seconds: int.parse(positionInfo.AbsTime.split(":")[2].split(".")[0]),
            ),
            duration: Duration(
                hours: int.parse(positionInfo.TrackDuration.split(":")[0]),
                minutes: int.parse(positionInfo.TrackDuration.split(":")[1]),
                seconds: int.parse(positionInfo.TrackDuration.split(":")[2].split(".")[0]),
            ),
        );

        CastManager.state.mediaState = mediaState;
    }
}
