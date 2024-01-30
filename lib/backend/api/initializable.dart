abstract class Initializable {
    late Future<void> _initialized;

    Initializable(void Function(Initializable) then) {
        this._initialized = this.prepare().then((_) => then(this));
    }

    Future<void> prepare() async {}
    Future<void> ensureInitialized() => this._initialized;
}