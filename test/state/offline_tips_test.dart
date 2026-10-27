import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/coach.dart';
import 'package:gymco/state/offline_tips.dart';

Map<String, Object?> numbers({
  int hour = 13,
  int kcal = 900,
  int protein = 60,
  List<String> meals = const ['breakfast'],
  int water = 500,
  String? planned = 'Upper A',
  bool trained = false,
  int? score,
  int? sleepMin,
  int streak = 0,
}) => {
  'now': {'hour': hour},
  'targets': {'kcal': 2200, 'protein': 180},
  'today': {
    'kcal': kcal,
    'protein': protein,
    'meals_logged': meals,
    'water_ml': water,
    'water_goal_ml': 3000,
    'trained': trained,
    'planned_workout': ?planned,
  },
  if (score != null || sleepMin != null) 'recovery': {'score': ?score, 'sleep_min': ?sleepMin},
  if (streak > 0) 'streak': {'current': streak},
};

void main() {
  test('three tips from the real numbers: protein, the planned session, water', () {
    final tips = offlineTips(numbers(), languageCode: 'en', day: '2026-09-26');
    expect([for (final t in tips) t.title], ['120 g of protein to go', 'Upper A is on today', '2500 ml of water to go']);
    expect(tips.first.tip, contains('about 60 g'));
    expect([for (final t in tips) t.action], [IronAction.logFood, IronAction.startWorkout, IronAction.drinkWater]);
    expect(tips.every((t) => t.offline), isTrue);
  });

  test('low recovery means an easy day, not the session', () {
    final tips = offlineTips(numbers(score: 38), languageCode: 'en', day: 'd');
    expect(tips.map((t) => t.title), contains('Take it easy today'));
    expect(tips.map((t) => t.title), isNot(contains('Upper A is on today')));
  });

  test('over the target, no shaming: keep the rest light', () {
    final tips = offlineTips(numbers(kcal: 2500, planned: null, water: 3000), languageCode: 'en', day: 'd');
    expect(tips.single.title, '300 kcal over today');
  });

  test('nothing logged by late morning asks for the first meal', () {
    final tips = offlineTips(numbers(meals: const [], kcal: 0, protein: 0), languageCode: 'en', day: 'd');
    expect(tips.first.title, 'Log your first meal');
  });

  test('in Arabic and Spanish too, and something general when all is on track', () {
    expect(offlineTips(numbers(), languageCode: 'ar', day: 'd').first.title, 'باقي 120 غرام بروتين');
    expect(offlineTips(numbers(), languageCode: 'es', day: 'd').first.title, 'Faltan 120 g de proteína');
    final fine = offlineTips(numbers(protein: 170, water: 3000, planned: null), languageCode: 'en', day: 'd');
    expect(fine.single.title, 'Protein at every meal');
  });
}
