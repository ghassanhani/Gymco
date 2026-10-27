import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/coach.dart';
import 'package:gymco/domain/energy.dart';
import 'package:gymco/domain/routine_ai.dart';

import '../helpers.dart';

IronProgram _p(double kcal, {double protein = 180, double fat = 70}) => IronProgram(
  summary: '',
  kcal: kcal,
  macros: Macros(protein: protein, carbs: 200, fat: fat),
  why: '',
  plan: const AiPlan(routines: [], summary: ''),
  habits: const [],
);

void main() {
  test('targets keep to the floor and move at most the weekly step', () {
    final (kcal, m, held) = safeTargets(current: 2300, p: _p(1500), floor: 1700, maxChange: 120, weightKg: 80);
    expect(kcal, 2180);
    expect(held, isTrue);
    // Carbs take what protein and fat leave.
    expect(m.protein * 4 + m.carbs * 4 + m.fat * 9, closeTo(kcal, 4));
  });

  test('a target within the step is used as it is', () {
    final (kcal, m, held) = safeTargets(current: 2300, p: _p(2250), floor: 1700, maxChange: 120, weightKg: 80);
    expect((kcal, held), (2250, false));
    expect(m.protein, 180);
  });

  test('protein is capped at 2.5 g per kg', () {
    final (_, m, _) = safeTargets(current: 2300, p: _p(2300, protein: 400), floor: 1700, maxChange: 120, weightKg: 80);
    expect(m.protein, 200);
  });

  test('a program reads its targets, routines and habits', () {
    final p = programFrom({
      'summary': 'Lean bulk.',
      'kcal': 2650,
      'protein': 170,
      'carbs': 320,
      'fat': 75,
      'why': 'Your trend is flat.',
      'routines': [
        {
          'name': 'Push',
          'days': [0],
          'items': [
            {'exercise': 'Barbell Bench Press', 'sets': 4, 'rep_low': 6, 'rep_high': 8, 'rest_seconds': 150},
          ],
        },
      ],
      'habits': ['Protein at every meal', 'Walk 8k steps', 'Sleep 8 hours', 'A fourth one'],
    }, testLibrary);
    expect(p.kcal, 2650);
    expect(p.plan.routines.single.items.single.exerciseId, 'bench');
    expect(p.habits, hasLength(3));
  });

  test('a program whose training week leaked into its "why" is put back together', () {
    final p = programFrom({
      'summary': 'Hold the cut.',
      'kcal': 2095,
      'protein': 186,
      'carbs': 207,
      'fat': 58,
      'why':
          'السعرات من هدفك الحالي.</why>\n<parameter name="routines">[{"name":"الجزء العلوي A","days":[0],'
          '"items":[{"exercise":"Barbell Bench Press","sets":4,"rep_low":6,"rep_high":8,"rest_seconds":150}]}]'
          '</parameter>',
      'routines': <Object?>[],
      'habits': ['Walk 8k steps'],
    }, testLibrary);
    expect(p.why, 'السعرات من هدفك الحالي.');
    expect(p.plan.routines.single.name, 'الجزء العلوي A');
    expect(p.plan.routines.single.items.single.exerciseId, 'bench');
    expect(cleanText('Fine sentence.'), 'Fine sentence.');
    expect(cleanText('Cut here {"exercise":"x"}'), 'Cut here');
  });

  test("a tip keeps for its day, with the action it asks for", () {
    final t = IronTip.fromJson({
      'title': 'Protein first',
      'tip': 'You are 60 g short.',
      'action': 'log_food',
    }, '2026-09-26')!;
    final back = IronTip.stored(t.toJson())!;
    expect((back.day, back.title, back.action), ('2026-09-26', 'Protein first', IronAction.logFood));
    expect(IronTip.fromJson({'title': '', 'tip': 'x'}, 'd'), isNull);
  });
}
