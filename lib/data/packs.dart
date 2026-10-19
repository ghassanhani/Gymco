/// Content packs: foods, unit words, eating-out dishes, exercises,
/// templates, awards, challenges and copy published from the Control
/// Center. Built-in content always stays; a pack only adds to it or
/// overrides it by id. See docs/superpowers/plans/2026-10-19-content-packs.md.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/awards.dart';
import '../domain/meal_text.dart';
import 'models.dart';
import 'training.dart';

/// Every kind the app understands, in the order it fetches them.
const packKinds = ['foods', 'vocabulary', 'eating_out', 'exercises', 'templates', 'awards', 'challenges', 'copy'];

/// The strings a copy pack may override.
const copyKeys = {
  'emptyDayTitle',
  'emptyDayBody',
  'obWelcomeBody',
  'welcomeBody',
  'welcomeLogBody',
  'welcomeTrainBody',
  'welcomeProgressBody',
  'obTargetsBody',
  'remindMealBody',
  'remindWorkoutBody',
};

/// The lowercase hex SHA-256 of [bodyJson]'s UTF-8 bytes, as the server
/// computes it.
String packChecksum(String bodyJson) => sha256.convert(utf8.encode(bodyJson)).toString();

/// A text in English, Arabic and Spanish. Publishing needs all three; the
/// phone copes with one missing.
class T3 {
  const T3(this._by);
  final Map<String, String> _by;

  static T3? parse(Object? j) {
    if (j is! Map) return null;
    final by = {
      for (final l in const ['en', 'ar', 'es'])
        if (j[l] case final String s when s.trim().isNotEmpty) l: s.trim(),
    };
    return by.isEmpty ? null : T3(by);
  }

  /// The text in [lang] when the pack has it.
  String? maybe(String lang) => _by[lang];

  /// The text in [lang], else English, else whatever there is.
  String of(String lang) => _by[lang] ?? _by['en'] ?? _by.values.first;

  String get en => of('en');

  Map<String, String> toMap() => Map.unmodifiable(_by);
}

/// A restaurant dish at a normal portion, from the eating-out pack.
class PackDish {
  const PackDish({
    required this.id,
    required this.main,
    required this.name,
    required this.g,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
  });
  final String id;

  /// A main dish, or a side.
  final bool main;
  final T3 name;
  final double g, kcal, p, c, f;
}

/// One routine of a pack template.
class PackRoutine {
  const PackRoutine({required this.name, required this.weekday, required this.items});
  final T3 name;

  /// 0 = Monday … 6 = Sunday, as the app counts them.
  final int weekday;
  final List<RoutineItem> items;
}

/// A starter block from the templates pack.
class PackTemplate {
  const PackTemplate({required this.id, required this.name, required this.routines, this.level});
  final String id;
  final T3 name;

  /// beginner, intermediate or expert.
  final String? level;
  final List<PackRoutine> routines;
}

/// One month's challenge.
class PackChallenge {
  const PackChallenge({required this.month, required this.title, required this.target});

  /// "YYYY-MM".
  final String month;
  final T3 title;
  final int target;
}

/// Everything the published packs add, parsed. Each kind defaults to empty,
/// and a body that cannot be read is the same as none.
class Packs {
  const Packs._({
    this.foods = const [],
    this.unitWords = const {},
    this.dishes = const [],
    this.exercises = ExercisePack.empty,
    this.templates = const [],
    this.awards = const [],
    this.challenges = const {},
    this.copyOverrides = const {},
    this.foodTexts = const {},
    this.dishTexts = const {},
  });

  static const empty = Packs._();

  /// The packs the domain and data code read. Set when they load or change.
  static Packs current = empty;

  /// Foods per 100 g, with ids `pack:<id>` and source `pack`.
  final List<Food> foods;

  /// Extra unit words for the Write parser, keyed as [normaliseMealText]
  /// writes them.
  final Map<String, MealUnit> unitWords;

  /// Extra eating-out dishes, mains and sides.
  final List<PackDish> dishes;
  final ExercisePack exercises;
  final List<PackTemplate> templates;
  final List<ExtraAward> awards;

  /// By month, "YYYY-MM".
  final Map<String, PackChallenge> challenges;
  final Map<String, T3> copyOverrides;

  /// Names of pack foods and dishes, by food id.
  final Map<String, T3> foodTexts;
  final Map<String, T3> dishTexts;

  /// Arabic and Spanish names of pack foods and dishes, by food id.
  Map<String, (String, String)> get foodNames => {
    for (final MapEntry(:key, :value) in {...foodTexts, ...dishTexts}.entries) key: (value.of('ar'), value.of('es')),
  };

  /// [month]'s challenge, when the pack has one.
  PackChallenge? challengeFor(DateTime month) =>
      challenges['${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}'];

  /// The copy override for [key] in [lang], or [builtIn].
  String copy(String key, String lang, String builtIn) =>
      (copyKeys.contains(key) ? copyOverrides[key]?.maybe(lang) : null) ?? builtIn;

  /// These packs with [kind]'s body replaced by [bodyJson], or dropped when null.
  Packs withKind(String kind, String? bodyJson) {
    Map<String, Object?> body = const {};
    if (bodyJson != null) {
      try {
        if (jsonDecode(bodyJson) case final Map m) body = m.cast<String, Object?>();
      } on FormatException {
        // A damaged body is the same as none.
      }
    }
    return switch (kind) {
      'foods' => _foods(body),
      'vocabulary' => _copy(unitWords: _vocabulary(body)),
      'eating_out' => _eatingOut(body),
      'exercises' => _copy(exercises: _exercises(body)),
      'templates' => _copy(templates: _templates(body)),
      'awards' => _copy(awards: _awards(body)),
      'challenges' => _copy(challenges: _challenges(body)),
      'copy' => _copy(copyOverrides: _overrides(body)),
      _ => this,
    };
  }

  Packs _copy({
    List<Food>? foods,
    Map<String, MealUnit>? unitWords,
    List<PackDish>? dishes,
    ExercisePack? exercises,
    List<PackTemplate>? templates,
    List<ExtraAward>? awards,
    Map<String, PackChallenge>? challenges,
    Map<String, T3>? copyOverrides,
    Map<String, T3>? foodTexts,
    Map<String, T3>? dishTexts,
  }) => Packs._(
    foods: foods ?? this.foods,
    unitWords: unitWords ?? this.unitWords,
    dishes: dishes ?? this.dishes,
    exercises: exercises ?? this.exercises,
    templates: templates ?? this.templates,
    awards: awards ?? this.awards,
    challenges: challenges ?? this.challenges,
    copyOverrides: copyOverrides ?? this.copyOverrides,
    foodTexts: foodTexts ?? this.foodTexts,
    dishTexts: dishTexts ?? this.dishTexts,
  );

  Packs _foods(Map<String, Object?> body) {
    final foods = <Food>[];
    final texts = <String, T3>{};
    for (final j in _list(body['items'])) {
      final (id, name) = (_id(j['id']), T3.parse(j['name']));
      final (kcal, p, c, f) = (
        _num(j['kcal'], 900),
        _num(j['protein'], 100),
        _num(j['carbs'], 100),
        _num(j['fat'], 100),
      );
      if (id == null || name == null || kcal == null || p == null || c == null || f == null) continue;
      final food = Food(
        id: 'pack:$id',
        name: name.en,
        kcal: kcal,
        protein: p,
        carbs: c,
        fat: f,
        servingGrams: _num(j['serving_g'], 2000, min: 1),
        source: 'pack',
      );
      foods.add(food);
      texts[food.id] = name;
    }
    return _copy(foods: foods, foodTexts: texts);
  }

  static Map<String, MealUnit> _vocabulary(Map<String, Object?> body) => {
    for (final j in _list(body['units']))
      if ((j['word'], MealUnit.values.asNameMap()[j['unit']]) case (final String w, final MealUnit u))
        if (normaliseMealText(w).trim() case final k when k.isNotEmpty && !k.contains(' ') && !isBuiltInMealWord(k))
          k: u,
  };

  Packs _eatingOut(Map<String, Object?> body) {
    final dishes = <PackDish>[];
    final texts = <String, T3>{};
    for (final j in _list(body['dishes'])) {
      final (id, name, group) = (_id(j['id']), T3.parse(j['name']), j['group']);
      final (g, kcal) = (_num(j['g'], 2000, min: 1), _num(j['kcal'], 3000));
      final (p, c, f) = (_num(j['p'], 300), _num(j['c'], 300), _num(j['f'], 300));
      if (id == null || name == null || (group != 'main' && group != 'side')) continue;
      if (g == null || kcal == null || p == null || c == null || f == null) continue;
      dishes.add(PackDish(id: id, main: group == 'main', name: name, g: g, kcal: kcal, p: p, c: c, f: f));
      texts['eatout:$id'] = name;
    }
    return _copy(dishes: dishes, dishTexts: texts);
  }

  static ExercisePack _exercises(Map<String, Object?> body) {
    List<String> strings(Object? v) => [for (final s in v is List ? v : const []) ?(s is String ? s : null)];
    final items = <Exercise>[];
    for (final j in _list(body['items'])) {
      final (id, name, primary) = (j['id'], T3.parse(j['name']), strings(j['primary']));
      if (id is! String || id.isEmpty || name == null || primary.isEmpty) continue;
      items.add(
        Exercise(
          id: id,
          name: name.en,
          primary: primary,
          secondary: strings(j['secondary']),
          equipment: j['equipment'] is String ? j['equipment'] as String : null,
          level: j['level'] is String ? j['level'] as String : null,
          category: 'strength',
          images: strings(j['images']),
          instructions: strings(j['instructions']),
        ),
      );
    }
    return ExercisePack(items: items, removed: strings(body['removed']).toSet());
  }

  static List<PackTemplate> _templates(Map<String, Object?> body) {
    final out = <PackTemplate>[];
    for (final j in _list(body['items'])) {
      final (id, name) = (_id(j['id']), T3.parse(j['name']));
      if (id == null || name == null) continue;
      final routines = <PackRoutine>[];
      for (final r in _list(j['routines'])) {
        final (rname, day) = (T3.parse(r['name']), _int(r['weekday'], 0, 6));
        if (rname == null || day == null) continue;
        final items = <RoutineItem>[];
        for (final i in _list(r['items'])) {
          final ex = i['exercise'];
          final (sets, lo) = (_int(i['sets'], 1, 10), _int(i['rep_low'], 1, 50));
          final (hi, rest) = (_int(i['rep_high'], lo ?? 1, 50), _int(i['rest_s'], 0, 600));
          if (ex is! String || ex.isEmpty || sets == null || lo == null || hi == null || rest == null) continue;
          items.add(
            RoutineItem(
              exerciseId: ex,
              sets: sets,
              repLow: lo,
              repHigh: hi,
              restSeconds: rest,
              rir: _int(i['rir'], 0, 5) ?? 2,
            ),
          );
        }
        if (items.isNotEmpty) routines.add(PackRoutine(name: rname, weekday: day, items: items));
      }
      if (routines.isEmpty) continue;
      out.add(
        PackTemplate(id: id, name: name, level: j['level'] is String ? j['level'] as String : null, routines: routines),
      );
    }
    return out;
  }

  static List<ExtraAward> _awards(Map<String, Object?> body) => [
    for (final j in _list(body['items']))
      if ((
            _id(j['id']),
            T3.parse(j['name']),
            T3.parse(j['description']),
            _int(j['threshold'], 1, 1000),
            switch (j['metric']) {
              'logged_days' => AwardMetric.loggedDays,
              'workouts' => AwardMetric.workouts,
              'streak_days' => AwardMetric.streakDays,
              _ => null,
            },
          )
          case (final String id, final T3 name, final T3 desc, final int n, final AwardMetric m))
        ExtraAward(id: id, metric: m, threshold: n, names: name.toMap(), descriptions: desc.toMap()),
  ];

  static Map<String, PackChallenge> _challenges(Map<String, Object?> body) => {
    for (final j in _list(body['items']))
      if ((j['month'], T3.parse(j['title']), _int(j['target'], 4, 31))
          case (final String m, final T3 title, final int target) when RegExp(r'^\d{4}-\d{2}$').hasMatch(m))
        m: PackChallenge(month: m, title: title, target: target),
  };

  static Map<String, T3> _overrides(Map<String, Object?> body) => {
    if (body['overrides'] case final Map o)
      for (final MapEntry(:key, :value) in o.entries)
        if (key is String && copyKeys.contains(key)) key: ?T3.parse(value),
  };
}

final _idPattern = RegExp(r'^[a-z0-9_]{1,40}$');

String? _id(Object? v) => v is String && _idPattern.hasMatch(v) ? v : null;

Iterable<Map<String, Object?>> _list(Object? v) => [
  for (final x in v is List ? v.take(500) : const []) ?(x is Map ? x.cast<String, Object?>() : null),
];

double? _num(Object? v, num max, {num min = 0}) => v is num && v.isFinite && v >= min && v <= max ? v.toDouble() : null;

int? _int(Object? v, int min, int max) => v is num && v == v.roundToDouble() && v >= min && v <= max ? v.toInt() : null;
