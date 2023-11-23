import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/views/home.dart';

class Stronzflix extends StatelessWidget {
    const Stronzflix({super.key});

    @override
    Widget build(BuildContext context) {
        return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
            },
            child: MaterialApp(
                title: 'Stronzflix',
                theme: ThemeData(
                    colorScheme: ColorScheme.dark(
                        brightness: Brightness.dark,
                        primary: Colors.orange,
                        secondary: Colors.orangeAccent,
                        background: (Colors.grey[900])!,
                        surface: const Color(0xff121212),
                        surfaceTint: Colors.transparent,
                    ),
                    useMaterial3: true,
                ),
                home: const HomePage(),
                debugShowCheckedModeBanner: false
            )
        );
    }
}
