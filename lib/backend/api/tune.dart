import 'package:stronzflix/utils/simple_http.dart' as http;

class Tuner {
    final bool Function(String) validator;
    const Tuner(this.validator);
    
    Future<bool> validateDomain(String domain) async {
        domain = domain.startsWith('https://') ? domain : 'https://${domain}';
        String body = await http.get(domain, followRedirects: false).onError((error, stackTrace) => "");
        return this.validator(body);
    }

    Future<List<String>> _getDomains() async {
        String response = await http.get("https://data.iana.org/TLD/tlds-alpha-by-domain.txt");
        return response.split("\n").where((String line) => !line.startsWith("#")).toList();
    }

    Stream<dynamic> findDomain(String subdomain) async* {
        String? result;
        double progress = 0.0;
        yield progress;

        List<String> domains = await this._getDomains();
        
        for (String domain in domains) {
            if (await this.validateDomain("${subdomain}.${domain}")) {
                result = domain;
                break;
            }

            progress += 1.0 / domains.length;
            yield progress;
        }

        yield result;
    }
}
