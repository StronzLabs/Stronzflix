import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/pages/loading_page.dart';

class Stronzflix extends StatelessWidget {
    
    static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

    const Stronzflix({super.key});

    @override
    Widget build(BuildContext context) {
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp
        ]);
        return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
            },
            child: MaterialApp(
                title: 'Stronzflix',
                navigatorObservers: [ Stronzflix.routeObserver ],
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
                    progressIndicatorTheme: const ProgressIndicatorThemeData(
                        linearTrackColor: Colors.grey,
                    ),
                ),
                home: const LoadingPage(),
                debugShowCheckedModeBanner: false
            )
        );
    }
}
