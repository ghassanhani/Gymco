/// The staples' names in Arabic and Spanish, by food id. Foods from the
/// internet, custom foods and recipes keep the name they came with.
const _names = <String, (String ar, String es)>{
  'usda:chicken-breast-raw': ('صدر دجاج، نيء', 'Pechuga de pollo, cruda'),
  'usda:rice-white-cooked': ('أرز أبيض، مطبوخ', 'Arroz blanco, cocido'),
  'usda:rice-basmati-cooked': ('أرز بسمتي، مطبوخ', 'Arroz basmati, cocido'),
  'usda:oats-rolled': ('شوفان', 'Copos de avena'),
  'usda:egg-whole-raw': ('بيض كامل', 'Huevo entero'),
  'usda:egg-white-raw': ('بياض البيض', 'Clara de huevo'),
  'usda:olive-oil': ('زيت زيتون', 'Aceite de oliva'),
  'usda:banana': ('موز', 'Plátano'),
  'usda:blueberries': ('توت أزرق', 'Arándanos'),
  'usda:apple': ('تفاح', 'Manzana'),
  'usda:dates-medjool': ('تمر مجهول', 'Dátiles Medjool'),
  'usda:greek-yogurt-nonfat': ('زبادي يوناني، خالٍ من الدسم', 'Yogur griego natural, desnatado'),
  'usda:milk-semi': ('حليب، 2% دسم', 'Leche semidesnatada (2%)'),
  'usda:salmon-raw': ('سلمون أطلسي، نيء', 'Salmón atlántico, crudo'),
  'usda:tuna-canned-water': ('تونة معلبة بالماء', 'Atún en lata al natural'),
  'usda:beef-mince-90': ('لحم بقري مفروم، 90% قليل الدهن، نيء', 'Carne picada de ternera, 90% magra, cruda'),
  'usda:lentils-cooked': ('عدس، مطبوخ', 'Lentejas, cocidas'),
  'usda:chickpeas-cooked': ('حمص حب، مطبوخ', 'Garbanzos, cocidos'),
  'usda:hummus': ('حمص بطحينة', 'Hummus'),
  'usda:pita-white': ('خبز عربي أبيض', 'Pan de pita blanco'),
  'usda:bread-wholewheat': ('خبز قمح كامل', 'Pan integral'),
  'usda:pasta-cooked': ('معكرونة، مطبوخة', 'Pasta, cocida'),
  'usda:potato-boiled': ('بطاطا مسلوقة', 'Patata cocida'),
  'usda:sweet-potato-baked': ('بطاطا حلوة مشوية', 'Boniato asado'),
  'usda:broccoli': ('بروكلي', 'Brócoli'),
  'usda:avocado': ('أفوكادو', 'Aguacate'),
  'usda:almonds': ('لوز', 'Almendras'),
  'usda:peanut-butter': ('زبدة الفول السوداني', 'Crema de cacahuete'),
  'usda:feta': ('جبن فيتا', 'Queso feta'),
  'usda:cottage-cheese': ('جبن قريش، قليل الدسم', 'Requesón bajo en grasa'),
  'usda:bread-white': ('خبز أبيض', 'Pan blanco'),
  'usda:whey-protein': ('بروتين مصل اللبن (واي)', 'Proteína de suero (whey)'),
};

/// [english] in [languageCode] when the staple has a name there.
String localFoodName(String id, String english, String languageCode) => switch ((_names[id], languageCode)) {
  ((final ar, _), 'ar') => ar,
  ((_, final es), 'es') => es,
  _ => english,
};

/// Lower case without Spanish accents or Arabic marks, so "platano",
/// "plátano" and "Plátano" all match.
String foldForSearch(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[áàâä]'), 'a')
    .replaceAll(RegExp('[éèêë]'), 'e')
    .replaceAll(RegExp('[íìîï]'), 'i')
    .replaceAll(RegExp('[óòôö]'), 'o')
    .replaceAll(RegExp('[úùûü]'), 'u')
    .replaceAll('ñ', 'n')
    .replaceAll(RegExp('[ً-ْـ]'), '')
    .replaceAll(RegExp('[أإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي');

/// Staples whose Arabic or Spanish name holds every word of [query].
List<String> foodIdsNamed(String query) {
  final words = foldForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return const [];
  return [
    for (final MapEntry(key: id, value: (ar, es)) in _names.entries)
      if (words.every((w) => foldForSearch(ar).contains(w)) || words.every((w) => foldForSearch(es).contains(w))) id,
  ];
}
