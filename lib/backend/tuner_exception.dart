class TunerException implements Exception {
    final String site;
    TunerException(this.site);

    @override
    String toString() => "Non è stato possibile sintonizzare ${this.site}.\nIl caricamento continuerà senza di esso.";
}
