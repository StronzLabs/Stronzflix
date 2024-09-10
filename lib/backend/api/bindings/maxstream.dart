import 'package:stronzflix/backend/api/bindings/vjsplayer.dart';
import 'package:stronzflix/backend/api/player.dart';
import 'package:sutils/sutils.dart';

class Maxstream extends Player {
    static Player instance = Maxstream._();
    Maxstream._() : super("Maxstream");

    @override
    Future<Uri> getSource(Uri uri) async {
        uri = await HTTP.redirect(uri);
        return VJSPlayer.instance.getSource(uri);
    }
}
