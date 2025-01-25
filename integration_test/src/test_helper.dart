import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stronzflix/pages/home_page.dart';
import 'package:stronzflix/pages/loading_page.dart';
import 'package:stronzflix/stronzflix.dart';

final class TestHelper {
    TestHelper._();

    static late WidgetTester tester;
    static bool _loaded = false;

    static Future<void> _waitLoading() async {
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

    static Future<void> pumpApp() async {
        if(!TestHelper._loaded) {
            await tester.pumpWidget(const Stronzflix());
            await TestHelper._waitLoading();
            TestHelper._loaded = true;
        } else {
            await tester.pumpWidget(const Stronzflix(skipLoading: true));
        }

        await tester.pump(Durations.extralong4);
        Navigator.of(Stronzflix.navigatorKey.currentState!.context).popUntil((route) => route.settings.name == "/home");
        await tester.pump(Durations.extralong4);
        expect(find.byType(HomePage), findsOneWidget);
    }
}