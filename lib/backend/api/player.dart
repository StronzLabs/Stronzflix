import 'package:stronzflix/utils/initializable.dart';
import 'package:stronzflix/backend/api/media.dart';

abstract class Player extends Initializable {
    final String name;

    Player(this.name) : super((self) => Player._registry[name] = self as Player);

    Future<Uri> getSource(Watchable media);

    static final Map<String, Player> _registry = {};
    static List<Player> get players => _registry.values.toList();
    static Player? get(String name) => _registry[name];
}
