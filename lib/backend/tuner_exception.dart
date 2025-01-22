import 'package:stronzflix/backend/api/site.dart';
import 'package:sutils/logic/errors/stronz_loading_warn.dart';

class TunerException extends StronzLoadingWarn {
    TunerException(Site site)
        : super("Non è stato possibile sintonizzare ${site}.\nIl caricamento continuerà senza di esso.");
}
