import 'package:flutter/material.dart';
import 'package:stronzflix/pages/search_page.dart';

class SearchButton extends StatelessWidget {

    const SearchButton({
        super.key
    });

    @override
    Widget build(BuildContext context) {
        return IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
                context: context,
                delegate: SearchPage(),
                maintainState: true
            )
        );
    }
}
