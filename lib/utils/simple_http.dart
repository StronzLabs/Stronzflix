import 'package:http/http.dart' as http;

Future<String> get(String url, {Map<String, String>? headers}) async => (await http.get(Uri.parse(url), headers: headers)).body;
