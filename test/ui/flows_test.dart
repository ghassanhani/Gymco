import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/models.dart';

import '../helpers.dart';

void main() {
  testWidgets('first launch runs onboarding and lands on Today with targets', (tester) async {
    await pumpApp(tester);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Lose fat'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Body: Continue stays off until every field is valid.
    await tester.enterText(find.widgetWithText(TextField, 'Age'), '30');
    await tester.enterText(find.widgetWithText(TextField, 'Height (cm)'), '180');
    await tester.enterText(find.widgetWithText(TextField, 'Weight (kg)'), '80');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Active job or daily walks'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Rate: default 0.5%/week, no warning.
    expect(find.textContaining('0.50% of body weight'), findsOneWidget);
    expect(find.textContaining('Faster than 0.85%'), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 1780 * 1.55 - 80 * 0.005 * 7700 / 7 = 2319
    expect(find.text('2,319 kcal'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    expect(find.text('A fresh day'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
  });

  testWidgets('searching and logging a food moves the day', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    expect(find.text('A fresh day'), findsOneWidget);

    await tester.tap(find.byTooltip('Add to Lunch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'chicken');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chicken breast, raw'));
    await tester.pumpAndSettle();
    // Default serving is the 170 g fillet: 204 kcal.
    expect(find.text('204'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '200');
    await tester.pumpAndSettle();
    expect(find.text('240'), findsOneWidget);
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();

    expect((await db.entriesFor(dayKey(testNow))).single.grams, 200);
    expect(find.text('2,079 kcal left'), findsOneWidget);
    expect(find.textContaining('Chicken breast, raw · 1 item'), findsOneWidget);
  });

  testWidgets('offline search still finds foods saved on the phone', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, source: FakeFoodSource(offline: true));
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'oats');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Oats, rolled'), findsOneWidget);
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('a search with no match gets a way forward', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzqx');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No match for "zzqx"'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
  });

  testWidgets('no-numbers mode hides calories and shows habits', (tester) async {
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'noNumbers': true},
      seed: (db) => db.addEntry(
        LogEntry.of(
          const Food(id: 'x', name: 'Skyr', kcal: 63, protein: 11, carbs: 4, fat: 0.2),
          day: dayKey(testNow),
          meal: Meal.breakfast,
          grams: 200,
        ),
      ),
    );

    expect(find.text("Today's habits"), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
  });

  testWidgets('leaving no-numbers mode needs a confirmation', (tester) async {
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile, 'noNumbers': true});
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(Switch), 200);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Show numbers again?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('noNumbers'), isTrue);
  });

  testWidgets('Arabic runs right to left', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('ar'));
    expect(find.text('اليوم'), findsWidgets);
    final dir = Directionality.of(tester.element(find.text('الوجبات')));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('Spanish translates the tabs', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('es'));
    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Comidas'), findsOneWidget);
  });
}
