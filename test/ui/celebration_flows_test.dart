import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/state/providers.dart';

import '../helpers.dart';

Future<void> settle(WidgetTester t, [int n = 12]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('logging a meal shows the flame sheet, the last one the award', (tester) async {
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'awardsSeen': <String>[]},
      celebrations: true,
    );
    await settle(tester);
    final c = ProviderScope.containerOf(tester.element(find.byType(GymcoApp)));
    final oats = (await db.searchFoods('oats')).first;
    Future<void> log(Meal m) async {
      await c.read(logActionsProvider).add(LogEntry.of(oats, day: dayKey(testNow), meal: m, grams: 80));
      await settle(tester);
    }

    await log(Meal.breakfast);
    // No plan, so today is a rest day and that part is already done.
    expect(find.text('2 of 4 done today'), findsOneWidget);
    expect(find.text('day streak'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('2 of 4 done today'), findsNothing);

    await log(Meal.lunch);
    expect(find.text('3 of 4 done today'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await settle(tester);

    // The day kept is also the first full day: the award moment comes instead.
    await log(Meal.dinner);
    // Coming back after missed days earns Comeback too; they show one after the other.
    final shown = <String>[];
    for (var i = 0; i < 2; i++) {
      expect(find.text('Award unlocked'), findsOneWidget);
      shown.add(find.text('First full day').evaluate().isNotEmpty ? 'f1' : 'back');
      await tester.tap(find.text('Done'));
      await settle(tester);
    }
    expect(shown.toSet(), {'f1', 'back'});
    expect(find.text('Award unlocked'), findsNothing);
    expect(prefs.getStringList('awardsSeen'), containsAll(['f1', 'back']));
  });

  testWidgets('awards already earned before the update are never celebrated', (tester) async {
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      celebrations: true,
      seed: (db) async {
        final oats = (await db.searchFoods('oats')).first;
        for (final m in [Meal.breakfast, Meal.lunch, Meal.dinner]) {
          await db.addEntry(
            LogEntry.of(oats, day: dayKey(testNow.subtract(const Duration(days: 1))), meal: m, grams: 80),
          );
        }
      },
    );
    await settle(tester);
    expect(find.text('Award unlocked'), findsNothing);
    expect(prefs.getStringList('awardsSeen'), contains('f1'));
  });
}
