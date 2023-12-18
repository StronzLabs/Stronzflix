import 'package:http/http.dart' as http;

Future<String> get(String url, {Map<String, String>? headers}) async {

    headers ??= {};
    if(!headers.containsKey("User-Agent"))
        headers["User-Agent"] = "Stronzflix";

    return (await http.get(Uri.parse(url), headers: headers)).body;
}
