import 'package:stronzflix/utils/initializable.dart';
import 'package:sutils/utils/simple_http.dart';

abstract class Middleware extends Initializable {
    final String name;

    Middleware(this.name) : super((self) => Middleware._registry[name] = self as Middleware);

    Future<Uri> pass(Uri uri, String body);
    bool detect(Uri uri, String body);

    static final Map<String, Middleware> _registry = {};
    static List<Middleware> get middlewares => _registry.values.toList();
    static Middleware? get(String name) => _registry[name];

    static Middleware? _detect(Uri uri, String body) {
        for (Middleware middleware in Middleware.middlewares)
            if (middleware.detect(uri, body))
                return middleware;
        return null;
    }

    static Future<Uri> resolve(Uri uri) async {
        while(true) {
            String middlewareBody = await HTTP.get(uri);
            Middleware? middleware = Middleware._detect(uri, middlewareBody);
            if(middleware == null)
                break;
            try {
                uri = await middleware.pass(uri, middlewareBody);
            } catch(_) {
                print("Nop");
                break;
            }
        }
        return uri;
    }
}
