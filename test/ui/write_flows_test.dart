import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/cloud.dart';
import 'package:gymco/data/models.dart';

import '../helpers.dart';

Future<void> _openWrite(WidgetTester tester, String mode) async {
  await tester.tap(find.bySemanticsLabel('Food').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a written meal is read into rows and logged together', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await _openWrite(tester, 'Write');
    expect(find.textContaining('Write the meal the way you would say it'), findsOneWidget);

    await _type(tester, 'banana\n200g chicken breast, 150g rice and 10g olive oil\n2 eggs');
    expect(find.text('IT READ 5 ITEMS'), findsOneWidget);
    expect(find.text('1 assumed'), findsOneWidget);
    expect(find.text('assumed'), findsOneWidget);
    expect(find.text('200 g · 240 kcal · 45.0 g protein'), findsOneWidget);

    // Drop the banana, then add the rest.
    await tester.tap(find.bySemanticsLabel('Remove Banana'));
    await tester.pumpAndSettle();
    expect(find.text('IT READ 4 ITEMS'), findsOneWidget);
    await tester.tap(find.text('Add 4'));
    await tester.pumpAndSettle();
    expect(find.text('Add to lunch?'), findsOneWidget);
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();

    final entries = await db.entriesFor(dayKey(testNow));
    expect(
      [for (final e in entries) (e.foodName, e.grams)],
      [('Chicken breast, raw', 200), ('White rice, cooked', 150), ('Olive oil', 10), ('Egg, whole', 100)],
    );
    expect(entries.every((e) => e.meal == Meal.lunch), isTrue);
  });

  testWidgets('a food the phone does not know offers a search', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await _openWrite(tester, 'Write');
    await _type(tester, '100g quinoa');
    expect(find.text('Not in the database yet'), findsOneWidget);
    expect(find.text('IT READ 0 ITEMS'), findsOneWidget);
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'quinoa'), findsOneWidget);
  });

  testWidgets('a signed-in user can have a missing food estimated', (tester) async {
    final cloud = FakeCloud(
      signedIn: 'sam@example.com',
      photoFoods: const [
        PhotoFood(
          name: 'Mini pizza',
          local: 'Mini pizza',
          sure: true,
          grams: 90,
          kcal: 270,
          protein: 11,
          carbs: 30,
          fat: 11,
        ),
      ],
    );
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openWrite(tester, 'Write');
    await _type(tester, '3 mini pizzas');
    await tester.tap(find.text('Estimate'));
    await tester.pumpAndSettle();
    expect(cloud.lastNote, '3 mini pizzas');
    expect(cloud.lastHadImage, isFalse);
    expect(find.text('IT READ 1 ITEM'), findsOneWidget);
    await tester.tap(find.text('Add 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect([for (final e in entries) (e.foodName, e.grams)], [('Mini pizza', 90)]);
  });

  testWidgets('a recipe is built from written ingredients and a serving is logged', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Food').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New recipe'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Chicken and rice');
    await tester.enterText(find.byType(TextField).last, '600g chicken breast, 400g rice');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add ingredients'));
    await tester.pumpAndSettle();
    expect(find.text('2 INGREDIENTS'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Chicken and rice'), findsOneWidget);
    await tester.tap(find.text('Chicken and rice'));
    await tester.pumpAndSettle();
    expect(find.text('Your recipe'), findsOneWidget);
    await tester.tap(find.textContaining(RegExp(r'^Add \d')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect([for (final e in entries) (e.foodName, e.grams)], [('Chicken and rice', 250)]);
  });

  testWidgets('eating out logs an honest estimate', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Food').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Eat out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eat out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Burger'));
    await tester.tap(find.text('Big'));
    await tester.tap(find.text('Fries'));
    await tester.pumpAndSettle();
    expect(find.text('≈ 1,348'), findsOneWidget);
    await tester.ensureVisible(find.text('Log to lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log to lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect(
      [for (final e in entries) (e.foodName, e.grams.round(), e.kcal.round())],
      [('Burger', 338, 878), ('Fries', 150, 470)],
    );
  });

  testWidgets('voice goes through the same reader, with an editable transcript', (tester) async {
    final (db, _) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      dictation: FakeDictation(words: 'two eggs and a scoop of whey'),
    );
    await _openWrite(tester, 'Voice');
    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('TRANSCRIPT · EDIT IF IT MISHEARD'), findsOneWidget);
    expect(find.text('IT READ 2 ITEMS'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect([for (final e in entries) e.grams], [100, 30]);
  });

  testWidgets('no recogniser says so', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, dictation: FakeDictation(available: false));
    await _openWrite(tester, 'Voice');
    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dictation is not available'), findsOneWidget);
  });

  testWidgets('Arabic meals are read too', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('ar'));
    await tester.tap(find.bySemanticsLabel('الطعام').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('كتابة'));
    await tester.pumpAndSettle();
    await _type(tester, '٢٠٠ غرام دجاج ورز');
    await tester.tap(find.text('أضف 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد وإضافة'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect(
      [for (final e in entries) (e.foodId, e.grams)],
      [('usda:chicken-breast-raw', 200), ('usda:rice-white-cooked', 150)],
    );
  });
}
