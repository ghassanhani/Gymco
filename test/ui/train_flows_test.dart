import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    // Saturday is today, so Train now shows it as today's session.
    expect(find.text('Start all'), findsOneWidget);
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

  testWidgets('the Train tab reads right to left in Arabic', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('ar'));
    await openTrain(tester, label: 'التمرين');
    expect(find.text('لا برامج بعد'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('لا برامج بعد'))), TextDirection.rtl);
  });
}
