import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/awards.dart';
import 'package:gymco/state/celebration_providers.dart';

DayProgress day({
  String d = '2026-09-26',
  int meals = 0,
  bool trained = false,
  bool rest = true,
  int streak = 4,
  bool kept = false,
}) => DayProgress(day: d, meals: meals, trained: trained, rest: rest, streak: streak, kept: kept);

Award award(String id, {bool earned = false}) => Award(
  id: id,
  group: AwardGroup.food,
  shape: MedalShape.circle,
  tone: MedalTone.green,
  need: 1,
  have: earned ? 1 : 0,
);

void main() {
  test('the first read only remembers what is already earned', () {
    final r = decideCelebrations(before: null, after: day(meals: 1), awards: [award('f1', earned: true)], seen: {});
    expect(r.show, isEmpty);
    expect(r.seen, {'f1'});
  });

  test('a log that moves today forward shows the flame sheet from where it stood', () {
    final r = decideCelebrations(before: day(meals: 1), after: day(meals: 2), awards: const [], seen: {});
    final c = r.show.single as DayCelebration;
    expect(c.from, 0.5);
    expect(c.now.fraction, 0.75);
    expect(c.justKept, isFalse);
    expect(c.now.dayNumber, 5);
  });

  test('the log that keeps the day says so', () {
    final r = decideCelebrations(
      before: day(meals: 2),
      after: day(meals: 3, streak: 5, kept: true),
      awards: const [],
      seen: {},
    );
    final c = r.show.single as DayCelebration;
    expect(c.justKept, isTrue);
    expect(c.now.dayNumber, 5);
  });

  test('a workout counts the same as a meal; a rest day starts it done', () {
    expect(day(rest: false).done, 0);
    expect(day(rest: true).done, 1);
    final r = decideCelebrations(
      before: day(rest: false),
      after: day(rest: false, trained: true),
      awards: const [],
      seen: {},
    );
    expect(r.show.single, isA<DayCelebration>());
  });

  test('a new award takes the place of the flame sheet, once', () {
    final r = decideCelebrations(
      before: day(meals: 2),
      after: day(meals: 3, kept: true, streak: 5),
      awards: [award('f1', earned: true), award('s7')],
      seen: {},
    );
    expect((r.show.single as AwardCelebration).award.id, 'f1');
    final again = decideCelebrations(
      before: day(meals: 3, kept: true),
      after: day(meals: 3, kept: true),
      awards: [award('f1', earned: true)],
      seen: r.seen,
    );
    expect(again.show, isEmpty);
  });

  test('nothing for another day, a removal, or no change', () {
    expect(
      decideCelebrations(
        before: day(d: '2026-09-25', meals: 3),
        after: day(meals: 1),
        awards: const [],
        seen: {},
      ).show,
      isEmpty,
    );
    expect(decideCelebrations(before: day(meals: 2), after: day(meals: 1), awards: const [], seen: {}).show, isEmpty);
    expect(decideCelebrations(before: day(meals: 2), after: day(meals: 2), awards: const [], seen: {}).show, isEmpty);
  });
}
