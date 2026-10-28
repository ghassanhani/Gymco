import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/ui/kit/kit.dart';

import '../helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> key(WidgetTester t, String k) =>
    t.tap(find.descendant(of: find.byType(Keypad), matching: k == 'del' ? find.byType(VIcon) : find.text(k)));

/// 27 fully logged days eating 2,520, losing about 0.07 kg a day.
Future<void> measuredMonth(LocalDb db) async {
  const food = Food(id: 'x', name: 'Mixed', kcal: 105, protein: 8, carbs: 11, fat: 3);
  await db.upsertFoods([food]);
  for (var i = 1; i <= 27; i++) {
    final day = dayKey(testNow.subtract(Duration(days: i)));
    for (final m in [Meal.breakfast, Meal.lunch, Meal.dinner]) {
      await db.addEntry(LogEntry.of(food, day: day, meal: m, grams: 800));
    }
  }
  for (var i = 27; i >= 0; i--) {
    await db.setWeight(dayKey(testNow.subtract(Duration(days: i))), 80 + 0.07 * i);
  }
}

void main() {
  testWidgets('a weigh-in on the keypad lands in the log', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Progress').first);
    await settle(tester);
    await tester.tap(find.byTooltip('Add a weigh-in'));
    await settle(tester);
    for (final k in ['7', '9', '.', '6']) {
      await key(tester, k);
    }
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect((await db.weighIns()).last, (dayKey(testNow), 79.6));
  });

  testWidgets('tapping the body measures that part, and waist and neck give body fat', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Progress').first);
    await settle(tester);
    await tester.tap(find.text('Measure'));
    await settle(tester);
    expect(find.text('Measure your waist and neck to see your body fat.'), findsOneWidget);
    Future<void> measure(String part, List<String> keys) async {
      await tester.tap(find.byKey(Key('body-$part')));
      await settle(tester);
      for (final k in keys) {
        await key(tester, k);
      }
      await tester.pump();
      await tester.tap(find.text('Save'));
      await settle(tester);
    }

    await measure('neck', ['3', '8']);
    await measure('waist', ['8', '5']);
    expect(await db.measurements('neck'), [(dayKey(testNow), 38.0)]);
    expect(await db.measurements('waist'), [(dayKey(testNow), 85.0)]);
    expect(find.text('Body fat, estimated'), findsOneWidget);
    expect(find.text('%'), findsOneWidget);
  });

  testWidgets('without two weeks of logging the check-in keeps the targets', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Progress').first);
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await settle(tester);
    await tester.tap(find.text("Open this week's check-in"));
    await settle(tester);
    expect(find.text('Not measured yet'), findsOneWidget);
    expect(find.text('no change'), findsOneWidget);
  });

  testWidgets('a measured week moves the target by at most 120 and accepting saves it', (tester) async {
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile}, seed: measuredMonth);
    await tester.tap(find.bySemanticsLabel('Progress').first);
    await settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await settle(tester);
    await tester.tap(find.text("Open this week's check-in"));
    await settle(tester);
    expect(find.text('Measured expenditure'), findsOneWidget);
    expect(find.text('+120 kcal'), findsOneWidget);
    await tester.tap(find.text('Accept targets'));
    await settle(tester);
    final p = jsonDecode(prefs.getString('profile')!) as Map<String, Object?>;
    expect(p['kcal'], 2319 + 120);
    // Carbs take the change; protein and fat stay.
    expect(p['p'], 176);
    expect(p['c'], 245 + 30);
    expect(prefs.getDouble('lastExpenditure'), isNotNull);
  });

  testWidgets('a commitment can be changed', (tester) async {
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Progress').first);
    await settle(tester);
    await tester.tap(find.textContaining('days kept'));
    await settle(tester);
    await tester.tap(find.text('Edit goal'));
    await settle(tester);
    await tester.tap(find.text('One month'));
    await settle(tester);
    await tester.tap(find.text('Commit to 30 days'));
    await settle(tester);
    expect(prefs.getInt('streakGoal'), 30);
  });

  testWidgets('a tester account sees badges unlocked to preview them', (tester) async {
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      cloud: FakeCloud(signedIn: 'ghassanhani0@gmail.com'),
    );
    await settle(tester);
    expect(find.bySemanticsLabel(RegExp(r'^Awards, ([1-9]\d*) earned')), findsOneWidget);
  });
}
