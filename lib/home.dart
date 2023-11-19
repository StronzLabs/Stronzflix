import 'package:flutter/material.dart';
import 'package:stronzflix/search.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

    AppBar buildSearchBar(BuildContext context) {
        return AppBar(
            title: const Text("Stronzflix"),
            centerTitle: true,
            actions: [
                IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                        showSearch(context: context, delegate: SearchPage());
                    },
                ),
            ],
        );        
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: this.buildSearchBar(context),
            body: const Center(
                child: Text("<home page will go here>")
            )
        );
    }
}
