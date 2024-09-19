import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/peer/peer_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/pages/home_page.dart';
import 'package:stronzflix/pages/loading_page.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'package:stronzflix/pages/title_page.dart';
import 'package:sutils/sutils.dart';

class Stronzflix extends StatelessWidget {

    static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    const Stronzflix({super.key});

    static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: (Colors.grey[900])!,
        drawerTheme: DrawerThemeData(
            backgroundColor: (Colors.grey[900])!
        ),
        colorScheme: ColorScheme.dark(
            brightness: Brightness.dark,
            primary: Colors.orange,
            secondary: Colors.grey,
            surface: const Color(0xff121212),
            surfaceTint: Colors.transparent,
            surfaceContainerHigh: (Colors.grey[900])!,
            error: Colors.red,
            secondaryContainer: Colors.orange
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
        expansionTileTheme: const ExpansionTileThemeData(
            shape: Border()
        ),
        cardTheme: const CardTheme(
            clipBehavior: Clip.antiAlias,
        )
    );

    @override
    Widget build(BuildContext context) {
        SystemChrome.setPreferredOrientations([
            if(EPlatform.isTV || EPlatform.isTablet) ...[
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight
            ] else
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
                navigatorKey: Stronzflix.navigatorKey,
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
