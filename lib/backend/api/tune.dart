import 'package:stronzflix/utils/simple_http.dart' as http;

class Tuner {

    static const Duration timeout = Duration(milliseconds: 2500);

    final bool Function(String) validator;
    const Tuner(this.validator);
    
    Future<bool> validateDomain(String domain) async {
        domain = domain.startsWith('https://') ? domain : 'https://${domain}';
        try {
            String body = await http.get(domain, followRedirects: false).timeout(Tuner.timeout).onError((error, stackTrace) => "");
            return this.validator(body);
        } catch (_) {
            return false;
        }
    }

    Future<List<String>> _getDomains() async {
        String response = await http.get("https://data.iana.org/TLD/tlds-alpha-by-domain.txt");
        List<String> domains = response.split("\n").where((String line) => !line.startsWith("#")).toList();
        domains.shuffle();
        return domains;
    }

    Stream<dynamic> findDomain(String subdomain) async* {
        String? result;
        double progress = 0.0;
        yield progress;

        List<String> domains = await this._getDomains();

        int groupSize = 10;
        for (int i = 0; i < domains.length; i += groupSize) {
            List<String> domainGroup = domains.sublist(i, i + groupSize > domains.length ? domains.length : i + groupSize);
            List<Future<bool>> validations = domainGroup.map((String domain) => this.validateDomain("${subdomain}.${domain}")).toList();
            List<bool> results = await Future.wait(validations);

            if (results.contains(true)) {
                result = domainGroup[results.indexWhere((bool result) => result)];
                break;
            }

            progress += groupSize / domains.length;
            yield progress;
        }

        yield result;
    }
}
