import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/food_names.dart';

import '../helpers.dart';

void main() {
  test('staples have Arabic and Spanish names; others keep theirs', () {
    expect(localFoodName('usda:banana', 'Banana', 'es'), 'Plátano');
    expect(localFoodName('usda:banana', 'Banana', 'ar'), 'موز');
    expect(localFoodName('usda:banana', 'Banana', 'en'), 'Banana');
    expect(localFoodName('off:123', 'Skyr', 'es'), 'Skyr');
  });

  test('search finds staples by their local names, accents optional', () async {
    final db = await openTestDb();
    expect((await db.searchFoods('platano')).map((f) => f.id), contains('usda:banana'));
    expect((await db.searchFoods('pechuga pollo')).map((f) => f.id), contains('usda:chicken-breast-raw'));
    expect(
      (await db.searchFoods('أرز')).map((f) => f.id),
      containsAll(['usda:rice-white-cooked', 'usda:rice-basmati-cooked']),
    );
    expect((await db.searchFoods('banana')).map((f) => f.id), contains('usda:banana'));
  });
}
