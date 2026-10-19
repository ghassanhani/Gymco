import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/food_names.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/data/packs.dart';
import 'package:gymco/data/training.dart';
import 'package:gymco/domain/awards.dart';
import 'package:gymco/domain/meal_text.dart';
import 'package:gymco/domain/streak.dart';

import '../helpers.dart';

Packs pack(String kind, Object body) => Packs.empty.withKind(kind, canonicalJson(body));

AwardStats stats({int fullDays = 0, int workouts = 0, int month = 0}) => AwardStats(
  streak: const StreakState(current: 0, best: 0, freezes: 0, keptTotal: 0, marks: {}),
  fullDays: [for (var i = 0; i < fullDays; i++) DateTime(2026, 9, 1 + i)],
  mealsLogged: 0,
  bestProteinWeek: 0,
  workouts: workouts,
  prs: 0,
  workoutsThisMonth: month,
);

void main() {
  test('the checksum is the lowercase hex SHA-256 of the UTF-8 bytes', () {
    expect(packChecksum('{"a":1}'), '015abd7f5cc57a2dd94b7590f04ad8084273905ee33ec5cebeae62276a97f862');
    expect(packChecksum('{"n":"لبنة"}'), packChecksum(utf8.decode(utf8.encode('{"n":"لبنة"}'))));
  });

  test('pack foods become foods with a pack: id and their own Arabic and Spanish names', () {
    final p = pack('foods', {
      'items': [
        {'id': 'labneh', 'name': t3('Labneh', 'لبنة', 'Labneh (es)'), 'kcal': 160, 'protein': 6, 'carbs': 4, 'fat': 13},
        {'id': 'broken', 'name': 'no'},
      ],
    });
    expect(p.foods.single.id, 'pack:labneh');
    expect(p.foods.single.source, 'pack');
    expect(p.foods.single.name, 'Labneh');
    setPackFoodNames(p.foodNames);
    addTearDown(() => setPackFoodNames(const {}));
    expect(localFoodName('pack:labneh', 'Labneh', 'ar'), 'لبنة');
    expect(foodIdsNamed('لبنه'), contains('pack:labneh'));
    // Built-in staples keep their names.
    expect(localFoodName('usda:banana', 'Banana', 'es'), 'Plátano');
  });

  test('vocabulary adds unit words to the parser, and built-in words win', () {
    final p = pack('vocabulary', {
      'units': [
        {'word': 'scoopie', 'lang': 'en', 'unit': 'scoop'},
        {'word': 'cup', 'lang': 'en', 'unit': 'bowl'},
      ],
    });
    final phrases = parseMealText('2 scoopie whey and 1 cup milk', extraUnits: p.unitWords);
    expect(phrases.first.unit, MealUnit.scoop);
    expect(phrases.first.food, 'whey');
    expect(phrases.last.unit, MealUnit.cup);
    // Without the pack the word is just part of the food.
    expect(parseMealText('2 scoopie whey').first.unit, isNull);
  });

  test('pack exercises join the library; removed ones hide from search but still resolve', () {
    final p = pack('exercises', {
      'items': [
        {
          'id': 'Landmine_Press',
          'name': t3('Landmine Press'),
          'primary': ['shoulders'],
          'secondary': ['triceps'],
          'equipment': 'barbell',
        },
        {
          'id': 'bench',
          'name': t3('Bench Press, renamed'),
          'primary': ['chest'],
          'secondary': <String>[],
        },
      ],
      'removed': ['ohp'],
    });
    final lib = testLibrary.withPack(p.exercises);
    expect(lib.search('landmine').single.id, 'Landmine_Press');
    expect(lib['bench']!.name, 'Bench Press, renamed');
    expect(lib.search('press').map((e) => e.id), isNot(contains('ohp')));
    expect(lib.all.map((e) => e.id), isNot(contains('ohp')));
    expect(lib['ohp']!.name, 'Standing Military Press');
    // The user's own exercises keep the hidden ones hidden.
    final mine = lib.withCustom([
      const Exercise(id: 'custom:1', name: 'Towel row', primary: ['lats'], secondary: [], instructions: [], images: []),
    ]);
    expect(mine.all.map((e) => e.id), isNot(contains('ohp')));
    expect(mine['ohp'], isNotNull);
  });

  test('the month challenge takes its target and title from the pack, 12 otherwise', () {
    final p = pack('challenges', {
      'items': [
        {'month': '2026-09', 'title': t3('September sprint'), 'target': 16},
      ],
    });
    final sept = p.challengeFor(DateTime(2026, 9, 26));
    expect(sept!.target, 16);
    expect(p.challengeFor(DateTime(2026, 10, 1)), isNull);
    final month = awards(
      stats(month: 14),
      monthTarget: sept.target,
      monthTitle: sept.title.toMap(),
    ).firstWhere((a) => a.id == 'month');
    expect(month.need, 16);
    expect(month.earned, isFalse);
    expect(month.names!['en'], 'September sprint');
    expect(awards(stats()).firstWhere((a) => a.id == 'month').need, monthlyChallenge);
  });

  test('pack awards sit with the built-ins and are earned at their threshold', () {
    final p = pack('awards', {
      'items': [
        {
          'id': 'ten_days',
          'name': t3('Ten full days'),
          'description': t3('Logged ten full days.'),
          'metric': 'logged_days',
          'threshold': 10,
        },
        {
          'id': 'five',
          'name': t3('Five sessions'),
          'description': t3('Trained five times.'),
          'metric': 'workouts',
          'threshold': 5,
        },
      ],
    });
    final all = awards(stats(fullDays: 10, workouts: 4), extra: p.awards);
    expect(all.where((a) => a.id == 's7'), hasLength(1));
    final days = all.firstWhere((a) => a.names?['en'] == 'Ten full days');
    expect(days.earned, isTrue);
    expect(days.group, AwardGroup.food);
    expect(days.earnedOn, DateTime(2026, 9, 10));
    final five = all.firstWhere((a) => a.names?['en'] == 'Five sessions');
    expect(five.earned, isFalse);
    expect(five.group, AwardGroup.training);
  });

  test('copy overrides fall back to the built-in for a missing language or key', () {
    final p = pack('copy', {
      'overrides': {
        'welcomeBody': {'en': 'Show up. That is the whole trick.', 'ar': 'احضر فقط.'},
        'notAKey': t3('ignored'),
      },
    });
    expect(p.copy('welcomeBody', 'en', 'built-in'), 'Show up. That is the whole trick.');
    expect(p.copy('welcomeBody', 'es', 'built-in'), 'built-in');
    expect(p.copy('notAKey', 'en', 'built-in'), 'built-in');
    expect(Packs.empty.copy('welcomeBody', 'en', 'built-in'), 'built-in');
  });

  test('a damaged body is the same as no pack', () {
    expect(Packs.empty.withKind('foods', 'not json').foods, isEmpty);
    expect(Packs.empty.withKind('templates', '{"items":"x"}').templates, isEmpty);
  });

  test('templates parse their routines into routine items', () {
    final p = pack('templates', {
      'items': [
        {
          'id': 'glutes',
          'name': t3('Glute focus'),
          'level': 'beginner',
          'routines': [
            {
              'name': t3('Lower A', 'سفلي أ', 'Inferior A'),
              'weekday': 1,
              'items': [
                {'exercise': 'squat', 'sets': 3, 'rep_low': 8, 'rep_high': 12, 'rest_s': 120, 'rir': 1},
              ],
            },
          ],
        },
      ],
    });
    final t = p.templates.single;
    expect(t.routines.single.name.of('es'), 'Inferior A');
    expect(t.routines.single.weekday, 1);
    final i = t.routines.single.items.single;
    expect([i.exerciseId, i.sets, i.repLow, i.repHigh, i.restSeconds, i.rir], ['squat', 3, 8, 12, 120, 1]);
  });

  test('syncing pack foods updates them and drops unpublished ones the user does not point at', () async {
    final db = await openTestDb();
    addTearDown(db.close);
    Food f(String id, double kcal) =>
        Food(id: 'pack:$id', name: id, kcal: kcal, protein: 1, carbs: 1, fat: 1, source: 'pack');
    await db.syncPackFoods([f('labneh', 160), f('zaatar', 300), f('kishk', 350), f('halloumi', 320)]);
    await db.addEntry(LogEntry.of(f('zaatar', 300), day: '2026-09-26', meal: Meal.lunch, grams: 20));
    await db.setFavourite('pack:kishk', true);
    await db.saveMeal('Breakfast', [
      LogEntry.of(f('halloumi', 320), day: '2026-09-26', meal: Meal.breakfast, grams: 50),
    ]);
    await db.syncPackFoods([f('labneh', 170)]);
    expect((await db.foodById('pack:labneh'))!.kcal, 170);
    // Logged only: the diary keeps its own copy, so the food may go.
    expect(await db.foodById('pack:zaatar'), isNull);
    expect((await db.entriesFor('2026-09-26')).single.foodName, 'zaatar');
    // A favourite and a saved meal still point at theirs.
    expect(await db.foodById('pack:kishk'), isNotNull);
    expect(await db.foodById('pack:halloumi'), isNotNull);
    // A pack update keeps the favourite flag.
    await db.syncPackFoods([f('kishk', 360)]);
    expect((await db.foodById('pack:kishk'))!.favourite, isTrue);
    expect(await db.searchFoods('banana'), isNotEmpty);
  });
}
