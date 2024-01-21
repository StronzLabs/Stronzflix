import 'package:stronzflix/backend/api/media.dart';

abstract class Player {
    final String name;

    Player({required this.name}) {
        this.prepare().then((_) => Player._registry[name] = this);
    }

    Future<void> prepare() async {}
    Future<Uri> getSource(Watchable media);

    static final Map<String, Player> _registry = {};
    static Player? get(String name) => _registry[name];
}
