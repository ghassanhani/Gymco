import 'package:openfoodfacts/openfoodfacts.dart';

import 'models.dart';

/// Looks foods up online. Results are always written back to the local
/// database by the caller, so the network only ever adds to what the phone
/// already knows.
abstract class FoodSource {
  Future<Food?> byBarcode(String barcode, {required String languageCode});
  Future<List<Food>> search(String query, {required String languageCode});
}

// The typed `nutriments` model and API v3 are deprecated in favour of an
// untyped `nutrition` map; they still work and are clearer, so we keep them
// until the package ships a typed replacement.
// ignore_for_file: deprecated_member_use

/// Open Food Facts: free and open, strong coverage in Europe and growing in
/// the Gulf.
class OpenFoodFactsSource implements FoodSource {
  OpenFoodFactsSource() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'Gymco', url: 'https://github.com/ghassanhani/Gymco');
  }

  static const _fields = [
    ProductField.BARCODE,
    ProductField.NAME,
    ProductField.BRANDS,
    ProductField.NUTRIMENTS,
    ProductField.SERVING_QUANTITY,
  ];

  static OpenFoodFactsLanguage _lang(String code) => switch (code) {
    'ar' => OpenFoodFactsLanguage.ARABIC,
    'es' => OpenFoodFactsLanguage.SPANISH,
    _ => OpenFoodFactsLanguage.ENGLISH,
  };

  @override
  Future<Food?> byBarcode(String barcode, {required String languageCode}) async {
    final result = await OpenFoodAPIClient.getProductV3(
      ProductQueryConfiguration(
        barcode,
        language: _lang(languageCode),
        fields: _fields,
        version: ProductQueryVersion.v3,
      ),
    );
    final p = result.product;
    return p == null ? null : toFood(p);
  }

  @override
  Future<List<Food>> search(String query, {required String languageCode}) async {
    final result = await OpenFoodAPIClient.searchProducts(
      null,
      ProductSearchQueryConfiguration(
        language: _lang(languageCode),
        fields: _fields,
        parametersList: [
          SearchTerms(terms: [query]),
          const PageSize(size: 25),
        ],
        version: ProductQueryVersion.v3,
      ),
    );
    return [for (final p in result.products ?? const <Product>[]) ?toFood(p)];
  }

  /// A product becomes a food only when it has per-100 g energy.
  static Food? toFood(Product p) {
    final n = p.nutriments;
    final name = p.productName?.trim();
    if (n == null || name == null || name.isEmpty || p.barcode == null) return null;
    double? v(Nutrient x) => n.getValue(x, PerSize.oneHundredGrams);
    final kcal = v(Nutrient.energyKCal);
    if (kcal == null) return null;
    return Food(
      id: 'off:${p.barcode}',
      name: name,
      brand: p.brands?.split(',').first.trim(),
      barcode: p.barcode,
      kcal: kcal,
      protein: v(Nutrient.proteins) ?? 0,
      carbs: v(Nutrient.carbohydrates) ?? 0,
      fat: v(Nutrient.fat) ?? 0,
      servingGrams: p.servingQuantity,
      source: 'off',
    );
  }
}

/// Where a missed barcode can be added in the browser.
Uri openFoodFactsAddUrl(String barcode) =>
    Uri.parse('https://world.openfoodfacts.org/cgi/product.pl?type=add&code=$barcode');
