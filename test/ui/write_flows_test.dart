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
    expect(find.textContaining('What did you eat?'), findsOneWidget);

    await _type(tester, 'banana\n200g chicken breast, 150g rice and 10g olive oil\n2 eggs');
    expect(find.text('IT READ 5 ITEMS'), findsOneWidget);
    expect(find.text('1 assumed'), findsOneWidget);
    expect(find.text('assumed'), findsOneWidget);
    expect(find.text('200 g · 240 kcal · 45.0 g protein'), findsOneWidget);

    // Drop the banana, then add the rest.
    await tester.ensureVisible(find.bySemanticsLabel('Remove Banana'));
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Search').last);
    await tester.pumpAndSettle();
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
    await tester.ensureVisible(find.text('Estimate'));
    await tester.pumpAndSettle();
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

  testWidgets('Ask AI estimates every missing food at once; a written weight wins', (tester) async {
    PhotoFood f(String name, double g) =>
        PhotoFood(name: name, local: name, sure: true, grams: g, kcal: 300, protein: 8, carbs: 50, fat: 7);
    final cloud = FakeCloud(signedIn: 'sam@example.com', photoFoods: [f('Tortilla', 60), f('Molokhia', 250)]);
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openWrite(tester, 'Write');
    await _type(tester, 'tortilla 100 g, ملوخية');
    await tester.tap(find.text('Ask AI about 2 foods'));
    await tester.pumpAndSettle();
    expect(cloud.lastNote, 'tortilla 100 g\nملوخيه');
    expect(find.text('IT READ 2 ITEMS'), findsOneWidget);
    await tester.tap(find.text('Add 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect([for (final e in entries) (e.foodName, e.grams)], [('Tortilla', 100), ('Molokhia', 250)]);
  });

  testWidgets('signed out, Ask AI goes to sign in', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: FakeCloud());
    await _openWrite(tester, 'Write');
    await _type(tester, 'quinoa');
    await tester.tap(find.text('Ask AI'));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);
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
    await tester.ensureVisible(find.text('Fries'));
    await tester.pumpAndSettle();
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

  testWidgets('a restaurant meal not on the list is estimated by the AI, or guessed', (tester) async {
    final cloud = FakeCloud(
      signedIn: 'sam@example.com',
      photoFoods: const [
        PhotoFood(
          name: 'Chicken biryani',
          local: 'Chicken biryani',
          sure: true,
          grams: 450,
          kcal: 180,
          protein: 9,
          carbs: 22,
          fat: 6,
        ),
      ],
    );
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await tester.tap(find.bySemanticsLabel('Food').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Eat out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eat out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Something else'));
    await tester.pumpAndSettle();
    // Without the AI, the rough total counts.
    expect(find.text('≈ 700'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'chicken biryani');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Ask Iron to estimate it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ask Iron to estimate it'));
    await tester.pumpAndSettle();
    expect(cloud.lastNote, contains('chicken biryani'));
    expect(find.text('≈ 810'), findsOneWidget);
    await tester.ensureVisible(find.text('Log to lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log to lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect([for (final e in entries) (e.foodName, e.grams.round())], [('Chicken biryani', 450)]);
  });

  testWidgets('voice goes straight to the reader, with no transcript box', (tester) async {
    final (db, _) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      dictation: FakeDictation(words: 'two eggs and a scoop of whey'),
    );
    await _openWrite(tester, 'Voice');
    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    // Recording: the red dot, the time and the wave show the mic is open.
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('0:00'), findsOneWidget);
    expect(find.byTooltip('Cancel recording'), findsOneWidget);
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    expect(find.text('TRANSCRIPT · EDIT IF IT MISHEARD'), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('You said: “two eggs and a scoop of whey”'), findsOneWidget);
    expect(find.text('IT READ 2 ITEMS'), findsOneWidget);

    await tester.tap(find.text('Add 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm and add'));
    await tester.pumpAndSettle();
    final entries = await db.entriesFor(dayKey(testNow));
    expect([for (final e in entries) e.grams], [100, 30]);
  });

  testWidgets('a meal said in a language the reader does not know is read by the AI whole', (tester) async {
    PhotoFood f(String name, double g) =>
        PhotoFood(name: name, local: name, sure: true, grams: g, kcal: 150, protein: 12, carbs: 1, fat: 10);
    final cloud = FakeCloud(signedIn: 'sam@example.com', photoFoods: [f('Boiled egg', 100), f('Baguette', 60)]);
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      cloud: cloud,
      voice: FakeVoice(words: 'deux oeufs et un morceau de baguette', language: 'fr'),
    );
    await _openWrite(tester, 'Voice');
    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Done'));
    await tester.pumpAndSettle();
    expect(cloud.lastNote, 'deux oeufs et un morceau de baguette');
    expect(find.text('IT READ 2 ITEMS'), findsOneWidget);
    expect(find.text('Add 2'), findsOneWidget);
  });

  testWidgets('a voice note can be thrown away', (tester) async {
    final voice = FakeVoice(words: 'two eggs');
    await pumpApp(tester, prefs: {'profile': savedProfile}, voice: voice);
    await _openWrite(tester, 'Voice');
    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Cancel recording'));
    await tester.pumpAndSettle();
    expect(voice.cancelled, 1);
    expect(voice.finished, 0);
    expect(find.textContaining('You said'), findsNothing);
  });

  testWidgets('a note that is out of AI requests says so', (tester) async {
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      voice: FakeVoice(failure: CloudFailure.dailyCap),
    );
    await _openWrite(tester, 'Voice');
    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Dictate the meal'), findsOneWidget);
    expect(find.textContaining('You said'), findsNothing);
  });

  testWidgets('no recogniser says so', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, dictation: FakeDictation(available: false));
    await _openWrite(tester, 'Voice');
    await tester.tap(find.bySemanticsLabel('Dictate the meal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
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
