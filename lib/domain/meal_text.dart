/// Reads a meal written the way you would say it — "200g chicken breast,
/// 150g rice and 10g olive oil", "2 eggs with two slices of bread", "a scoop
/// of whey" — into phrases with an amount, in English, Arabic and Spanish.
/// No network and no model: rules, so it works offline and costs nothing.
library;

/// Counted measures, as opposed to weights.
enum MealUnit { piece, scoop, slice, tbsp, tsp, cup, handful, bowl }

/// One food in the text, before it is matched to the database.
class MealPhrase {
  const MealPhrase({required this.text, required this.food, this.grams, this.count, this.unit});

  /// The phrase as written.
  final String text;

  /// The food words, normalised, with amounts and fillers taken out.
  final String food;

  /// A weight that was written ("200g", "1,5 kg", "10 ml").
  final double? grams;

  /// A count that was written ("2 eggs", "a scoop", "half a cup").
  final double? count;
  final MealUnit? unit;

  /// Nothing said how much, so a normal serving stands in.
  bool get assumed => grams == null && count == null;

  @override
  String toString() => 'MealPhrase($food, g: $grams, n: $count, ${unit?.name})';
}

// ---- normalising ----

final _tashkeel = RegExp('[ً-ْـ]');
const _accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};

/// Lower case, Arabic and Eastern digits as 0-9, no diacritics, and the
/// Arabic letters that are written several ways folded into one.
String normaliseMealText(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      b.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      b.writeCharCode(0x30 + r - 0x06F0);
    } else {
      final c = String.fromCharCode(r);
      b.write(switch (c) {
        'أ' || 'إ' || 'آ' => 'ا',
        'ة' => 'ه',
        'ى' => 'ي',
        '٫' => '.',
        '،' || '؛' => ',',
        _ => _accents[c] ?? c,
      });
    }
  }
  return b.toString().replaceAll(_tashkeel, '');
}

/// A word reduced so plurals and articles match: "eggs" and "egg", "dates"
/// and "date", "huevos" and "huevo", "البيض" and "بيضه".
String mealWordKey(String w) {
  var k = w;
  if (_isArabic(k)) {
    if (k.startsWith('ال') && k.length > 3) k = k.substring(2);
    if (k.endsWith('ات') && k.length > 4) {
      k = k.substring(0, k.length - 2);
    } else if (k.endsWith('ه') && k.length > 2) {
      k = k.substring(0, k.length - 1);
    }
    return k;
  }
  if (k.length > 3 && k.endsWith('s')) k = k.substring(0, k.length - 1);
  if (k.length > 3 && k.endsWith('e')) k = k.substring(0, k.length - 1);
  return k;
}

bool _isArabic(String w) => w.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

// ---- vocabulary ----

const _separators = {'and', 'with', 'plus', '&', '+', 'y', 'e', 'con', 'mas', 'و', 'مع', 'ومع', ',', ';', '\n'};

const _fillers = {
  'of', 'the', 'some', 'my', 'about', 'around', 'x', //
  'de', 'del', 'la', 'el', 'los', 'las', 'unos', 'unas', 'algo', //
  'من', 'حوالي', 'تقريبا', 'شوي',
};

/// Articles count as one only when they open a phrase: "a scoop", "an apple".
const _articles = {'a', 'an', 'un', 'una', 'uno'};

const _numberWords = <String, double>{
  'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6, 'seven': 7, //
  'eight': 8, 'nine': 9, 'ten': 10, 'twelve': 12, 'dozen': 12, 'half': 0.5, 'couple': 2,
  'dos': 2, 'tres': 3, 'cuatro': 4, 'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8, //
  'nueve': 9, 'diez': 10, 'doce': 12, 'docena': 12, 'medio': 0.5, 'media': 0.5,
  'واحد': 1, 'واحده': 1, 'اثنين': 2, 'اثنان': 2, 'ثنتين': 2, 'ثلاث': 3, 'ثلاثه': 3, //
  'اربع': 4, 'اربعه': 4, 'خمس': 5, 'خمسه': 5, 'ست': 6, 'سته': 6, 'سبع': 7, 'سبعه': 7,
  'ثمان': 8, 'ثمانيه': 8, 'تسع': 9, 'تسعه': 9, 'عشر': 10, 'عشره': 10, 'نص': 0.5, 'نصف': 0.5,
};

/// Grams per written unit of weight or volume (ml taken as grams).
const _massUnits = <String, double>{
  'g': 1, 'gr': 1, 'grs': 1, 'gm': 1, 'gram': 1, 'grams': 1, 'gramo': 1, 'gramos': 1, //
  'ml': 1, 'kg': 1000, 'kilo': 1000, 'kilos': 1000, 'l': 1000, 'litre': 1000, 'liter': 1000, 'litro': 1000,
  'oz': 28.35, 'onza': 28.35, 'onzas': 28.35, 'lb': 453.6, 'lbs': 453.6, 'libra': 453.6,
  'غ': 1, 'غم': 1, 'غرام': 1, 'جرام': 1, 'جم': 1, 'مل': 1, 'كغ': 1000, 'كيلو': 1000, 'لتر': 1000,
};

const _countUnits = <String, MealUnit>{
  'scoop': MealUnit.scoop,
  'scoops': MealUnit.scoop,
  'cazo': MealUnit.scoop,
  'cacito': MealUnit.scoop,
  'سكوب': MealUnit.scoop,
  'مغرفه': MealUnit.scoop,
  'slice': MealUnit.slice,
  'slices': MealUnit.slice,
  'rebanada': MealUnit.slice,
  'rebanadas': MealUnit.slice,
  'loncha': MealUnit.slice,
  'lonchas': MealUnit.slice,
  'شريحه': MealUnit.slice,
  'شرائح': MealUnit.slice,
  'tbsp': MealUnit.tbsp,
  'tablespoon': MealUnit.tbsp,
  'tablespoons': MealUnit.tbsp,
  'spoon': MealUnit.tbsp,
  'cucharada': MealUnit.tbsp,
  'cucharadas': MealUnit.tbsp,
  'ملعقه': MealUnit.tbsp,
  'ملاعق': MealUnit.tbsp,
  'tsp': MealUnit.tsp,
  'teaspoon': MealUnit.tsp,
  'teaspoons': MealUnit.tsp,
  'cucharadita': MealUnit.tsp,
  'cucharaditas': MealUnit.tsp,
  'cup': MealUnit.cup,
  'cups': MealUnit.cup,
  'taza': MealUnit.cup,
  'tazas': MealUnit.cup,
  'vaso': MealUnit.cup,
  'كوب': MealUnit.cup,
  'اكواب': MealUnit.cup,
  'كاس': MealUnit.cup,
  'piece': MealUnit.piece,
  'pieces': MealUnit.piece,
  'pieza': MealUnit.piece,
  'piezas': MealUnit.piece,
  'unidad': MealUnit.piece,
  'unidades': MealUnit.piece,
  'حبه': MealUnit.piece,
  'حبات': MealUnit.piece,
  'رغيف': MealUnit.piece,
  'handful': MealUnit.handful,
  'punado': MealUnit.handful,
  'حفنه': MealUnit.handful,
  'bowl': MealUnit.bowl,
  'plate': MealUnit.bowl,
  'plato': MealUnit.bowl,
  'tazon': MealUnit.bowl,
  'صحن': MealUnit.bowl,
  'طبق': MealUnit.bowl,
};

/// Arabic duals carry their "two" inside the word.
const _arabicDuals = <String, (MealUnit?, String?)>{
  'حبتين': (MealUnit.piece, null),
  'شريحتين': (MealUnit.slice, null),
  'ملعقتين': (MealUnit.tbsp, null),
  'كوبين': (MealUnit.cup, null),
  'سكوبين': (MealUnit.scoop, null),
  'رغيفين': (MealUnit.piece, null),
  'بيضتين': (null, 'بيض'),
  'تمرتين': (null, 'تمر'),
  'موزتين': (null, 'موز'),
};

// ---- splitting ----

final _decimalComma = RegExp(r'(\d),(\d)');
final _digitLetter = RegExp(r'(\d)([^\d\s.,/])');
final _letterDigit = RegExp(r'([^\d\s.,/])(\d)');
final _punct = RegExp(r'([,;+&\n])');

/// Sentence marks, but not the point in "1.5".
final _stop = RegExp(r'[!?]|(?<!\d)\.|\.(?!\d)');
final _marks = RegExp(r'[:()"]');
final _number = RegExp(r'^\d+(\.\d+)?$');
final _fraction = RegExp(r'^(\d+)/(\d+)$');

/// Every Arabic word a token may carry a leading "و" ("and") in front of.
final Set<String> _arabicVocab = {
  for (final k in [..._numberWords.keys, ..._massUnits.keys, ..._countUnits.keys, ..._arabicDuals.keys])
    if (_isArabic(k)) k,
};

/// Words in [knownFoodWords] also split on a leading "و": "دجاج ورز".
List<MealPhrase> parseMealText(String input, {Set<String> knownFoodWords = const {}}) {
  final s = normaliseMealText(input)
      .replaceAllMapped(_decimalComma, (m) => '${m[1]}.${m[2]}')
      .replaceAllMapped(_digitLetter, (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(_letterDigit, (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(_punct, (m) => ' ${m[1]} ')
      .replaceAll(_stop, ' , ')
      .replaceAll(_marks, ' ');
  final tokens = <String>[];
  for (final t in s.split(RegExp(r'[ \t\r]+'))) {
    if (t.isEmpty) continue;
    if (t.length > 2 && t.startsWith('و') && !_arabicVocab.contains(t)) {
      final rest = t.substring(1);
      if (_number.hasMatch(rest) || _arabicVocab.contains(rest) || knownFoodWords.contains(mealWordKey(rest))) {
        tokens
          ..add('و')
          ..add(rest);
        continue;
      }
    }
    tokens.add(t);
  }

  final phrases = <MealPhrase>[];
  var group = <String>[];
  void close() {
    final p = _phrase(group);
    if (p != null) phrases.add(p);
    group = [];
  }

  for (final t in tokens) {
    if (_separators.contains(t)) {
      close();
    } else {
      group.add(t);
    }
  }
  close();
  return phrases;
}

MealPhrase? _phrase(List<String> tokens) {
  double? grams;
  double? count;
  MealUnit? unit;
  final food = <String>[];
  double? pending;

  for (final (i, t) in tokens.indexed) {
    final n = _number.hasMatch(t)
        ? double.parse(t)
        : switch (_fraction.firstMatch(t)) {
            final m? when int.parse(m[2]!) != 0 => int.parse(m[1]!) / int.parse(m[2]!),
            _ => _numberWords[t],
          };
    if (n != null) {
      pending = (pending ?? 1) * n;
      continue;
    }
    if (i == 0 && _articles.contains(t)) {
      pending = 1;
      continue;
    }
    final per = _massUnits[t];
    if (pending != null && per != null) {
      grams = (grams ?? 0) + pending * per;
      pending = null;
      continue;
    }
    if (_countUnits[t] case final u?) {
      unit = u;
      count = (count ?? 1) * (pending ?? 1);
      pending = null;
      continue;
    }
    if (_arabicDuals[t] case (final u, final word)) {
      count = 2 * (pending ?? 1);
      pending = null;
      if (u != null) unit = u;
      if (word != null) food.add(word);
      continue;
    }
    if (_articles.contains(t) || _fillers.contains(t)) continue;
    // A number with no unit counts what follows: "2 eggs".
    if (pending != null) {
      count = (count ?? 1) * pending;
      pending = null;
    }
    food.add(t);
  }
  // "eggs 2", "rice 200 g" (unit taken above), or a bare trailing number.
  if (pending != null) count = (count ?? 1) * pending;
  if (food.isEmpty) return null;
  return MealPhrase(
    text: tokens.join(' '),
    food: food.join(' '),
    grams: grams,
    count: grams == null ? count : null,
    unit: grams == null ? unit : null,
  );
}

// ---- matching ----

/// Common names in the three languages, for the staples shipped with the
/// app, so "pollo" and "دجاج" find the same chicken as "chicken".
const mealAliases = <String, List<String>>{
  'usda:chicken-breast-raw': [
    'chicken breast',
    'chicken',
    'pollo',
    'pechuga de pollo',
    'pechuga',
    'دجاج',
    'صدر دجاج',
    'فراخ',
  ],
  'usda:rice-white-cooked': ['rice', 'white rice', 'arroz', 'arroz blanco', 'رز', 'ارز', 'رز ابيض'],
  'usda:rice-basmati-cooked': ['basmati', 'basmati rice', 'arroz basmati', 'رز بسمتي', 'بسمتي'],
  'usda:oats-rolled': ['oats', 'oatmeal', 'porridge', 'avena', 'copos de avena', 'شوفان'],
  'usda:egg-whole-raw': ['egg', 'eggs', 'huevo', 'huevos', 'بيض', 'بيضه'],
  'usda:egg-white-raw': ['egg white', 'egg whites', 'clara', 'claras', 'clara de huevo', 'بياض بيض', 'بياض البيض'],
  'usda:olive-oil': ['olive oil', 'oil', 'aceite de oliva', 'aceite', 'زيت زيتون', 'زيت'],
  'usda:banana': ['banana', 'platano', 'banana', 'موز', 'موزه'],
  'usda:blueberries': ['blueberries', 'blueberry', 'arandanos', 'arandano', 'توت ازرق', 'توت'],
  'usda:apple': ['apple', 'manzana', 'تفاح', 'تفاحه'],
  'usda:dates-medjool': ['date', 'dates', 'datil', 'datiles', 'تمر', 'تمرات', 'تمره'],
  'usda:greek-yogurt-nonfat': [
    'greek yogurt',
    'yogurt',
    'yoghurt',
    'yogur',
    'yogur griego',
    'زبادي',
    'لبن زبادي',
    'زبادي يوناني',
  ],
  'usda:milk-semi': ['milk', 'leche', 'حليب', 'لبن'],
  'usda:salmon-raw': ['salmon', 'salmon', 'سلمون', 'سالمون'],
  'usda:tuna-canned-water': ['tuna', 'atun', 'تونه', 'تونا'],
  'usda:beef-mince-90': [
    'beef',
    'mince',
    'minced beef',
    'ground beef',
    'ternera',
    'carne picada',
    'carne',
    'لحم',
    'لحم مفروم',
    'لحم بقر',
  ],
  'usda:lentils-cooked': ['lentils', 'lentil', 'lentejas', 'عدس'],
  'usda:chickpeas-cooked': ['chickpeas', 'chickpea', 'garbanzos', 'garbanzo', 'حمص حب', 'حمص مسلوق'],
  'usda:hummus': ['hummus', 'houmous', 'humus', 'حمص'],
  'usda:pita-white': ['pita', 'pitta', 'pan de pita', 'خبز عربي', 'خبز لبناني', 'خبز'],
  'usda:bread-white': ['bread', 'toast', 'white bread', 'pan', 'pan blanco', 'tostada', 'توست', 'خبز توست'],
  'usda:bread-wholewheat': [
    'wholewheat bread',
    'whole wheat bread',
    'brown bread',
    'pan integral',
    'خبز اسمر',
    'توست اسمر',
  ],
  'usda:pasta-cooked': ['pasta', 'spaghetti', 'macaroni', 'espaguetis', 'macarrones', 'معكرونه', 'مكرونه', 'باستا'],
  'usda:potato-boiled': ['potato', 'potatoes', 'patata', 'patatas', 'papa', 'papas', 'بطاطس', 'بطاطا'],
  'usda:sweet-potato-baked': ['sweet potato', 'sweet potatoes', 'boniato', 'batata', 'بطاطا حلوه', 'بطاطس حلوه'],
  'usda:broccoli': ['broccoli', 'brocoli', 'بروكلي', 'بروكلي'],
  'usda:avocado': ['avocado', 'aguacate', 'palta', 'افوكادو'],
  'usda:almonds': ['almonds', 'almond', 'almendras', 'almendra', 'لوز'],
  'usda:peanut-butter': [
    'peanut butter',
    'pb',
    'crema de cacahuete',
    'mantequilla de cacahuete',
    'mantequilla de mani',
    'زبده فول سوداني',
    'زبده الفول السوداني',
  ],
  'usda:feta': ['feta', 'queso feta', 'فيتا', 'جبنه فيتا'],
  'usda:cottage-cheese': ['cottage cheese', 'cottage', 'requeson', 'queso cottage', 'جبنه قريش', 'جبنه كوتج', 'كوتج'],
  'usda:whey-protein': [
    'whey',
    'whey protein',
    'protein',
    'protein powder',
    'proteina',
    'proteina whey',
    'بروتين',
    'واي بروتين',
    'واي',
  ],
};

List<String> _keys(String s) => [
  for (final w in normaliseMealText(s).split(RegExp(r'\s+')))
    if (w.isNotEmpty && !_fillers.contains(w)) mealWordKey(w),
];

final _aliasIndex = [
  for (final e in mealAliases.entries)
    for (final a in e.value) (_keys(a), e.key),
]..sort((a, b) => b.$1.length.compareTo(a.$1.length));

/// Every word an alias is made of, keyed, for splitting "دجاج ورز".
final Set<String> mealAliasWords = {for (final (k, _) in _aliasIndex) ...k};

/// The staple a phrase names, by the longest alias found in its words.
String? aliasFoodId(String food) {
  final words = _keys(food);
  for (final (alias, id) in _aliasIndex) {
    for (var i = 0; i + alias.length <= words.length; i++) {
      var hit = true;
      for (var j = 0; j < alias.length && hit; j++) {
        hit = words[i + j] == alias[j];
      }
      if (hit) return id;
    }
  }
  return null;
}

/// One piece of a staple, in grams: an egg, a slice, a date.
const _pieceGrams = <String, double>{
  'usda:egg-whole-raw': 50,
  'usda:egg-white-raw': 33,
  'usda:banana': 118,
  'usda:apple': 182,
  'usda:dates-medjool': 24,
  'usda:pita-white': 60,
  'usda:bread-white': 30,
  'usda:bread-wholewheat': 32,
  'usda:avocado': 150,
  'usda:potato-boiled': 170,
  'usda:sweet-potato-baked': 130,
  'usda:almonds': 1.2,
  'usda:whey-protein': 30,
};

const _cupGrams = <String, double>{
  'usda:rice-white-cooked': 158,
  'usda:rice-basmati-cooked': 158,
  'usda:oats-rolled': 81,
  'usda:milk-semi': 244,
  'usda:greek-yogurt-nonfat': 245,
  'usda:pasta-cooked': 140,
  'usda:lentils-cooked': 198,
  'usda:chickpeas-cooked': 164,
  'usda:blueberries': 148,
  'usda:broccoli': 91,
  'usda:cottage-cheese': 226,
};

const _unitGrams = <MealUnit, double>{
  MealUnit.scoop: 30,
  MealUnit.slice: 30,
  MealUnit.tbsp: 15,
  MealUnit.tsp: 5,
  MealUnit.cup: 200,
  MealUnit.handful: 30,
  MealUnit.bowl: 250,
};

/// What a phrase weighs for a given food: the grams written, or the count
/// times one unit of it, or one normal serving when nothing was written.
double mealPhraseGrams(MealPhrase p, {required String foodId, double? servingGrams}) {
  if (p.grams case final g?) return g;
  final one = switch (p.unit) {
    MealUnit.cup => _cupGrams[foodId] ?? _unitGrams[MealUnit.cup]!,
    MealUnit.tbsp when foodId == 'usda:olive-oil' => 13.5,
    MealUnit.tbsp when foodId == 'usda:peanut-butter' => 16,
    MealUnit.scoop || MealUnit.slice when _pieceGrams[foodId] != null => _pieceGrams[foodId]!,
    null || MealUnit.piece => _pieceGrams[foodId] ?? servingGrams ?? 100,
    final u => _unitGrams[u]!,
  };
  return (p.count ?? 1) * (p.assumed ? (servingGrams ?? one) : one);
}
