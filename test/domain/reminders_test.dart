import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/reminders.dart';

void main() {
  // A Saturday, 12:00.
  final noon = DateTime(2026, 9, 26, 12);
  List<PlannedReminder> plan({
    ReminderSettings settings = const ReminderSettings(meals: true, water: true, workout: true),
    Set<ReminderKind> meals = const {},
    int water = 0,
    bool trained = false,
    Map<int, String> plan = const {5: 'Push A', 0: 'Pull A'},
  }) => planReminders(
    now: noon,
    settings: settings,
    mealsLoggedToday: meals,
    waterMlToday: water,
    waterGoalMl: 2800,
    trainedToday: trained,
    planByWeekday: plan,
  );

  List<(ReminderKind, int)> today(List<PlannedReminder> p) => [
    for (final r in p)
      if (r.at.day == 26) (r.kind, r.at.hour),
  ];

  test('today keeps only what is still due, and only later than now', () {
    expect(today(plan()), [
      (ReminderKind.lunch, 13),
      (ReminderKind.dinner, 20),
      (ReminderKind.water, 15),
      (ReminderKind.water, 18),
      (ReminderKind.workout, 17),
    ]);
  });

  test('a logged meal, water on pace and a done workout drop today\'s nudges', () {
    final p = plan(meals: {ReminderKind.lunch}, water: 2200, trained: true);
    expect(today(p), [(ReminderKind.dinner, 20)]);
  });

  test('the next days are planned in full, workouts only on plan days', () {
    final p = plan();
    final sunday = p.where((r) => r.at.day == 27).map((r) => r.kind).toList();
    expect(sunday.where((k) => k == ReminderKind.workout), isEmpty);
    final monday = p.where((r) => r.at.day == 28).toList();
    expect(monday.where((r) => r.kind == ReminderKind.workout).single.routine, 'Pull A');
    expect(monday.length, 7);
    expect(p.map((r) => r.id).toSet().length, p.length);
  });

  test('nothing is planned when every reminder is off', () {
    expect(plan(settings: const ReminderSettings()), isEmpty);
  });

  test('water pace runs evenly from 8:00 to 22:00', () {
    expect(waterPaceMl(2800, 8, 0), 0);
    expect(waterPaceMl(2800, 15, 0), 1400);
    expect(waterPaceMl(2800, 23, 0), 2800);
  });
}
