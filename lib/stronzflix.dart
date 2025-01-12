import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stronzflix/backend/api/media.dart';
import 'package:stronzflix/backend/sink/sink_messenger.dart';
import 'package:stronzflix/backend/storage/keep_watching.dart';
import 'package:stronzflix/components/floating_player_context.dart';
import 'package:stronzflix/pages/home_page.dart';
import 'package:stronzflix/pages/loading_page.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'package:stronzflix/pages/title_page.dart';

class Stronzflix extends StatelessWidget {

    static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    const Stronzflix({super.key});

    static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: (Colors.grey[900])!,
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
        progressIndicatorTheme: const ProgressIndicatorThemeData(
            linearTrackColor: Colors.grey
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
                    '/loading': (context) => const LoadingPage(),
                    '/home' : (context) => const HomePage(),
                },
                onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                        settings: settings,
                        builder: (context) => switch(settings.name) {
                            '/title' => TitlePage(
                                heroUuid: (settings.arguments as TitlePageArguments).heroUuid,
                                metadata: (settings.arguments as TitlePageArguments).metadata
                            ),
                            '/player' || '/player-sink' => FloatingPlayerContext.navigatorGuard(context,
                                child: PlayerPage(
                                    watchable: (settings.arguments as PlayerPageArguments).watchable,
                                    controller: (settings.arguments as PlayerPageArguments).controller
                                )
                            ),
                            '/' => const SizedBox.shrink(),
                            _ => throw Exception("Unknown route: ${settings.name}")
                        }
                    );
                },
                builder: (context, child) => FloatingPlayerContext(child: child),
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
        if(route.settings.name == '/player') {
            Watchable watchable = (route.settings.arguments as PlayerPageArguments).watchable; 
            SinkMessenger.startWatching(SerialMetadata.fromWatchable(watchable, 0, 0));
        }
    }
}
