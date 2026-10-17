import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/data/seed_foods.dart';

import '../helpers.dart';

void main() {
  test('ships with staples so search works offline on first launch', () async {
    final db = await openTestDb();
    final r = await db.searchFoods('chicken');
    expect(r.map((f) => f.id), contains('usda:chicken-breast-raw'));
    expect(await db.searchFoods('rice cooked'), hasLength(2));
  });

  test('logging snapshots nutrition and marks the food recent', () async {
    final db = await openTestDb();
    final chicken = seedFoods.first;
    await db.addEntry(LogEntry.of(chicken, day: '2026-09-26', meal: Meal.lunch, grams: 200));
    final e = (await db.entriesFor('2026-09-26')).single;
    expect(e.kcal, closeTo(240, 1e-9));
    expect(e.protein, closeTo(45, 1e-9));
    expect((await db.recentFoods()).first.id, chicken.id);
  });

  test('online foods are kept for offline search and barcode lookup', () async {
    final db = await openTestDb();
    const skyr = Food(
      id: 'off:123',
      name: 'Skyr natural',
      barcode: '123',
      kcal: 63,
      protein: 11,
      carbs: 4,
      fat: 0.2,
      source: 'off',
    );
    await db.upsertFoods([skyr]);
    expect((await db.foodByBarcode('123'))?.name, 'Skyr natural');
    expect((await db.searchFoods('skyr')).single.id, 'off:123');
  });

  test('repeat yesterday copies one meal', () async {
    final db = await openTestDb();
    for (final f in seedFoods.take(3)) {
      await db.addEntry(LogEntry.of(f, day: '2026-09-25', meal: Meal.breakfast, grams: 100));
    }
    await db.addEntry(LogEntry.of(seedFoods[5], day: '2026-09-25', meal: Meal.dinner, grams: 100));
    final n = await db.repeatMeal(from: '2026-09-25', to: '2026-09-26', meal: Meal.breakfast);
    expect(n, 3);
    final today = await db.entriesFor('2026-09-26');
    expect(today.every((e) => e.meal == Meal.breakfast), isTrue);
  });
}
