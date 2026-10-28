import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/notifications.dart';
import 'package:gymco/domain/reminders.dart';

void main() {
  // A Saturday, 12:00.
  final noon = DateTime(2026, 9, 26, 12);
  const everything = NoteSwitches(
    meals: true,
    protein: true,
    water: true,
    workout: true,
    weighIn: true,
    streak: true,
    checkIn: true,
    iron: true,
    timer: true,
    account: true,
    mealAt: {ReminderKind.breakfast: (8, 0), ReminderKind.lunch: (13, 0), ReminderKind.dinner: (19, 30)},
  );
  NoteFacts facts({
    DateTime? now,
    Region region = Region.other,
    Set<ReminderKind> meals = const {},
    int water = 0,
    bool trained = false,
    bool kept = false,
    Map<int, PlanDay> plan = const {},
    Set<NoteKind> backedOff = const {},
    double protein = 0,
  }) => NoteFacts(
    now: now ?? noon,
    region: region,
    mealsLoggedToday: meals,
    waterToday: water,
    waterGoal: 2800,
    trainedToday: trained,
    keptToday: kept,
    streak: 23,
    plan: plan,
    movesTo: {for (final d in plan.keys) d: 3},
    proteinToday: protein,
    proteinTarget: 160,
    backedOff: backedOff,
  );

  List<NoteKind> on(List<Note> notes, int day) => [
    for (final n in notes)
      if (n.at.day == day) n.kind,
  ];

  test('meal reminders go 45 minutes after the meal, only while it is empty', () {
    final notes = planNotes(facts(), const NoteSwitches(meals: true, mealAt: {ReminderKind.lunch: (13, 0)}));
    expect(notes.first.kind, NoteKind.lunch);
    expect(notes.first.at, DateTime(2026, 9, 26, 13, 45));
    final logged = planNotes(
      facts(meals: {ReminderKind.lunch}),
      const NoteSwitches(meals: true, mealAt: {ReminderKind.lunch: (13, 0)}),
    );
    expect(on(logged, 26), isEmpty);
  });

  test('at most 3 a day, keeping the most valuable', () {
    final notes = planNotes(facts(plan: {0: const PlanDay(name: 'Push', exercises: 6, minutes: 55)}), everything);
    final today = on(notes, 26);
    expect(today.length, 3);
    expect(today, containsAll([NoteKind.streakRisk, NoteKind.workout, NoteKind.sessionMoved]));
  });

  test('the workout timer is never cut by the cap', () {
    final f = NoteFacts(
      now: noon,
      region: Region.other,
      restEndsAt: noon.add(const Duration(seconds: 90)),
      restExercise: 'Bench Press',
      restSet: 3,
      workoutActiveAt: noon,
    );
    final notes = planNotes(f, const NoteSwitches(timer: true));
    expect(notes.map((n) => n.kind), [NoteKind.restOver, NoteKind.workoutOpen]);
    expect(notes.first.data, {'exercise': 'Bench Press', 'set': 3});
  });

  test('nothing goes off in quiet hours', () {
    const late = NoteSwitches(meals: true, mealAt: {ReminderKind.dinner: (22, 30)});
    expect(planNotes(facts(), late), isEmpty);
  });

  test('during Friday prayer in the Gulf a reminder waits until after', () {
    final friday = DateTime(2026, 10, 2, 9);
    final notes = planNotes(
      facts(now: friday, region: Region.gulf),
      const NoteSwitches(meals: true, mealAt: {ReminderKind.lunch: (11, 30)}),
      days: 1,
    );
    expect(notes.single.at, DateTime(2026, 10, 2, 13, 30));
  });

  test('a reminder ignored 5 days running goes every other day', () {
    const water = NoteSwitches(water: true, waterAt: [(11, 0)]);
    final normal = planNotes(facts(now: DateTime(2026, 9, 26, 9)), water);
    final backed = planNotes(facts(now: DateTime(2026, 9, 26, 9), backedOff: {NoteKind.water}), water);
    expect(normal.length, 7);
    expect(backed.length, 4);
    expect(
      backedOffKinds({
        NoteKind.water: [true, true, true, true, true],
      }),
      {NoteKind.water},
    );
    expect(
      backedOffKinds({
        NoteKind.water: [true, true, false, true, true],
      }),
      isEmpty,
    );
  });

  test('protein short goes 2 h before dinner, only under 70%', () {
    const p = NoteSwitches(protein: true, mealAt: {ReminderKind.dinner: (19, 30)});
    final short = planNotes(facts(protein: 60), p);
    expect(short.single.at, DateTime(2026, 9, 26, 17, 30));
    expect(short.single.data['grams'], 100);
    expect(planNotes(facts(protein: 130), p), isEmpty);
  });

  test('a kept day has no streak warning; the check-in follows the region', () {
    const s = NoteSwitches(streak: true, checkIn: true);
    expect(on(planNotes(facts(kept: true), s), 26), isEmpty);
    final gulf = planNotes(facts(now: DateTime(2026, 9, 26, 9), region: Region.gulf, kept: true), s).where((n) => n.kind == NoteKind.checkIn);
    expect(gulf.single.at, DateTime(2026, 9, 26, 10));
    final other = planNotes(facts(), s).where((n) => n.kind == NoteKind.checkIn);
    expect(other.single.at, DateTime(2026, 9, 28, 9));
  });

  test('the region sets meal hours', () {
    expect(regionOf('SA', 'en'), Region.gulf);
    expect(regionOf('ES', 'es'), Region.spain);
    expect(regionOf('US', 'en'), Region.other);
    expect(regionMealTimes(Region.spain)[ReminderKind.dinner], (22, 0));
  });

  test('ids are unique and nothing is planned with everything off', () {
    final notes = planNotes(facts(now: DateTime(2026, 9, 26, 7, 10)), everything);
    expect(notes.map((n) => n.id).toSet().length, notes.length);
    expect(planNotes(facts(), const NoteSwitches()), isEmpty);
  });

  test('water pace runs evenly from 8:00 to 22:00', () {
    expect(waterPaceMl(2800, 8, 0), 0);
    expect(waterPaceMl(2800, 15, 0), 1400);
    expect(waterPaceMl(2800, 23, 0), 2800);
  });
}
