import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/ui/food/add_food_screen.dart';
import 'package:gymco/ui/progress/progress_screen.dart';
import 'package:gymco/ui/common/ask_iron.dart';

import '../helpers.dart';

void main() {
  testWidgets('what Siri was asked while the app was closed is done when it opens', (tester) async {
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {
        'profile': savedProfile,
        'siriQueue': jsonEncode([
          {'a': 'water', 'ml': 500},
          {'a': 'weight', 'kg': 81.36},
          {'a': 'food', 'text': '2 eggs and toast'},
        ]),
      },
    );
    // The requests write to the database, which takes real time.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }
    expect(
      [
        for (final (day, kg) in await db.weighIns())
          if (day == dayKey(testNow)) kg,
      ],
      [81.4],
    );
    // The food opens Write mode with the words in, read as if typed.
    expect(find.byType(AddFoodScreen), findsOneWidget);
    expect(find.text('2 eggs and toast'), findsOneWidget);
    expect(prefs.getString('siriQueue'), isNull);
    expect(prefs.getString('waterlog_${dayKey(testNow)}'), endsWith(':500'));
  });

  testWidgets('today\'s numbers are kept where Siri can read them', (tester) async {
    final (_, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      seed: (db) async {
        final oats = (await db.searchFoods('oats')).first;
        await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 100));
      },
    );
    await tester.pumpAndSettle();
    final today = jsonDecode(prefs.getString('siriToday')!) as Map<String, Object?>;
    expect(today['day'], dayKey(testNow));
    final target = (jsonDecode(savedProfile) as Map)['kcal'] as num;
    expect(today['kcal_left'], lessThan(target));
    expect(today['water_ml'], 0);
  });

  testWidgets('a voice note to Iron is sent as the message, not left in the box', (tester) async {
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'ironOn': true},
      cloud: FakeCloud(signedIn: 'me@example.com'),
      dictation: FakeDictation(words: 'only three days a week'),
    );
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push('/iron');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Say it'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byTooltip('Cancel recording'), findsOneWidget);
    await tester.tap(find.byTooltip('Build my program'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(UserBubble), matching: find.text('only three days a week')), findsOneWidget);
    expect(find.descendant(of: find.byType(TextField), matching: find.text('only three days a week')), findsNothing);
  });

  testWidgets('a shortcut that opens a place in the app goes there, and only to known places', (tester) async {
    await pumpApp(
      tester,
      prefs: {
        'profile': savedProfile,
        'siriQueue': jsonEncode([
          {'a': 'open', 'to': '/account/delete'},
          {'a': 'open', 'to': '/progress'},
        ]),
      },
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }
    expect(find.byType(ProgressScreen), findsOneWidget);
  });
}
