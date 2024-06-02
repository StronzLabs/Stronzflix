import 'package:flutter/services.dart' show rootBundle;
import 'package:stronzflix/utils/simple_http.dart' as http;

class Tuner {
    final bool Function(String) validator;
    const Tuner(this.validator);
    
    Future<bool> validateDomain(String domain) async {
        domain = domain.startsWith('https://') ? domain : 'https://${domain}';
        String body = await http.get(domain, followRedirects: false).onError((error, stackTrace) => "");
        return this.validator(body);
    }

    Stream<dynamic> findDomain(String subdomain) async* {
        String? result;
        double progress = 0.0;
        yield progress;

        List<String> domains = (await rootBundle.loadString('assets/tld_list.txt')).split("\n");
        
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
