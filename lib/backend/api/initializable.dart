abstract class Initializable {
    late Future<void> _initialized;

    Initializable(void Function(Initializable) then) {
        this._initialized = this.construct().then((_) => then(this));
    }

    Future<void> construct() async {}
    Future<void> ensureInitialized() => this._initialized;
}
