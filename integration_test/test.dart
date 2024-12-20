import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stronzflix/backend/api/bindings/animesaturn.dart';
import 'package:stronzflix/backend/api/bindings/cb01.dart';
import 'package:stronzflix/backend/api/bindings/streamingcommunity.dart';
import 'package:stronzflix/backend/api/site.dart';
import 'package:stronzflix/backend/api/tune.dart';
import 'package:stronzflix/dialogs/settings_dialog.dart';
import 'package:stronzflix/main.dart' as app;
import 'package:stronzflix/pages/home_page.dart';
import 'package:stronzflix/pages/loading_page.dart';
import 'package:stronzflix/pages/player_page.dart';

Future<void> testSiteTuning(Site site) async {
    await Tuner.prepareCache();
    Completer<bool> completer = Completer<bool>();
    site.progress.listen(
        (_) {},
        onError: (_) => completer.complete(false),
        onDone: () => completer.complete(true)
    );
    bool succesfull = await completer.future;
    expect(succesfull, true);
}

Future<void> waitLoading(WidgetTester tester) async {
    expect(find.byType(LoadingPage), findsOneWidget);

    String? error;
    while (find.byType(HomePage).evaluate().isEmpty && error == null) {
        await tester.pump(Durations.extralong4);

        FinderResult<Element> errorFinder = find.byKey(const Key("loading_error")).evaluate();
        if (errorFinder.isNotEmpty)
            error = (errorFinder.single.widget as Text).data;
    }

    if(error != null)
        fail("Loading failed: ${error}");

    expect(find.byType(HomePage), findsOneWidget);
}

Future<void> selectSite(WidgetTester tester, String site) async {

    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump(Durations.long2);

    expect(find.byType(SettingsDialog), findsOneWidget);

    await tester.tap(find.byKey(const Key("site_dropdown")));
    await tester.pump(Durations.long2);

    await tester.tap(find.text(site));
    await tester.pump(Durations.long2);

    expect(find.text(site), findsOneWidget);

    await tester.tap(find.byKey(const Key("settings_close")));
    await tester.pump(Durations.long2);

    expect(find.byType(SettingsDialog), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
}

Future<void> search(WidgetTester tester, String query) async {
    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    Finder searchFinder = find.byType(TextField);
    expect(searchFinder, findsOneWidget);

    await tester.enterText(searchFinder, "A");
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(SliverGrid), findsOne);
}

Future<void> playFirstResult(WidgetTester tester, String query) async {
    expect(find.byType(HomePage), findsOneWidget);

    await search(tester, query);
            
    Finder playFinder = find.byIcon(Icons.play_arrow).first;
    expect(playFinder, findsAny);

    await tester.tap(playFinder);
    await tester.pumpAndSettle();

    expect(find.byType(PlayerPage), findsOneWidget);
} 

void main() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    group("Loading - ", () {
        test("Tune StreamingCommunity",
            () => testSiteTuning(StreamingCommunity.instance),
            timeout: const Timeout(Duration(minutes: 5))
        );
        test("Tune CB01", () => testSiteTuning(CB01.instance),
            timeout: const Timeout(Duration(minutes: 5))
        );
        test("Tune AnimeSaturn", () => testSiteTuning(AnimeSaturn.instance),
            timeout: const Timeout(Duration(minutes: 5))
        );

        testWidgets("UI", (WidgetTester tester) async {
            app.main();
            await tester.pump(Durations.long4);
            await waitLoading(tester);
        });
    });

    group("Video Playback - ", () {
        testWidgets("StreamingCommunity", (WidgetTester tester) async {
            app.main();
            await tester.pump(Durations.long4);
            await waitLoading(tester);
            await selectSite(tester, "StreamingCommunity");
            await playFirstResult(tester, "A");
        });

        testWidgets("CB01", (WidgetTester tester) async {
            app.main();
            await tester.pump(Durations.long4);
            await waitLoading(tester);
            await selectSite(tester, "CB01");
            await playFirstResult(tester, "A");
        });

        testWidgets("AnimeSaturn", (WidgetTester tester) async {
            app.main();
            await tester.pump(Durations.long4);
            await waitLoading(tester);
            await selectSite(tester, "AnimeSaturn");
            await playFirstResult(tester, "A");
        });
    });
}