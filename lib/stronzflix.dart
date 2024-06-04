import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/linear_track_shape.dart';
import 'package:stronzflix/pages/home_page.dart';
import 'package:stronzflix/pages/loading_page.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'package:stronzflix/pages/title_page.dart';

class Stronzflix extends StatelessWidget {

    const Stronzflix({super.key});

    static ThemeData get theme => ThemeData(
        dropdownMenuTheme: const DropdownMenuThemeData(
            inputDecorationTheme: InputDecorationTheme(
                fillColor: Colors.red
            )
        ),
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
        expansionTileTheme: const ExpansionTileThemeData(
            shape: Border()
        ),
        sliderTheme: const SliderThemeData(
            trackShape: LinearTrackShape(),
            trackHeight: 1.2,
            inactiveTrackColor: Color(0x3DFFFFFF),
            activeTrackColor: Colors.white,
            thumbColor: Colors.white,
            thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 12.0 / 2,
                elevation: 0.0,
                pressedElevation: 0.0,
            ),
            overlayColor: Colors.transparent,
        ),
    );

    @override
    Widget build(BuildContext context) {
        SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
        ));

        return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
            },
            child: MaterialApp(
                themeMode: ThemeMode.dark,
                title: 'Stronzflix',
                theme: Stronzflix.theme,
                initialRoute: '/loading',
                routes: {
                    '/home' : (context) => const HomePage(),
                    '/loading': (context) => const LoadingPage(),
                    '/title': (context) => const TitlePage(),
                    '/player': (context) => const PlayerPage(),
                    '/player-sink': (context) => const PlayerPage(),
                },
                debugShowCheckedModeBanner: false,
                navigatorObservers: [
                    SinkNavigatorObserver()
                ],
            )
        );
    }
}

class SinkNavigatorObserver extends NavigatorObserver {

    @override
    void didPush(Route route, Route? previousRoute) {
        super.didPush(route, previousRoute);
        if(route.settings.name == '/player') {
            Watchable watchable = route.settings.arguments as Watchable; 
            PeerMessenger.startWatching(SerialMetadata.fromWatchable(watchable, 0, 0));
        }
    }
}
