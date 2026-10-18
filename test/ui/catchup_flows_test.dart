import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/models.dart';

import '../helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

String daysAgo(int n) => dayKey(testNow.subtract(Duration(days: n)));

void main() {
  testWidgets('open days fill from the usual day or stay out', (tester) async {
    const food = Food(id: 'x', name: 'Mixed', kcal: 105, protein: 8, carbs: 11, fat: 3);
    final (db, _) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      seed: (db) async {
        await db.upsertFoods([food]);
        // Started on the 20th; the 22nd and 23rd have nothing.
        for (final n in [1, 2, 5, 6]) {
          await db.addEntry(LogEntry.of(food, day: daysAgo(n), meal: Meal.lunch, grams: 2000));
        }
      },
    );
    expect(find.text('2 days without food logs'), findsOneWidget);
    await tester.ensureVisible(find.text('2 days without food logs'));
    await settle(tester);
    await tester.tap(find.text('2 days without food logs'));
    await settle(tester);
    expect(find.textContaining('≈ 2,100 kcal, 160 g protein'), findsNWidgets(2));
    await tester.tap(find.text('Leave out').last);
    await settle(tester);
    expect(find.textContaining('Left out of your expenditure average'), findsOneWidget);
    await tester.tap(find.text('Save 2 days'));
    await settle(tester);

    final filled = await db.entriesFor(daysAgo(4));
    expect(filled.single.kcal, closeTo(2100, 0.1));
    expect(filled.single.protein, closeTo(160, 0.1));
    expect(await db.entriesFor(daysAgo(3)), isEmpty);
    expect(find.text('2 days without food logs'), findsNothing);
    expect(find.textContaining('without food logs'), findsNothing);
  });
}
