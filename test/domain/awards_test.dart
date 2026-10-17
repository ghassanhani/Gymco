import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/awards.dart';
import 'package:gymco/domain/streak.dart';

void main() {
  DateTime d(int n) => DateTime(2026, 9, n);

  test('milestones are dated the day the run first reaches them', () {
    final marks = {for (var i = 1; i <= 16; i++) d(i): DayMark.kept};
    marks[d(5)] = DayMark.frozen;
    final m = milestoneDates(marks);
    // Day 5 is frozen: it holds the run but does not add, so 7 lands on day 8.
    expect(m[7], d(8));
    expect(m[14], d(15));
    expect(m.containsKey(30), isFalse);
  });

  test('a missed day resets the run, and the next kept day is the comeback', () {
    final marks = {d(1): DayMark.kept, d(2): DayMark.missed, d(3): DayMark.kept};
    expect(comebackDate(marks), d(3));
    expect(comebackDate({d(1): DayMark.kept}), isNull);
  });

  test('awards count logging and showing up', () {
    final streak = StreakState(
      current: 9,
      best: 9,
      freezes: 1,
      keptTotal: 9,
      marks: {for (var i = 1; i <= 9; i++) d(i): DayMark.kept},
    );
    final list = awards(
      AwardStats(
        streak: streak,
        fullDays: [d(1), d(2)],
        mealsLogged: 40,
        bestProteinWeek: 7,
        workouts: 3,
        firstWorkout: d(2),
        prs: 2,
        workoutsThisMonth: 3,
      ),
    );
    Award a(String id) => list.firstWhere((x) => x.id == id);
    expect(a('s7').earned, isTrue);
    expect(a('s7').earnedOn, d(7));
    expect(a('s14').toGo, 5);
    expect(a('f1').earned, isTrue);
    expect(a('fp').earned, isTrue);
    expect(a('f100').toGo, 60);
    expect(a('t1').earnedOn, d(2));
    expect(nextStreakAward(list)?.id, 's14');
  });

  test('the best protein week counts days inside one Monday-to-Sunday week', () {
    // 21–27 Sep 2026 is Monday to Sunday.
    expect(bestProteinWeek([d(21), d(22), d(23), d(27), d(28)]), 4);
  });
}
