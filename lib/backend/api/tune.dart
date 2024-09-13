import 'dart:convert';

import 'package:sutils/sutils.dart';

class Tuner {

    static const Duration timeout = Duration(milliseconds: 2500);
    static late final List<String> cache;

    final bool Function(String) validator;
    final int cacheId;
    const Tuner(this.validator, this.cacheId);

    static Future<void> prepareCache() async {
        Map<String, dynamic> release = jsonDecode(await HTTP.get('https://api.github.com/repos/StronzLabs/StronzTuner/releases/tags/cache'));
        String body = String.fromCharCodes(base64Decode(release["body"]));
        List<String> cache = body.split("|");
        Tuner.cache = cache;
    }
    
    Future<bool> validateDomain(String domain) async {
        domain = domain.startsWith('https://') ? domain : 'https://${domain}';
        try {
            String body = await HTTP.get(domain, followRedirects: false, timeout: Tuner.timeout).onError((error, stackTrace) => "");
            return this.validator(body);
        } catch (_) {
            return false;
        }
    }

    Future<List<String>> _getDomains() async {
        String response = await HTTP.get("https://data.iana.org/TLD/tlds-alpha-by-domain.txt");
        List<String> domains = response.split("\n").where((String line) => !line.startsWith("#")).toList();
        domains.shuffle();
        domains.insert(0, Tuner.cache[this.cacheId]);
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

            // TODO: maybe use a logarithmic scale for progress instead of linear
            progress += groupSize / domains.length;
            yield progress;
        }

        yield result;
    }
}
