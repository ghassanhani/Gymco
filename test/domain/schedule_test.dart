import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/schedule.dart';

void main() {
  // Saturday 26 September 2026, as in the prototype.
  final today = DateTime(2026, 9, 26);
  final days = stripDays(today);
  const push = PlannedRoutine(id: 1, name: 'Push A', weekday: 5); // Saturday
  const pull = PlannedRoutine(id: 2, name: 'Pull A', weekday: 2); // Wednesday
  const legs = PlannedRoutine(id: 3, name: 'Legs A', weekday: 4); // Friday
  const monday = PlannedRoutine(id: 4, name: 'Push B', weekday: 0);

  test('the strip runs four days back, today, two ahead', () {
    expect(days.first, DateTime(2026, 9, 22));
    expect(days.last, DateTime(2026, 9, 28));
  });

  test('done days show their log; due days ahead show their routine', () {
    final s = schedule(
      days: days,
      today: today,
      routines: const [push, pull, legs, monday],
      workouts: [
        DoneWorkout(day: DateTime(2026, 9, 23), name: 'Pull A', routineId: 2),
        DoneWorkout(day: DateTime(2026, 9, 25), name: 'Legs A', routineId: 3),
      ],
    );
    expect(s[1].done?.name, 'Pull A');
    expect(s[3].done?.name, 'Legs A');
    expect(s[4].routine, push);
    expect(s[4].today, isTrue);
    expect(s[5].rest, isTrue);
    expect(s[6].routine, monday);
    expect(s.any((d) => d.moved), isFalse);
  });

  test('a missed session slides to the next day, and the rest of the week with it', () {
    final s = schedule(
      days: days,
      today: today,
      routines: const [push, pull, legs, monday],
      workouts: [DoneWorkout(day: DateTime(2026, 9, 25), name: 'Legs A', routineId: 3)],
    );
    expect(s[1].missed, pull);
    expect(s[4].routine, pull);
    expect(s[4].moved, isTrue);
    // Push A, displaced from Saturday, waits for the next free day.
    expect(s[5].routine, push);
    expect(s[5].moved, isTrue);
    expect(s[6].routine, monday);
  });

  test('an any-day routine never enters the rotation', () {
    final s = schedule(
      days: days,
      today: today,
      routines: const [PlannedRoutine(id: 9, name: 'Arms', weekday: null)],
      workouts: const [],
    );
    expect(s.every((d) => d.rest), isTrue);
  });

  test('resting today moves the session to tomorrow; skipping drops it', () {
    final rest = schedule(
      days: days,
      today: today,
      routines: const [push, monday],
      workouts: const [],
      restDays: {today},
    );
    expect(rest[4].restTaken, push);
    expect(rest[4].routine, isNull);
    expect(rest[5].routine, push);
    expect(rest[5].moved, isTrue);
    expect(rest[6].routine, monday);

    final skip = schedule(
      days: days,
      today: today,
      routines: const [push, monday],
      workouts: const [],
      skipDays: {today},
    );
    expect(skip[4].skipped, push);
    expect(skip[5].rest, isTrue);
    expect(skip[6].routine, monday);
  });

  test('a past skipped day does not carry its routine forward', () {
    final s = schedule(
      days: days,
      today: today,
      routines: const [pull],
      workouts: const [],
      skipDays: {DateTime(2026, 9, 23)},
    );
    expect(s[1].skipped, pull);
    expect(s.skip(4).every((d) => d.routine == null), isTrue);
  });

  test('a routine made today owes nothing for the days before it', () {
    // Planned on Wednesday, created on Saturday: Wednesday was never missed.
    final wed = PlannedRoutine(id: 7, name: 'h1', days: const {2}, since: today);
    final s = schedule(days: days, today: today, routines: [wed], workouts: const []);
    expect(s[1].missed, isNull);
    expect(s[4].routine, isNull);
    expect(s.every((d) => !d.moved), isTrue);
  });

  test('one routine on several days runs on each; a miss is caught up once', () {
    const both = PlannedRoutine(id: 8, name: 'Full', days: {2, 5, 0}); // Mon, Wed, Sat
    final s = schedule(days: days, today: today, routines: const [both], workouts: const []);
    expect(s[1].missed, both);
    // Today was due anyway, so the missed Wednesday does not pile up.
    expect(s[4].routine, both);
    expect(s[5].rest, isTrue);
    expect(s[6].routine, both);
  });

  test('a moved routine says the day it was missed on', () {
    const wed = PlannedRoutine(id: 9, name: 'Pull', days: {2});
    final s = schedule(days: days, today: today, routines: const [wed], workouts: const []);
    expect(s[4].moved, isTrue);
    expect(s[4].movedFrom, DateTime(2026, 9, 23));
  });
}
