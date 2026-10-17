import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/streak.dart';

void main() {
  final start = DateTime(2026, 9, 1);
  DateTime day(int i) => start.add(Duration(days: i));
  StreakDay kept(int i, {bool rest = false}) =>
      StreakDay(date: day(i), mealsLogged: true, trained: !rest, plannedRest: rest);

  test('logged meals plus training or a planned rest keeps a day', () {
    expect(kept(0).kept, isTrue);
    expect(kept(0, rest: true).kept, isTrue);
    expect(StreakDay(date: day(0), mealsLogged: true).kept, isFalse);
    expect(StreakDay(date: day(0), trained: true).kept, isFalse);
  });

  test('a freeze every 7 kept days, held up to 3', () {
    final s = computeStreak(history: [for (var i = 0; i < 30; i++) kept(i)], start: start, now: day(29));
    expect(s.current, 30);
    expect(s.freezes, 3);
  });

  test('today unlogged does not break the run', () {
    final s = computeStreak(history: [for (var i = 0; i < 5; i++) kept(i)], start: start, now: day(5));
    expect(s.current, 5);
    expect(s.marks[day(5)], DayMark.today);
  });

  test('yesterday missed is repairable, not broken', () {
    final s = computeStreak(history: [for (var i = 0; i < 5; i++) kept(i)], start: start, now: day(6));
    expect(s.current, 5);
    expect(s.canRepair, isTrue);
  });

  test('an older miss spends a freeze', () {
    final s = computeStreak(
      history: [for (var i = 0; i < 7; i++) kept(i), for (var i = 8; i < 11; i++) kept(i)],
      start: start,
      now: day(10),
    );
    expect(s.marks[day(7)], DayMark.frozen);
    expect(s.current, 10);
    expect(s.freezes, 0);
  });

  test('a miss with no freeze breaks the run but keeps the best', () {
    final s = computeStreak(
      history: [for (var i = 0; i < 5; i++) kept(i), for (var i = 6; i < 9; i++) kept(i)],
      start: start,
      now: day(8),
    );
    expect(s.marks[day(5)], DayMark.missed);
    expect(s.current, 3);
    expect(s.best, 5);
  });
}
