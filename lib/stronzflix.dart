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
import 'package:sutils/ui/stronz_theme.dart';

class Stronzflix extends StatelessWidget {

    static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    final bool skipLoading;

    const Stronzflix({super.key, this.skipLoading = false});

    @override
    Widget build(BuildContext context) {
        return Shortcuts(
            shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.select): ActivateIntent(),
            },
            child: MaterialApp(
                themeMode: ThemeMode.dark,
                title: 'Stronzflix',
                theme: stronzTheme,
                initialRoute: this.skipLoading ? '/home' : '/loading',
                routes: {
                    '/loading': (context) => LoadingPage(),
                    '/home' : (context) => HomePage(),
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
                            '/' => SizedBox.shrink(),
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
