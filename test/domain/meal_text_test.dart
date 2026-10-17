import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/meal_text.dart';

List<MealPhrase> parse(String s) => parseMealText(s, knownFoodWords: mealAliasWords);

void main() {
  test('reads grams, counts and units from the prototype examples', () {
    final a = parse('200g chicken breast, 150g rice and 10g olive oil');
    expect([for (final p in a) (p.food, p.grams)], [('chicken breast', 200), ('rice', 150), ('olive oil', 10)]);

    final b = parse('2 eggs with two slices of bread');
    expect(b, hasLength(2));
    expect((b[0].food, b[0].count, b[0].unit), ('eggs', 2, null));
    expect((b[1].food, b[1].count, b[1].unit), ('bread', 2, MealUnit.slice));

    final c = parse('a scoop of whey').single;
    expect((c.food, c.count, c.unit), ('whey', 1, MealUnit.scoop));
  });

  test('no amount written means assumed', () {
    final p = parse('banana').single;
    expect(p.assumed, isTrue);
    expect(parse('1 banana').single.assumed, isFalse);
  });

  test('weights in other units, decimals and fractions', () {
    expect(parse('1,5 kg potatoes').single.grams, 1500);
    expect(parse('1.5kg potatoes').single.grams, 1500);
    expect(parse('8 oz salmon').single.grams, closeTo(226.8, 0.01));
    expect(parse('250 ml milk').single.grams, 250);
    final half = parse('half a cup of oats').single;
    expect((half.count, half.unit, half.food), (0.5, MealUnit.cup, 'oats'));
    expect(parse('1/2 avocado').single.count, 0.5);
  });

  test('new lines and sentence marks split too, a decimal point does not', () {
    final a = parse('2 eggs\n100g oats. 0.5 banana');
    expect([for (final p in a) p.food], ['eggs', 'oats', 'banana']);
    expect(a.last.count, 0.5);
  });

  test('Spanish', () {
    final a = parse('200g de pollo, 150 g de arroz y una cucharada de aceite de oliva');
    expect([for (final p in a) p.food], ['pollo', 'arroz', 'aceite oliva']);
    expect(a[2].count, 1);
    expect(a[2].unit, MealUnit.tbsp);
    expect(aliasFoodId(a[0].food), 'usda:chicken-breast-raw');
    expect(aliasFoodId(a[2].food), 'usda:olive-oil');
    expect(parse('dos huevos con pan').map((p) => aliasFoodId(p.food)), ['usda:egg-whole-raw', 'usda:bread-white']);
  });

  test('Arabic, with Arabic digits, an attached "and" and a dual', () {
    final a = parse('٢٠٠ غرام دجاج و١٥٠غ رز وملعقة زيت زيتون');
    expect(
      [for (final p in a) aliasFoodId(p.food)],
      ['usda:chicken-breast-raw', 'usda:rice-white-cooked', 'usda:olive-oil'],
    );
    expect([a[0].grams, a[1].grams], [200, 150]);
    expect((a[2].count, a[2].unit), (1, MealUnit.tbsp));

    final b = parse('بيضتين مع خبز ورز');
    expect(
      [for (final p in b) aliasFoodId(p.food)],
      ['usda:egg-whole-raw', 'usda:pita-white', 'usda:rice-white-cooked'],
    );
    expect(b[0].count, 2);
  });

  test('the longest alias wins: egg whites are not eggs, sweet potato is not potato', () {
    expect(aliasFoodId('egg whites'), 'usda:egg-white-raw');
    expect(aliasFoodId('sweet potato'), 'usda:sweet-potato-baked');
    expect(aliasFoodId('potatoes'), 'usda:potato-boiled');
    expect(aliasFoodId('dates'), 'usda:dates-medjool');
    expect(aliasFoodId('البيض'), 'usda:egg-whole-raw');
    expect(aliasFoodId('quinoa'), isNull);
  });

  test('grams from counts use the food: eggs, slices, a scoop, a cup', () {
    double g(String s, String id, [double? serving]) =>
        mealPhraseGrams(parse(s).single, foodId: id, servingGrams: serving);
    expect(g('2 eggs', 'usda:egg-whole-raw', 50), 100);
    expect(g('two slices of bread', 'usda:bread-white', 30), 60);
    expect(g('a scoop of whey', 'usda:whey-protein', 30), 30);
    expect(g('a cup of rice', 'usda:rice-white-cooked', 150), 158);
    expect(g('a tbsp olive oil', 'usda:olive-oil', 14), 13.5);
    expect(g('rice', 'usda:rice-white-cooked', 150), 150);
    expect(g('2 chicken', 'usda:chicken-breast-raw', 170), 340);
  });
}
