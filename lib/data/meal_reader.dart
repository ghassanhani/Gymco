import '../domain/meal_text.dart';
import 'local_db.dart';
import 'models.dart';

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
  for (final p in parseMealText(text, knownFoodWords: mealAliasWords)) {
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
