import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/training.dart';
import 'package:gymco/domain/session.dart';
import 'package:gymco/ui/kit/kit.dart';

import '../helpers.dart';

/// A live workout repaints every second, so it never "settles"; pump a
/// fixed time instead, enough for a page transition.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openTrain(WidgetTester tester, {String label = 'Train'}) async {
  await tester.tap(find.bySemanticsLabel(label).first);
  await settle(tester);
}

Future<void> key(WidgetTester t, String k) =>
    t.tap(find.descendant(of: find.byType(Keypad), matching: k == 'del' ? find.byType(VIcon) : find.text(k)));

void main() {
  testWidgets('build a routine: Save waits for a name and an exercise', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await openTrain(tester);
    expect(find.text('No routines yet'), findsOneWidget);

    await tester.tap(find.text('Build my own routine'));
    await settle(tester);
    expect(find.text('Give it a name to save'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Push A');
    await tester.pump();
    expect(find.text('Add at least one exercise'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await settle(tester);
    await tester.tap(find.text('Add exercise'));
    await settle(tester);
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.tap(find.text('Side Lateral Raise'));
    await tester.pump();
    await tester.tap(find.text('Add 2 exercises'));
    await settle(tester);
    expect(find.text('6 sets · about 19 min'), findsOneWidget);

    await tester.tap(find.text('Sat'));
    await tester.tap(find.text('Save routine'));
    await settle(tester);
    final r = (await db.routines()).single;
    expect(r.items.map((i) => i.exerciseId), ['bench', 'lat']);
    expect(r.weekday, 5);
    // A routine with a day belongs to the weekly plan.
    expect(r.folder, RoutineFolder.plan);
    // Saturday is today, so Train now shows it as today's session.
    expect(find.text('Start all'), findsOneWidget);
  });

  testWidgets('an exercise not in the library is made on the spot, and a routine takes several days', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await openTrain(tester);
    await tester.tap(find.text('Build my own routine'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Home day');
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await settle(tester);
    await tester.tap(find.text('Add exercise'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Towel row');
    await settle(tester);
    await tester.tap(find.text('Create “Towel row”'));
    await settle(tester);
    await tester.tap(find.text('Lats').last);
    await tester.ensureVisible(find.text('Bodyweight'));
    await tester.tap(find.text('Bodyweight'));
    await tester.pump();
    await tester.ensureVisible(find.text('Create exercise'));
    await tester.pump();
    await tester.tap(find.text('Create exercise'));
    await settle(tester);
    await tester.tap(find.text('Add 1 exercise'));
    await settle(tester);
    expect(find.text('Towel row'), findsWidgets);

    await tester.tap(find.text('Mon'));
    await tester.tap(find.text('Thu'));
    await tester.tap(find.text('Save routine'));
    await settle(tester);
    final r = (await db.routines()).single;
    expect(r.days, {0, 3});
    expect(r.items.single.exerciseId, startsWith('custom:towel-row'));
    expect((await db.customExercises()).single.primary, ['lats']);
  });

  testWidgets('a routine with no day is kept in My routines', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await openTrain(tester);
    await tester.tap(find.text('Build my own routine'));
    await settle(tester);
    expect(find.text('WHICH DAYS?'), findsOneWidget);
    expect(find.text('No day picked: it stays in My routines, ready any time.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Arms');
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await settle(tester);
    await tester.tap(find.text('Add exercise'));
    await settle(tester);
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pump();
    await tester.tap(find.text('Add 1 exercise'));
    await settle(tester);
    expect(find.text('Save routine'), findsOneWidget);
    await tester.tap(find.text('Save routine'));
    await settle(tester);
    final r = (await db.routines()).single;
    expect(r.days, isEmpty);
    expect(r.folder, RoutineFolder.mine);
  });

  testWidgets('a routine described in words is built by the AI and added to the plan', (tester) async {
    final cloud = FakeCloud(
      signedIn: 'me@example.com',
      plan: {
        'summary': 'Two upper days and one for legs.',
        'routines': [
          {
            'name': 'Upper',
            'days': [0, 3],
            'items': [
              {'exercise': 'Barbell Bench Press', 'sets': 4, 'rep_low': 6, 'rep_high': 8, 'rest_seconds': 150},
              {'exercise': 'Side Lateral Raise', 'sets': 3, 'rep_low': 12, 'rep_high': 15, 'rest_seconds': 60},
            ],
          },
          {
            'name': 'Legs',
            'days': [5],
            'items': [
              {'exercise': 'Barbell Squat', 'sets': 4, 'rep_low': 5, 'rep_high': 8, 'rest_seconds': 180},
            ],
          },
        ],
      },
    );
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await openTrain(tester);
    await tester.tap(find.text('Ask Iron to build it'));
    await settle(tester);
    // Picked, not typed.
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('4'));
    await tester.tap(find.text('60 min'));
    await tester.pump();
    await _tapBuild(tester);
    await settle(tester);
    expect(cloud.lastPlanText, 'Days a week: 4. Time per session: 60 min.');
    expect(cloud.lastPlanNames, contains('Barbell Bench Press'));
    expect(find.text('Two upper days and one for legs.'), findsOneWidget);
    expect(find.text('Upper'), findsOneWidget);
    expect(find.text('4 × 6–8'), findsOneWidget);
    await tester.tap(find.text('Add 2 routines to my plan'));
    await settle(tester);
    final saved = {for (final r in await db.routines()) r.name: r};
    expect(saved['Upper']!.days, {0, 3});
    expect(saved['Legs']!.items.single.exerciseId, 'squat');
    // Saturday is today: Legs is today's session now.
    expect(find.text('Start all'), findsOneWidget);
  });

  testWidgets('the AI routine builder asks a signed-out user to sign in', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: FakeCloud());
    await openTrain(tester);
    await tester.tap(find.text('Ask Iron to build it'));
    await settle(tester);
    await _tapBuild(tester);
    await settle(tester);
    expect(find.textContaining('Sign in to use the AI'), findsOneWidget);
  });

  testWidgets('a duplicate routine name is refused', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, seed: (db) => db.saveRoutineFixture('Push A'));
    await openTrain(tester);
    await tester.tap(find.text('All routines'));
    await settle(tester);
    await tester.tap(find.text('New'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'push a');
    await tester.pump();
    expect(find.text('That name is taken'), findsOneWidget);
    expect(find.textContaining('You already have a routine called'), findsOneWidget);
  });

  testWidgets('a template fills the weekly plan', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await openTrain(tester);
    await tester.tap(find.text('Upper / Lower, 4 days'));
    await settle(tester);
    final all = await db.routines();
    expect(all.map((r) => r.weekday).toSet(), {0, 1, 3, 4});
    expect(all.map((r) => r.name), containsAll(['Upper A', 'Lower A', 'Upper B', 'Lower B']));
  });

  testWidgets('run a routine: type a set, tick it, rest runs, finish saves to history', (tester) async {
    var now = testNow;
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      clock: () => now,
      seed: (db) => db.saveRoutineFixture('Push A', weekday: 5),
    );
    await openTrain(tester);
    await tester.tap(find.text('Start all'));
    await settle(tester);
    expect(find.text('0 / 3'), findsOneWidget);

    // No weight yet: the tick opens the number pad instead.
    await tester.tap(find.bySemanticsLabel('Complete set 1'));
    await settle(tester);
    for (final k in ['1', '0', '0']) {
      await key(tester, k);
    }
    await tester.tap(find.text('REPS').last);
    for (final k in ['del', '5']) {
      await key(tester, k);
    }
    await tester.tap(find.text('Done'));
    await settle(tester);
    // The weight carries down to the empty sets below.
    expect(find.text('100'), findsNWidgets(3));

    await tester.tap(find.bySemanticsLabel('Complete set 1'));
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('500 kg'), findsOneWidget);
    expect(find.text('RESTING'), findsOneWidget);
    expect(prefs.getString('activeWorkout'), isNotNull);

    now = now.add(const Duration(seconds: 95));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('RESTING'), findsNothing);

    now = now.add(const Duration(minutes: 40));
    await tester.tap(find.text('Finish'));
    await settle(tester);
    expect(find.text('Push A — done'), findsOneWidget);
    expect(find.text('2 sets were left unticked — they are not in the log'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);

    final w = (await db.recentWorkouts()).single;
    expect(w.sets, 1);
    expect(w.volume, 500);
    expect(prefs.getString('activeWorkout'), isNull);
    expect(find.text('CLOSED'), findsOneWidget);
  });

  testWidgets('a ticked set puts the end of rest on the phone, and finishing takes it off', (tester) async {
    final reminders = FakeReminders();
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'notifyAllowed': true},
      reminders: reminders,
      seed: (db) => db.saveRoutineFixture('Push A', weekday: 5),
    );
    await openTrain(tester);
    await tester.tap(find.text('Start all'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Complete set 1'));
    await settle(tester);
    for (final k in ['1', '0', '0']) {
      await key(tester, k);
    }
    await tester.tap(find.text('Done'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Complete set 1'));
    await tester.pump();
    await tester.pump();
    final rest = reminders.timer.firstWhere((n) => n.urgent);
    expect(rest.title, '⏱️ Rest\'s up');
    expect(rest.body, 'Set 2 of Barbell Bench Press.');
    expect(reminders.timer.map((n) => n.title), contains('🏋️ Workout still open'));
    await tester.tap(find.text('Finish'));
    await settle(tester);
    await tester.tap(find.text('Done'));
    await settle(tester);
    expect(reminders.timer, isEmpty);
  });

  testWidgets('one exercise of the day starts on its own', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, seed: (db) => db.saveRoutineFixture('Push A', weekday: 5));
    await openTrain(tester);
    await tester.tap(find.bySemanticsLabel('Start Barbell Bench Press on its own'));
    await settle(tester);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsWidgets);
  });

  testWidgets('a set changes type from its sheet', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, seed: (db) => db.saveRoutineFixture('Push A', weekday: 5));
    await openTrain(tester);
    await tester.tap(find.bySemanticsLabel('Start Barbell Bench Press on its own'));
    await settle(tester);
    for (final (type, mark) in [('Warm-up', 'W'), ('Failure', 'F'), ('Drop set', 'D')]) {
      await tester.tap(find.bySemanticsLabel(RegExp('^Set type')).first);
      await settle(tester);
      await tester.tap(find.text(type));
      await settle(tester);
      expect(find.text(mark), findsOneWidget, reason: type);
    }
  });

  testWidgets('a workout left running comes back after the app restarts', (tester) async {
    final s = WorkoutSession.start(
      name: 'Legs',
      now: testNow.subtract(const Duration(minutes: 12)),
      exercises: const [
        SessionExercise(
          exerciseId: 'squat',
          name: 'Barbell Squat',
          sets: [SessionSet(weightKg: 120, reps: 5, done: true)],
        ),
      ],
    );
    await pumpApp(tester, prefs: {'profile': savedProfile, 'activeWorkout': jsonEncode(s.toJson())});
    await openTrain(tester);
    expect(find.text('Legs in progress'), findsOneWidget);
    expect(find.text('12:00 · 1 of 1 sets'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await settle(tester);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('600 kg'), findsOneWidget);
  });

  testWidgets('swap an exercise mid-workout, then flag pain on a set', (tester) async {
    final s = WorkoutSession.start(
      name: 'Shoulders',
      now: testNow.subtract(const Duration(minutes: 5)),
      exercises: const [
        SessionExercise(
          exerciseId: 'ohp',
          name: 'Standing Military Press',
          sets: [SessionSet(weightKg: 50, reps: 5, done: true), SessionSet(weightKg: 50), SessionSet(weightKg: 50)],
        ),
      ],
    );
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile, 'activeWorkout': jsonEncode(s.toJson())});
    await openTrain(tester);
    await tester.tap(find.text('Resume'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel('Options for Standing Military Press'));
    await settle(tester);
    await tester.tap(find.text('Swap exercise'));
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsNothing, reason: 'chest is not shoulders');
    await tester.tap(find.text('Side Lateral Raise'));
    await settle(tester);
    expect(find.text('Side Lateral Raise'), findsOneWidget);
    expect(find.text('Standing Military Press'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Set type')).last);
    await settle(tester);
    await tester.tap(find.text('Flag pain'));
    await settle(tester);
    await tester.tap(find.text('Shoulder'));
    await settle(tester);
    await tester.tap(find.text('Sharp: stop this exercise'));
    await settle(tester);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Pain flagged: Shoulder')), findsOneWidget);
    expect(prefs.getString('painFlags'), contains('shoulder'));
  });

  testWidgets('the Train tab reads right to left in Arabic', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('ar'));
    await openTrain(tester, label: 'التمرين');
    expect(find.text('لا برامج بعد'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('لا برامج بعد'))), TextDirection.rtl);
  });
}

/// The routine builder's button, under its choices.
Future<void> _tapBuild(WidgetTester tester) async {
  final list = find.descendant(of: find.byType(Scaffold).last, matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(find.text('Build my routine').last, 200, scrollable: list);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Build my routine').last);
}
