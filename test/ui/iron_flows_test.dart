import 'dart:convert';

import 'package:flutter/widgets.dart';
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
    await tester.tap(find.byTooltip('Build my program'));
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
}
