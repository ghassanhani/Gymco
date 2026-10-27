import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/ui/train/iron_screen.dart';

import '../helpers.dart';

void main() {
  final tip = {
    'title': 'Protein first today',
    'tip': 'You are 60 g under on protein. Make lunch count.',
    'action': 'log_food',
  };

  testWidgets('Iron asks before reading anything, then gives today\'s tip', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')..ironTip = tip;
    final (_, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      cloud: cloud,
      seed: (db) async {
        final oats = (await db.searchFoods('oats')).first;
        await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
      },
    );
    await tester.scrollUntilVisible(find.text('Meet Iron, your coach'), 300, scrollable: pageScroll);
    await tester.pumpAndSettle();
    expect(cloud.ironCalls, 0);
    await tester.tap(find.text('Turn on Iron'));
    await tester.pumpAndSettle();
    expect(cloud.ironCalls, 1);
    expect(find.text('Protein first today'), findsOneWidget);
    expect(find.text('Log food'), findsOneWidget);
    // Numbers only: what was eaten is not sent.
    final sent = jsonEncode(cloud.lastIronNumbers);
    expect(sent, isNot(contains('ats')));
    expect(sent, contains('"avg_kcal"'));
    expect(prefs.getBool('ironOn'), isTrue);
  });

  testWidgets('the tip is asked once a day', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')..ironTip = tip;
    await pumpApp(
      tester,
      prefs: {
        'profile': savedProfile,
        'ironOn': true,
        'ironTip': jsonEncode({...tip, 'day': dayKey(testNow)}),
      },
      cloud: cloud,
    );
    await tester.scrollUntilVisible(find.text('Protein first today'), 300, scrollable: pageScroll);
    expect(cloud.ironCalls, 0);
  });

  testWidgets('tips kept in another language are asked again in the app\'s', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')..ironTip = tip;
    await pumpApp(
      tester,
      prefs: {
        'profile': savedProfile,
        'ironOn': true,
        'lang': 'ar',
        'ironTips': jsonEncode({
          'day': dayKey(testNow),
          'tips': [tip],
        }),
      },
      cloud: cloud,
    );
    await tester.pumpAndSettle();
    expect(cloud.ironCalls, 1);
    expect(cloud.lastIronLanguage, 'ar');
  });

  testWidgets('today brings a few tips to swipe through, kept for the day', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')
      ..ironTip = {
        'tips': [
          tip,
          {
            'title': 'Water before noon',
            'tip': 'You are at 0 of 3,500 ml. Start with a glass.',
            'action': 'drink_water',
          },
          {'title': 'Sleep by eleven', 'tip': 'You slept 6 h. Aim for 7.', 'action': 'none'},
        ],
      };
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile, 'ironOn': true}, cloud: cloud);
    await tester.scrollUntilVisible(find.text('Protein first today'), 300, scrollable: pageScroll);
    await Scrollable.ensureVisible(tester.element(find.text('Protein first today')), alignment: 0.3);
    await tester.pumpAndSettle();
    expect(cloud.ironCalls, 1);
    expect(find.text('Log food'), findsOneWidget);
    await tester.fling(find.text('Protein first today'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Protein first today'), findsNothing);
    expect(find.text('Water before noon'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    // Doing what a tip says ticks it off.
    await tester.tap(find.text('Add water'));
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Add water'), findsNothing);
    expect(prefs.getString('waterlog_${dayKey(testNow)}'), endsWith(':250'));
    await tester.tap(find.byTooltip('3 of 4'));
    await tester.pumpAndSettle();
    expect(find.text('Sleep by eleven'), findsOneWidget);
    // Nothing to tap for this one, so it is ticked by hand.
    await tester.tap(find.byTooltip('Mark done'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    // After the tips, Iron's program is one swipe away.
    await tester.fling(find.text('Sleep by eleven'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Your program from Iron'), findsOneWidget);
    expect(jsonDecode(prefs.getString('ironTipsDone')!), {
      'day': dayKey(testNow),
      'done': [1, 2],
    });
    final kept = jsonDecode(prefs.getString('ironTips')!) as Map<String, Object?>;
    expect((kept['tips']! as List).length, 3);
  });

  testWidgets('a program from Iron sets targets safely and becomes the weekly plan', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')
      ..ironTip = tip
      ..ironProgram = {
        'summary': 'Hold maintenance and build the upper body.',
        'kcal': 1500,
        'protein': 170,
        'carbs': 150,
        'fat': 60,
        'why': 'Your weight is flat.',
        'routines': [
          {
            'name': 'Upper',
            'days': [0, 3],
            'items': [
              {'exercise': 'Barbell Bench Press', 'sets': 4, 'rep_low': 6, 'rep_high': 8, 'rest_seconds': 150},
            ],
          },
        ],
        'habits': ['Protein at every meal'],
      };
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'ironOn': true},
      cloud: cloud,
      seed: (db) => db.saveRoutineFixture('Old day', weekday: 2),
    );
    final before = (jsonDecode(prefs.getString('profile')!) as Map)['kcal'] as num;
    await tester.scrollUntilVisible(find.text('My program'), 300, scrollable: pageScroll);
    // To the middle of the screen, clear of the tab bar floating over the bottom.
    await Scrollable.ensureVisible(tester.element(find.text('My program')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('My program'));
    await tester.pumpAndSettle();
    await _build(tester, 'Build my program');
    await tester.pumpAndSettle();
    expect(find.text('Hold maintenance and build the upper body.'), findsOneWidget);
    // The screen's own list, not the note field's scroll inside it.
    final ironList = find
        .descendant(
          of: find.byType(IronScreen),
          matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
        )
        .first;
    await tester.scrollUntilVisible(find.text('Protein at every meal'), 300, scrollable: ironList);
    await tester.tap(find.text('Use this program'));
    await tester.pumpAndSettle();
    final after = (jsonDecode(prefs.getString('profile')!) as Map)['kcal'] as num;
    // Asked for 1500: it moves one safe step, not all the way.
    expect(after, before - 120);
    final routines = {for (final r in await db.routines()) r.name: r};
    expect(routines['Upper']!.days, {0, 3});
    expect(routines['Old day']!.days, isEmpty);
  });

  testWidgets('Iron is asked by picking, not typing: the picks go as the note', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')
      ..ironTip = tip
      ..ironProgram = {
        'summary': 'Three short sessions a week.',
        'kcal': 2200,
        'protein': 170,
        'carbs': 220,
        'fat': 70,
        'why': '',
        'routines': [],
        'habits': ['Walk after dinner'],
      };
    await pumpApp(
      tester,
      prefs: {
        'profile': savedProfile,
        'ironOn': true,
        'ironTip': jsonEncode({...tip, 'day': dayKey(testNow)}),
      },
      cloud: cloud,
    );
    await tester.scrollUntilVisible(find.text('My program'), 300, scrollable: pageScroll);
    await Scrollable.ensureVisible(tester.element(find.text('My program')), alignment: 0.5);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Ask Iron for a program…'), findsNothing);
    await tester.tap(find.text('My program'));
    await tester.pumpAndSettle();
    expect(find.byType(IronScreen), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('3'));
    await tester.tap(find.text('30 min'));
    await tester.pump();
    await _build(tester, 'Build my program');
    await tester.pumpAndSettle();
    expect(find.text('Days a week: 3. Time per session: 30 min.'), findsOneWidget);
    expect(find.text('Three short sessions a week.'), findsOneWidget);
    expect(cloud.ironCalls, 1);
  });

  testWidgets('the Iron Center keeps what Iron made, and opens it again without asking twice', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')
      ..ironTip = tip
      ..ironProgram = {
        'summary': 'Three short sessions a week.',
        'kcal': 2200,
        'protein': 170,
        'carbs': 220,
        'fat': 70,
        'why': '',
        'routines': [],
        'habits': ['Walk after dinner'],
      };
    final (_, prefs) = await pumpApp(
      tester,
      prefs: {
        'profile': savedProfile,
        'ironOn': true,
        'ironTip': jsonEncode({...tip, 'day': dayKey(testNow)}),
      },
      cloud: cloud,
    );
    await tester.scrollUntilVisible(find.byTooltip('Iron Center'), 300, scrollable: pageScroll);
    await Scrollable.ensureVisible(tester.element(find.byTooltip('Iron Center')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Iron Center'));
    await tester.pumpAndSettle();
    expect(find.text('Iron Center'), findsOneWidget);
    expect(find.text('Build a routine'), findsOneWidget);
    // Ask from the Center: Iron's screen opens with the program.
    await tester.tap(find.text('My program').last);
    await tester.pumpAndSettle();
    await _build(tester, 'Build my program');
    await tester.pumpAndSettle();
    expect(find.text('Three short sessions a week.'), findsOneWidget);
    expect(cloud.ironCalls, 1);
    expect(prefs.getString('ironHistory'), contains('Three short sessions a week.'));
    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();
    // It is in the history now; opening it again costs nothing.
    final centerList = find
        .descendant(
          of: find.byType(Scaffold).last,
          matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down),
        )
        .first;
    await tester.scrollUntilVisible(find.text('Three short sessions a week.'), 300, scrollable: centerList);
    await tester.tap(find.text('Three short sessions a week.'));
    await tester.pumpAndSettle();
    expect(find.text('Walk after dinner'), findsOneWidget);
    expect(cloud.ironCalls, 1);
  });

  testWidgets('with Iron out of reach, the card still has tips from the phone', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')..paused = true;
    await pumpApp(tester, prefs: {'profile': savedProfile, 'ironOn': true}, cloud: cloud);
    await tester.scrollUntilVisible(find.textContaining('from your numbers on the phone'), 300, scrollable: pageScroll);
    await tester.pumpAndSettle();
    // Nothing logged yet today, so that comes first, with its button.
    expect(find.text('Log your first meal'), findsOneWidget);
    expect(find.text('Log food'), findsOneWidget);
  });
}

/// Picks Iron's options and builds: the button sits under the choices.
Future<void> _build(WidgetTester tester, String label) async {
  final list = find.descendant(of: find.byType(Scaffold).last, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(find.text(label).last, 200, scrollable: list);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
}
