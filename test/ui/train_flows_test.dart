import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/session.dart';

import '../helpers.dart';

/// The workout screen repaints every second, so it never "settles"; pump a
/// fixed time instead, enough for a page transition.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> openTrain(WidgetTester tester, {String label = 'Train'}) async {
  await tester.tap(find.bySemanticsLabel(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('build a routine: Save waits for a name and an exercise', (tester) async {
    final (db, _) = await pumpApp(tester, prefs: {'profile': savedProfile});
    await openTrain(tester);
    expect(find.text('No routines yet'), findsOneWidget);

    await tester.tap(find.text('New routine'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(InkWell, 'Save');
    expect(tester.widget<InkWell>(save).onTap, isNull);

    await tester.enterText(find.byType(TextField), 'Push A');
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.tap(find.text('Side Lateral Raise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 2 exercises'));
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(save).onTap, isNotNull);

    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Push A'), findsOneWidget);
    expect(find.text('2 exercises · 6 sets'), findsOneWidget);
    expect((await db.routines()).single.items.map((i) => i.exerciseId), ['bench', 'lat']);
  });

  testWidgets('a duplicate routine name is refused', (tester) async {
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      seed: (db) async {
        await db.saveRoutineFixture('Push A');
      },
    );
    await openTrain(tester);
    await tester.tap(find.text('New routine'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'push a');
    await tester.tap(find.text('Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbell Squat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add 1 exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('You already have a routine called'), findsOneWidget);
  });

  testWidgets('run a routine: tick sets, rest runs, finish saves to history', (tester) async {
    var now = testNow;
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      clock: () => now,
      seed: (db) => db.saveRoutineFixture('Push A'),
    );
    await openTrain(tester);
    await tester.tap(find.text('Start'));
    await settle(tester);

    expect(find.text('0 / 3'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '5');
    await tester.pump();
    await tester.tap(find.byTooltip('Tick set').first);
    await tester.pump();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('500 kg'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    // The live workout is on the phone already, before Finish.
    expect(prefs.getString('activeWorkout'), isNotNull);

    now = now.add(const Duration(seconds: 95));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Rest'), findsNothing);

    now = now.add(const Duration(minutes: 40));
    await tester.tap(find.text('Finish'));
    await settle(tester);
    expect(find.text("Some sets aren't ticked"), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Finish'));
    await settle(tester);
    expect(find.text('Workout done'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await settle(tester);

    final w = (await db.recentWorkouts()).single;
    expect(w.sets, 1);
    expect(w.volume, 500);
    expect(prefs.getString('activeWorkout'), isNull);
    expect(find.text('Push A'), findsWidgets);
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
    expect(find.text('Legs'), findsOneWidget);
    expect(find.text('Workout in progress · 12:00'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await settle(tester);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('600 kg'), findsOneWidget);
  });

  testWidgets('the Train tab reads right to left in Arabic', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, locale: const Locale('ar'));
    await openTrain(tester, label: 'التمرين');
    expect(find.text('لا برامج بعد'), findsOneWidget);
    expect(Directionality.of(tester.element(find.text('البرامج'))), TextDirection.rtl);
  });
}
