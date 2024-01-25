import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/pages/home_page.dart';

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
                    cardTheme: const CardTheme(
                        clipBehavior: Clip.hardEdge,
                    ),
                    appBarTheme: const AppBarTheme(
                        centerTitle: true
                    ),
                    snackBarTheme: const SnackBarThemeData(
                        backgroundColor: Color(0xff121212),
                        behavior: SnackBarBehavior.floating,
                        showCloseIcon: true,
                        closeIconColor: Colors.white,
                        contentTextStyle: TextStyle(
                            color: Colors.white
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20))
                        )
                    ),
                    drawerTheme: const DrawerThemeData(
                        backgroundColor: Color.fromARGB(200, 18, 18, 18),
                    ),
                ),
                home: const HomePage(),
                debugShowCheckedModeBanner: false
            )
        );
    }
}
