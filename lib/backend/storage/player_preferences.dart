import 'package:stronzflix/backend/storage/local_storage.dart';

class PlayerPreferences extends LocalStorage {
    static final PlayerPreferences instance = PlayerPreferences._();
    PlayerPreferences._() : super({
        "volume": 100.0,
    });

    static double get volume => PlayerPreferences.instance["volume"];
    static set volume(double value) => PlayerPreferences.instance["volume"] = value;
}
