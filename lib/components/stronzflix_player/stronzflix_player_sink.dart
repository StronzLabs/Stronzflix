import 'package:flutter/material.dart';

class StronzflixPlayerSink extends StatefulWidget {

    const StronzflixPlayerSink() : super(key: const Key('StronzflixPlayerSink'));

    @override
    State<StronzflixPlayerSink> createState() => _StronzflixPlayerSinkState();    
}

class _StronzflixPlayerSinkState extends State<StronzflixPlayerSink> {

    late Widget _content;

    @override
    void initState() {
        super.initState();
        this._content = const Center(child: CircularProgressIndicator());
    }

    @override
    Widget build(BuildContext context) {
        return this._content;
    }

}
