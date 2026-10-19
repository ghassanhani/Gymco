import '../domain/meal_text.dart';
import 'cloud.dart' show PhotoFood;
import 'local_db.dart';
import 'models.dart';
import 'packs.dart';

/// A written food matched to the database, or not, with its weight.
class WrittenItem {
  const WrittenItem({required this.phrase, required this.food, required this.grams});
  final MealPhrase phrase;

  /// Null when nothing on the phone matches: "Not in the database yet".
  final Food? food;
  final double grams;

  bool get assumed => phrase.assumed;
  double get kcal => (food?.kcal ?? 0) * grams / 100;
  double get protein => (food?.protein ?? 0) * grams / 100;
  double get carbs => (food?.carbs ?? 0) * grams / 100;
  double get fat => (food?.fat ?? 0) * grams / 100;

  WrittenItem withGrams(double g) => WrittenItem(phrase: phrase, food: food, grams: g);
}

/// Reads a written meal against the foods on the phone: the staples by name
/// in any of the three languages, then whatever search finds, dropping
/// trailing words until something does ("chicken breast grilled" → "chicken breast").
Future<List<WrittenItem>> readWrittenMeal(LocalDb db, String text) async {
  final out = <WrittenItem>[];
  for (final p in parseMealText(text, knownFoodWords: mealAliasWords, extraUnits: Packs.current.unitWords)) {
    Food? food;
    if (aliasFoodId(p.food) case final id?) food = await db.foodById(id);
    if (food == null) {
      final words = p.food.split(' ');
      for (var n = words.length; n > 0 && food == null; n--) {
        final q = words.take(n).join(' ');
        if (q.length >= 3) food = (await db.searchFoods(q, limit: 1)).firstOrNull;
      }
    }
    out.add(
      WrittenItem(
        phrase: p,
        food: food,
        grams: food == null ? 0 : mealPhraseGrams(p, foodId: food.id, servingGrams: food.servingGrams),
      ),
    );
  }
  return out;
}

/// A food the model named, as something the phone can log: the database's
/// own entry when there is one, so its figures win; otherwise the model's
/// estimate, kept as an "estimated" food. Null when neither exists.
Future<Food?> resolveEstimate(LocalDb db, PhotoFood f) async {
  final found = (await readWrittenMeal(db, f.name)).firstOrNull?.food;
  // Only the same food: the reader drops words until something matches, and
  // "chicken biryani" is not chicken breast.
  final words = f.name.toLowerCase().split(RegExp(r'[^a-z]+')).where((w) => w.length > 2);
  if (found != null && words.every(found.name.toLowerCase().contains)) return found;
  if (!f.hasNutrition) return null;
  final slug = f.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  final food = Food(
    id: 'ai:${slug.isEmpty ? f.local.hashCode : slug}',
    name: f.local.isEmpty ? f.name : f.local,
    kcal: f.kcal!,
    protein: f.protein!,
    carbs: f.carbs!,
    fat: f.fat!,
    servingGrams: f.grams,
    source: 'ai',
  );
  await db.upsertFoods([food]);
  return food;
}
