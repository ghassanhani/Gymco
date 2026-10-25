import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/session.dart';

import '../helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a workout left open overnight saves at its last change', (tester) async {
    final last = testNow.subtract(const Duration(hours: 16));
    final s = WorkoutSession(
      name: 'Legs',
      startedAt: last.subtract(const Duration(minutes: 40)),
      touchedAt: last,
      exercises: const [
        SessionExercise(
          exerciseId: 'squat',
          name: 'Barbell Squat',
          sets: [SessionSet(weightKg: 100, reps: 5, done: true), SessionSet(weightKg: 100)],
        ),
      ],
    );
    final (db, prefs) = await pumpApp(
      tester,
      prefs: {'profile': savedProfile, 'activeWorkout': jsonEncode(s.toJson())},
      seed: (db) => db.saveRoutineFixture('Push A', weekday: 5),
    );
    expect(find.textContaining('Left open'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Save as done'));
    await settle(tester);
    final w = (await db.recentWorkouts()).single;
    expect(w.name, 'Legs');
    expect(w.endedAt, last);
    expect(prefs.getString('activeWorkout'), isNull);
  });

  testWidgets('not today: rest now and the session waits for tomorrow, undo puts it back', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, seed: (db) => db.saveRoutineFixture('Push A', weekday: 5));
    await tester.tap(find.bySemanticsLabel('More options'));
    await settle(tester);
    await tester.tap(find.text('Not today'));
    await settle(tester);
    await tester.tap(find.text('Rest today, train tomorrow'));
    await settle(tester);
    expect(find.bySemanticsLabel('Train anyway'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('More options'));
    await settle(tester);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(find.bySemanticsLabel('Start workout'), findsOneWidget);
  });

  testWidgets('a rest day can still be trained', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, seed: (db) => db.saveRoutineFixture('Pull A', weekday: 0));
    await tester.tap(find.bySemanticsLabel('Train anyway'));
    await settle(tester);
    await tester.tap(find.text('Pull A'));
    await settle(tester);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
  });
}
