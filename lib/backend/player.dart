import 'package:stronzflix/backend/media.dart';

abstract class Player {
    final String name;

    Player({required this.name}) {
        this.prepare().then((_) => Player._registry[name] = this);
    }

    Future<void> prepare() async {}
    Future<Uri> getSource(IWatchable media);
    Future<Title> recoverLate(LateTitle title);

    static final Map<String, Player> _registry = {};
    static Player? get(String name) => _registry[name];
}
