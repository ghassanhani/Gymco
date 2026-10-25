import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/domain/coach.dart';

import '../helpers.dart';

void main() {
  final tip = {'title': 'Protein first today', 'tip': 'Make lunch count.', 'action': 'log_food'};
  final parqYes = jsonEncode({
    'parq': [false, true, false, false, false, false, false],
  });

  Future<void> toIron(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(find.text(text), 300, scrollable: pageScroll);
    await tester.pumpAndSettle();
  }

  testWidgets('a yes on the PAR-Q+ puts a doctor first, until the user says they are cleared', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')..ironTip = tip;
    final (_, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'ironOn': true, 'ironHealth': parqYes},
      cloud: cloud,
    );
    await toIron(tester, 'Check with your doctor first');
    expect(find.text('Iron is a coach, not a doctor.'), findsOneWidget);
    expect(find.text('Protein first today'), findsNothing);
    await tester.ensureVisible(find.text("I'm cleared"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I'm cleared"));
    await tester.pumpAndSettle();
    expect(find.text('Check with your doctor first'), findsNothing);
    expect((jsonDecode(prefs.getString('ironHealth')!) as Map)['cleared'], isTrue);
  });

  testWidgets('"Got it" puts a warning away for a few days', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')..ironTip = tip;
    final (_, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'ironOn': true, 'ironHealth': parqYes},
      cloud: cloud,
    );
    await toIron(tester, 'Check with your doctor first');
    await tester.ensureVisible(find.text('Got it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Check with your doctor first'), findsNothing);
    expect((jsonDecode(prefs.getString('ironDismissed')!) as Map)['needs_clearance'], dayKey(testNow));
  });

  testWidgets('food names and the health profile reach Iron only when the user allows it', (tester) async {
    Future<String> sent(Map<String, Object> extra) async {
      final cloud = FakeCloud(signedIn: 'me@example.com')..ironTip = tip;
      await pumpApp(
        tester,
        prefs: {
          'profile': savedProfile,
          'ironOn': true,
          'ironHealth': jsonEncode({
            'injuries': ['knee'],
            'parq': List.filled(7, false),
          }),
          ...extra,
        },
        cloud: cloud,
        seed: (db) async {
          final oats = (await db.searchFoods('oats')).first;
          await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
        },
      );
      await toIron(tester, 'Protein first today');
      return jsonEncode(cloud.lastIronNumbers);
    }

    final plain = await sent({});
    expect(plain, isNot(contains('ats')));
    expect(plain, isNot(contains('"health"')));
    expect(plain, contains('"signals"'));
    final shared = await sent({'ironShareFood': true, 'ironShareHealth': true});
    expect(shared, contains('"meals_3d"'));
    expect(shared, contains('ats'));
    expect(shared, contains('"injuries":["knee"]'));
  });

  testWidgets('the weekly review is asked once a week', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com')
      ..ironTip = tip
      ..ironReview = {
        'headline': 'Four sessions and protein on target five days.',
        'wins': ['Trained every planned day'],
        'slips': ['Water was low on the weekend'],
        'next': ['Add one set to rows'],
      };
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile, 'ironOn': true}, cloud: cloud);
    await toIron(tester, 'Protein first today');
    await Scrollable.ensureVisible(tester.element(find.byTooltip('Iron Center')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Iron Center'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('This week with Iron'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This week with Iron'));
    await tester.pumpAndSettle();
    expect(find.text('Four sessions and protein on target five days.'), findsOneWidget);
    expect(find.text('Add one set to rows'), findsOneWidget);
    final calls = cloud.ironCalls;
    expect((jsonDecode(prefs.getString('ironReview')!) as Map)['week'], weekKey(testNow));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('This week with Iron'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('This week with Iron'));
    await tester.pumpAndSettle();
    expect(cloud.ironCalls, calls);
  });
}
