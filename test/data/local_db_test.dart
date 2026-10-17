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

  test('a saved meal keeps its foods and grams, in order', () async {
    final db = await openTestDb();
    final oats = seedFoods.firstWhere((f) => f.id == 'usda:oats-rolled');
    final berries = seedFoods.firstWhere((f) => f.id == 'usda:blueberries');
    final entries = [
      LogEntry.of(oats, day: '2026-09-26', meal: Meal.breakfast, grams: 80),
      LogEntry.of(berries, day: '2026-09-26', meal: Meal.breakfast, grams: 75),
    ];
    await db.saveMeal('Oats and berries', entries);
    final m = (await db.savedMeals()).single;
    expect(m.name, 'Oats and berries');
    expect(m.items.map((i) => (i.$1.id, i.$2)), [(oats.id, 80.0), (berries.id, 75.0)]);
    expect(m.kcal, closeTo(oats.kcal * 0.8 + berries.kcal * 0.75, 1e-9));
  });

  test('favourites come first in recent, and a custom copy is the user\'s own', () async {
    final db = await openTestDb();
    final oats = seedFoods.firstWhere((f) => f.id == 'usda:oats-rolled');
    await db.addEntry(LogEntry.of(seedFoods.first, day: '2026-09-26', meal: Meal.lunch, grams: 100));
    await db.setFavourite(oats.id, true);
    expect((await db.recentFoods()).first.id, oats.id);

    final copy = await db.saveAsCustom(oats);
    expect(copy.source, 'local');
    expect((await db.customFoods()).single.kcal, oats.kcal);
  });

  test('wipe removes everything the user made and keeps the bundled foods', () async {
    final db = await openTestDb();
    final oats = seedFoods.firstWhere((f) => f.id == 'usda:oats-rolled');
    await db.addEntry(LogEntry.of(oats, day: '2026-09-26', meal: Meal.breakfast, grams: 80));
    await db.setWeight('2026-09-26', 80);
    await db.saveAsCustom(oats);
    await db.setFavourite(oats.id, true);
    await db.wipe();
    expect(await db.entriesFor('2026-09-26'), isEmpty);
    expect(await db.weighIns(), isEmpty);
    expect(await db.customFoods(), isEmpty);
    expect(await db.recentFoods(), isEmpty);
    expect(await db.searchFoods('oats'), isNotEmpty);
    final c = await db.counts();
    expect((c.entries, c.sets, c.weighIns), (0, 0, 0));
  });
}
