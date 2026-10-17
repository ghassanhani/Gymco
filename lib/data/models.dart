import '../domain/energy.dart';

enum Meal { breakfast, lunch, dinner, snack }

/// A food, per 100 g. Every read in the app comes from the local copy, so
/// logging works with no signal.
class Food {
  const Food({
    required this.id,
    required this.name,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.brand,
    this.barcode,
    this.servingGrams,
    this.source = 'local',
    this.favourite = false,
  });

  final String id;
  final String name;
  final String? brand;
  final String? barcode;

  /// Per 100 g.
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  /// A typical serving, when the source gives one.
  final double? servingGrams;

  /// 'local' (made by the user), 'usda' or 'off'.
  final String source;

  final bool favourite;

  /// Generic foods from USDA carry the blue check; packs from Open Food
  /// Facts are crowd-sourced.
  bool get verified => source == 'usda';

  /// Ways to measure it: grams first, then one serving when the source gives one.
  /// Each is (grams per unit, label grams).
  List<(double, double?)> get units => [(1, null), if (servingGrams != null) (servingGrams!, servingGrams)];

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'brand': brand,
    'barcode': barcode,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'serving_g': servingGrams,
    'source': source,
  };

  factory Food.fromRow(Map<String, Object?> r) => Food(
    id: r['id']! as String,
    name: r['name']! as String,
    brand: r['brand'] as String?,
    barcode: r['barcode'] as String?,
    kcal: (r['kcal']! as num).toDouble(),
    protein: (r['protein']! as num).toDouble(),
    carbs: (r['carbs']! as num).toDouble(),
    fat: (r['fat']! as num).toDouble(),
    servingGrams: (r['serving_g'] as num?)?.toDouble(),
    source: r['source']! as String,
    favourite: (r['favourite'] as int? ?? 0) == 1,
  );
}

/// A meal the user saved to log again in one tap.
class SavedMeal {
  const SavedMeal({required this.id, required this.name, required this.items});
  final int id;
  final String name;

  /// Each food with its grams.
  final List<(Food, double)> items;

  double get kcal => items.fold(0, (s, i) => s + i.$1.kcal * i.$2 / 100);
}

/// One food logged into one meal. Nutrition is snapshotted at log time so a
/// later edit to the food never rewrites history.
class LogEntry {
  const LogEntry({
    required this.id,
    required this.day,
    required this.meal,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.loggedAt,
  });

  final int? id;

  /// When it was logged; null before it is saved.
  final DateTime? loggedAt;

  /// yyyy-MM-dd, local time.
  final String day;
  final Meal meal;
  final String foodId;
  final String foodName;
  final double grams;
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;

  factory LogEntry.of(Food f, {required String day, required Meal meal, required double grams}) {
    final k = grams / 100;
    return LogEntry(
      id: null,
      day: day,
      meal: meal,
      foodId: f.id,
      foodName: f.name,
      grams: grams,
      kcal: f.kcal * k,
      protein: f.protein * k,
      carbs: f.carbs * k,
      fat: f.fat * k,
    );
  }

  Macros get macros => Macros(protein: protein, carbs: carbs, fat: fat);

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'day': day,
    'meal': meal.name,
    'food_id': foodId,
    'food_name': foodName,
    'grams': grams,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory LogEntry.fromRow(Map<String, Object?> r) => LogEntry(
    id: r['id']! as int,
    day: r['day']! as String,
    meal: Meal.values.byName(r['meal']! as String),
    foodId: r['food_id']! as String,
    foodName: r['food_name']! as String,
    grams: (r['grams']! as num).toDouble(),
    kcal: (r['kcal']! as num).toDouble(),
    protein: (r['protein']! as num).toDouble(),
    carbs: (r['carbs']! as num).toDouble(),
    fat: (r['fat']! as num).toDouble(),
    loggedAt: r['created_at'] == null ? null : DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
  );
}

/// What onboarding sets up. Stored on the phone.
class Profile {
  const Profile({
    required this.goal,
    required this.sex,
    required this.ageYears,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.ratePctPerWeek,
    required this.targetKcal,
    required this.targets,
    required this.startedOn,
  });

  final Goal goal;
  final Sex sex;
  final int ageYears;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;

  /// Signed: negative loses.
  final double ratePctPerWeek;
  final double targetKcal;
  final Macros targets;
  final DateTime startedOn;

  Map<String, Object?> toJson() => {
    'goal': goal.name,
    'sex': sex.name,
    'age': ageYears,
    'height': heightCm,
    'weight': weightKg,
    'activity': activity.name,
    'rate': ratePctPerWeek,
    'kcal': targetKcal,
    'p': targets.protein,
    'c': targets.carbs,
    'f': targets.fat,
    'started': startedOn.toIso8601String(),
  };

  factory Profile.fromJson(Map<String, Object?> j) => Profile(
    goal: Goal.values.byName(j['goal']! as String),
    sex: Sex.values.byName(j['sex']! as String),
    ageYears: j['age']! as int,
    heightCm: (j['height']! as num).toDouble(),
    weightKg: (j['weight']! as num).toDouble(),
    activity: ActivityLevel.values.byName(j['activity']! as String),
    ratePctPerWeek: (j['rate']! as num).toDouble(),
    targetKcal: (j['kcal']! as num).toDouble(),
    targets: Macros(
      protein: (j['p']! as num).toDouble(),
      carbs: (j['c']! as num).toDouble(),
      fat: (j['f']! as num).toDouble(),
    ),
    startedOn: DateTime.parse(j['started']! as String),
  );
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
