import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/models.dart';

import 'package:gymco/ui/kit/kit.dart';
import 'package:gymco/ui/today/today_screen.dart';

import '../helpers.dart';

Future<void> _throughBody(WidgetTester tester) async {
  await tester.tap(find.text('GET STARTED'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  // Body: Continue stays off until every field is valid.
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), '30');
  await tester.enterText(fields.at(1), '180');
  await tester.enterText(fields.at(2), '80');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch runs onboarding and lands on Today with targets', (tester) async {
    await pumpApp(tester);
    await _throughBody(tester);

    await tester.tap(find.text('On my feet'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Rate: default 0.5%/week, and where it lands.
    expect(find.text('0.50'), findsOneWidget);
    expect(find.textContaining('Projected'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 1780 * 1.55 - 80 * 0.005 * 7700 / 7 = 2319
    expect(find.text('2,319'), findsOneWidget);
    // Nothing starts before the health-data consent.
    await tester.tap(find.text('Agree to continue'));
    await tester.pumpAndSettle();
    expect(find.text('Start logging'), findsNothing);
    await tester.ensureVisible(find.textContaining('I agree to Gymco'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('I agree to Gymco'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start logging'));
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
  });

  testWidgets('manual macros replace the calculated split', (tester) async {
    await pumpApp(tester);
    await _throughBody(tester);
    await tester.tap(find.text('On my feet'));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('2,319'), findsOneWidget);
    await tester.tap(find.text('Set my macros manually'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('More protein'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use these macros'));
    await tester.pumpAndSettle();
    // The split is rounded to whole grams, then 5 g of protein added.
    expect(find.text('2,319'), findsNothing);
  });

  testWidgets('searching and logging a food moves the day', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.scrollUntilVisible(find.text('Lunch'), 200, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Lunch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'chicken');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chicken breast, raw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log 1'));
    await tester.pumpAndSettle();

    // Logged at the 170 g fillet, then opened on the meal.
    expect((await db.entriesFor(dayKey(testNow))).single.grams, 170);
    expect(find.text('204'), findsOneWidget);

    // Change the portion with the keypad.
    await tester.tap(find.text('Chicken breast, raw'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.descendant(of: find.byType(Keypad), matching: find.byType(VIcon)));
    }
    for (final k in ['2', '0', '0']) {
      await tester.tap(find.descendant(of: find.byType(Keypad), matching: find.text(k)));
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save · 240 kcal'));
    await tester.pumpAndSettle();
    expect((await db.entriesFor(dayKey(testNow))).single.grams, 200);
  });

  testWidgets('a meal saves to My meals and copies to tomorrow', (tester) async {
    final (db, _) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      seed: (db) async {
        final f = (await db.searchFoods('oats')).first;
        await db.addEntry(LogEntry.of(f, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
      },
    );
    await tester.scrollUntilVisible(find.text('Breakfast'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save as a meal'));
    await tester.pumpAndSettle();
    expect(await db.savedMeals(), hasLength(1));

    await tester.tap(find.text('Copy to tomorrow'));
    await tester.pumpAndSettle();
    expect(await db.entriesFor(dayKey(testNow.add(const Duration(days: 1)))), hasLength(1));
  });

  testWidgets('offline search still finds foods saved on the phone', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, source: FakeFoodSource(offline: true));
    await tester.tap(find.bySemanticsLabel('Food').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'oats');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Oats, rolled'), findsOneWidget);
    expect(find.textContaining('Offline'), findsOneWidget);
  });

  testWidgets('a search with no match gets a way forward', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Food').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzqx');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('No match in the database'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
  });

  testWidgets('a phone that had numbers hidden shows them again', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile, 'noNumbers': true});
    expect(find.text('Numbers hidden'), findsNothing);
    expect(find.textContaining('kcal'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    expect(find.text('No-numbers mode'), findsNothing);
  });

  testWidgets('the Pro card opens Free vs Pro, with nothing to buy while testing', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Gymco Pro, free while testing'));
    await tester.pumpAndSettle();
    expect(find.text('Plans'), findsOneWidget);
    // Opens on Pro; yearly first, monthly on the switch.
    expect(find.text('€39.99'), findsOneWidget);
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('€4.99'), findsOneWidget);
    final top = tester.getTopLeft(find.byType(PageView)) + const Offset(200, 60);
    await tester.dragFrom(top, const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('Free, always'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
    expect(find.text('Goal and targets'), findsOneWidget);
  });

  testWidgets('water counts toward a goal from body weight, with undo and a day log', (tester) async {
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.scrollUntilVisible(find.text('+500'), 300, scrollable: find.byType(Scrollable).last);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('of 2.8 L'), findsOneWidget);
    await tester.tap(find.text('+500'));
    await tester.tap(find.text('+750'));
    await tester.pumpAndSettle();
    expect(find.text('1.25'), findsOneWidget);
    expect(prefs.getInt('water_${dayKey(testNow)}'), 1250);
    await tester.tap(find.bySemanticsLabel('Undo the last drink'));
    await tester.pumpAndSettle();
    expect(find.text('0.50'), findsOneWidget);

    await tester.tap(find.text('Hydration'));
    await tester.pumpAndSettle();
    expect(find.text('Water today'), findsOneWidget);
    expect(find.text('500 ml'), findsOneWidget);
  });

  testWidgets('turning reminders on schedules them; a refused permission says so', (tester) async {
    final reminders = FakeReminders();
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile}, reminders: reminders);
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Meals'), 300, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.bySemanticsLabel('Turn Meals reminders on or off'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Turn Meals reminders on or off'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('remindMeals'), isTrue);
    expect(reminders.scheduled, isNotEmpty);
    expect(reminders.scheduled.first.title, 'Lunch logged?');
    await tester.tap(find.bySemanticsLabel('Turn Meals reminders on or off'));
    await tester.pumpAndSettle();
    expect(reminders.scheduled, isEmpty);
  });

  testWidgets('a reminder opens to its times, and a moved time is what gets scheduled', (tester) async {
    final reminders = FakeReminders();
    await pumpApp(
      tester,
      prefs: {
        'profile': savedProfile,
        'remindMeals': true,
        'remindMealAt': ['8:00', '14:15', '21:00'],
      },
      reminders: reminders,
    );
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Meals'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('If a meal isn’t logged by 08:00, 14:15 or 21:00'), findsOneWidget);
    expect(reminders.scheduled.first.at, DateTime(2026, 9, 26, 14, 15));
    await tester.ensureVisible(find.text('Meals'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meals'));
    await tester.pumpAndSettle();
    expect(find.text('14:15'), findsOneWidget);
    await tester.tap(find.text('Lunch'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
  });

  testWidgets('a phone that refuses notifications keeps reminders off', (tester) async {
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile}, reminders: FakeReminders(allow: false));
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Water'), 300, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.bySemanticsLabel('Turn Water reminders on or off'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Turn Water reminders on or off'));
    await tester.pump();
    expect(find.textContaining('Notifications are off'), findsOneWidget);
    expect(prefs.getBool('remindWater'), isNull);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('delete everything goes back to a first run', (tester) async {
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      seed: (db) => db.setWeight(dayKey(testNow), 80),
    );
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Your data'), 200, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.text('Your data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Your data'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Delete all data'), 200, scrollable: find.byType(Scrollable).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, delete it all'));
    await tester.pumpAndSettle();
    expect(prefs.getString('profile'), isNull);
    expect(await db.weighIns(), isEmpty);
    expect(find.text('GET STARTED'), findsOneWidget);
  });

  testWidgets('Arabic runs right to left', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('ar'));
    expect(find.text('اليوم'), findsWidgets);
    final dir = Directionality.of(tester.element(find.text('اليوم').first));
    expect(dir, TextDirection.rtl);
  });

  testWidgets('Spanish translates the tabs', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('es'));
    expect(find.text('Hoy'), findsWidgets);
    expect(find.text('Comida'), findsWidgets);
  });
}
