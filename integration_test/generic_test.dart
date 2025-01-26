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
import 'package:stronzflix/pages/home_page.dart';
import 'package:stronzflix/pages/player_page.dart';
import 'src/test_helper.dart';

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

    expect(find.byType(SliverGrid), findsOneWidget);
}

Future<void> playFirstResult(WidgetTester tester, String query) async {
    expect(find.byType(HomePage), findsOneWidget);

    await search(tester, query);
            
    Finder playFinder = find.byIcon(Icons.play_arrow).first;
    expect(playFinder, findsAny);

    await tester.tap(playFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30));

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
}

void testPlaybackFor(String site) {
    testWidgets(site, (WidgetTester tester) async {
        TestHelper.tester = tester;
        await TestHelper.pumpApp();
        await selectSite(tester, site);
        await playFirstResult(tester, "A");
    });
}

Future<void> testSiteTuning(Site site) async {
    Completer<bool> completer = Completer<bool>();
    site.progress.progress.listen(
        (_) {},
        onError: (_) => completer.complete(false),
        onDone: () => completer.complete(true)
    );
    bool succesfull = await completer.future;
    expect(succesfull, true);
}

void main() async {
    print("Setting up test environments");
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await Tuner.prepareCache();

    print("Starting tests");

    group("Tuning -", () {
        print("Tuing test...");
        test("StreamingCommunity", () async {
            await testSiteTuning(StreamingCommunity.instance);
        }, timeout: const Timeout(Duration(minutes: 5)));

        print("Streaming community done");

        test("CB01", () async {
            await testSiteTuning(CB01.instance);
        }, timeout: const Timeout(Duration(minutes: 5)));

        print("CB01 done");

        test("AnimeSaturn", () async {
            await testSiteTuning(AnimeSaturn.instance);
        }, timeout: const Timeout(Duration(minutes: 5)));
    
        print("AnimeSaturn done");
    });

    group("Video Playback - ", () {
        testPlaybackFor("StreamingCommunity");
        testPlaybackFor("CB01");
        testPlaybackFor("AnimeSaturn");
    });
}