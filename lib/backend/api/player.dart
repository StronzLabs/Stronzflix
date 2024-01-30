import 'package:stronzflix/backend/api/initializable.dart';
import 'package:stronzflix/backend/api/media.dart';

abstract class Player extends Initializable {
    final String name;

    Player({required this.name}) : super((self) => Player._registry[name] = self as Player);

    Future<Uri> getSource(Watchable media);

    static final Map<String, Player> _registry = {};
    static Player? get(String name) => _registry[name];
}
