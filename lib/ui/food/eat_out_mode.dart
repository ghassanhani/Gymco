import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart' show CloudException;
import '../../data/meal_reader.dart';

import '../../data/models.dart';
import '../../data/packs.dart' show PackDish;
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/pack_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import '../me/account_screen.dart' show cloudMessage;
import 'confirm_log.dart';
import '../../state/config_providers.dart';

/// A restaurant dish at a normal portion: grams and its totals.
typedef _Dish = ({String id, String name, double g, double kcal, double p, double c, double f});

// Typical restaurant servings; an honest middle, not a lab value.
const _dishes = <_Dish>[
  (id: 'burger', name: 'Burger', g: 250, kcal: 650, p: 30, c: 50, f: 35),
  (id: 'pizza', name: 'Pizza, half', g: 350, kcal: 900, p: 38, c: 100, f: 36),
  (id: 'pasta', name: 'Pasta dish', g: 400, kcal: 700, p: 25, c: 95, f: 22),
  (id: 'shawarma', name: 'Shawarma wrap', g: 300, kcal: 650, p: 35, c: 55, f: 30),
  (id: 'sushi', name: 'Sushi, 12 pieces', g: 300, kcal: 500, p: 22, c: 85, f: 8),
  (id: 'curry', name: 'Curry with rice', g: 450, kcal: 800, p: 30, c: 95, f: 32),
  (id: 'salad', name: 'Salad with dressing', g: 300, kcal: 400, p: 15, c: 20, f: 28),
  (id: 'grill', name: 'Grill plate', g: 450, kcal: 850, p: 60, c: 50, f: 45),
];

const _sides = <_Dish>[
  (id: 'fries', name: 'Fries', g: 150, kcal: 470, p: 5, c: 60, f: 23),
  (id: 'garlic', name: 'Garlic sauce', g: 30, kcal: 210, p: 0, c: 2, f: 22),
  (id: 'bread', name: 'Bread', g: 80, kcal: 210, p: 7, c: 40, f: 2),
  (id: 'soda', name: 'Soft drink', g: 330, kcal: 140, p: 0, c: 35, f: 0),
];

const _portions = [0.7, 1.0, 1.35, 1.7];

/// The built-in dishes of one group with their labels, then the eating-out
/// pack's: a pack dish with a built-in id takes its place.
List<(_Dish, String)> _menu(List<_Dish> builtIn, List<String> labels, Iterable<PackDish> pack, String lang) {
  final byId = {
    for (final d in pack)
      d.id: ((id: d.id, name: d.name.en, g: d.g, kcal: d.kcal, p: d.p, c: d.c, f: d.f), d.name.of(lang)),
  };
  return [for (final (i, d) in builtIn.indexed) byId.remove(d.id) ?? (d, labels[i]), ...byId.values];
}

/// The estimate as a food per 100 g, so it logs like any other.
Food _asFood(_Dish d) => Food(
  id: 'eatout:${d.id}',
  name: d.name,
  kcal: d.kcal * 100 / d.g,
  protein: d.p * 100 / d.g,
  carbs: d.c * 100 / d.g,
  fat: d.f * 100 / d.g,
  servingGrams: d.g,
  source: 'estimate',
);

/// Eating out: no label, so pick the dish, the size and the sides for an
/// honest estimate (±20%) instead of a blank day.
class EatOutMode extends ConsumerStatefulWidget {
  const EatOutMode({super.key, required this.meal, required this.onDone});
  final Meal meal;
  final ValueChanged<int> onDone;

  @override
  ConsumerState<EatOutMode> createState() => _EatOutModeState();
}

/// A meal not on the list, as a plain rough total: the kcal as guessed,
/// split the way a restaurant plate usually is.
Food _roughFood(String name, double kcal) => Food(
  id: 'eatout:other',
  name: name,
  kcal: kcal / 4,
  protein: kcal * 0.2 / 4 / 4,
  carbs: kcal * 0.45 / 4 / 4,
  fat: kcal * 0.35 / 9 / 4,
  servingGrams: 400,
  source: 'estimate',
);

class _EatOutModeState extends ConsumerState<EatOutMode> {
  /// The dish picked; [_other] when it is not on the list.
  int? _dish;
  static const _other = -1;
  int _portion = 1;
  final _picked = <int>{};
  final _described = TextEditingController();
  List<(Food, double)> _ai = const [];
  double _rough = 700;
  bool _asking = false;

  @override
  void dispose() {
    _described.dispose();
    super.dispose();
  }

  /// The mains and sides on offer, built-in and from the pack.
  (List<(_Dish, String)>, List<(_Dish, String)>) get _offer {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final pack = ref.read(packsProvider).dishes;
    return (
      _menu(
        _dishes,
        [l.eoBurger, l.eoPizza, l.eoPasta, l.eoShawarma, l.eoSushi, l.eoCurry, l.eoSalad, l.eoGrill],
        pack.where((d) => d.main),
        lang,
      ),
      _menu(_sides, [l.eoFries, l.eoGarlic, l.eoBread, l.eoSoda], pack.where((d) => !d.main), lang),
    );
  }

  List<(Food, double)> get _lines {
    final scale = _portions[_portion];
    final (mains, sides) = _offer;
    return [
      if (_dish case final d? when d >= 0 && d < mains.length) (_asFood(mains[d].$1), mains[d].$1.g * scale),
      if (_dish == _other)
        if (_ai.isNotEmpty)
          for (final (f, g) in _ai) (f, g * scale)
        else
          (
            _roughFood(_described.text.trim().isEmpty ? 'Restaurant meal' : _described.text.trim(), _rough * scale),
            400.0,
          ),
      for (final i in _picked)
        if (i < sides.length) (_asFood(sides[i].$1), sides[i].$1.g),
    ];
  }

  /// The model reads the meal as described, at a restaurant's portion.
  Future<void> _askAi() async {
    final l = AppLocalizations.of(context);
    final text = _described.text.trim();
    if (text.isEmpty) return;
    if (!ref.read(remoteConfigProvider).eatingOutAi) {
      showVToast(context, l.photoPaused, info: true);
      return;
    }
    if ((ref.read(accountProvider).value ?? ref.read(cloudProvider).email) == null) {
      showVToast(context, l.aiNeedsAccount, info: true);
      context.push('/account');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _asking = true);
    try {
      final (foods, _) = await ref
          .read(cloudProvider)
          .scanPhoto(
            null,
            languageCode: Localizations.localeOf(context).languageCode,
            note: l.eoAiNote(text),
            feature: 'eating_out',
            bucket: ref.read(installBucketProvider),
          );
      final db = ref.read(dbProvider);
      final out = <(Food, double)>[];
      for (final f in foods) {
        final food = await resolveEstimate(db, f);
        if (food != null) out.add((food, f.grams ?? food.servingGrams ?? 100));
      }
      if (!mounted) return;
      setState(() => _ai = out);
      if (out.isEmpty) showVToast(context, l.aiCouldNot(1), info: true);
    } on CloudException catch (e) {
      if (mounted) showVToast(context, cloudMessage(l, e.failure), info: true);
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  Future<void> _log() async {
    final l = AppLocalizations.of(context);
    final lines = _lines;
    final ok = await confirmLog(
      context,
      meal: mealName(l, widget.meal).toLowerCase(),
      lines: [
        for (final (f, g) in lines)
          (name: foodName(context, f.id, f.name), grams: g, kcal: f.kcal * g / 100, protein: f.protein * g / 100),
      ],
    );
    if (!ok || !mounted) return;
    final db = ref.read(dbProvider);
    await db.upsertFoods([for (final (f, _) in lines) f]);
    final day = ref.read(todayKeyProvider);
    for (final (f, g) in lines) {
      await ref.read(logActionsProvider).add(LogEntry.of(f, day: day, meal: widget.meal, grams: g));
    }
    if (mounted) widget.onDone(lines.length);
  }

  /// Not on the list: describe it for the AI, or just guess the total.
  List<Widget> _otherMeal(AppLocalizations l) => [
    TextField(
      controller: _described,
      onChanged: (_) => setState(() => _ai = const []),
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 15, color: Volt.t1),
      decoration: InputDecoration(
        hintText: l.eoOtherHint,
        hintStyle: const TextStyle(color: Volt.t4),
        filled: true,
        fillColor: Volt.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ),
    VBtn(
      label: _asking ? l.aiThinking : l.eoAskAi,
      icon: _asking ? null : 'star',
      expand: true,
      onTap: _asking || _described.text.trim().isEmpty ? null : _askAi,
    ),
    if (_ai.isNotEmpty)
      VList(
        children: [
          for (final (f, g) in _ai)
            VItem(
              children: [
                ItemText(
                  foodName(context, f.id, f.name),
                  sub: '${fmtInt(context, g)} ${l.grams} · ${fmtInt(context, f.kcal * g / 100)} ${l.kcal}',
                ),
              ],
            ),
        ],
      )
    else
      VCard(
        tight: true,
        child: Row(
          children: [
            Expanded(child: Muted(l.eoRoughGuess)),
            VStepper(
              label: '${fmtInt(context, _rough)} ${l.kcal}',
              onMinus: _rough > 100 ? () => setState(() => _rough -= 50) : null,
              onPlus: _rough < 3000 ? () => setState(() => _rough += 50) : null,
            ),
          ],
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lines = _lines;
    final kcal = lines.fold<double>(0, (s, x) => s + x.$1.kcal * x.$2 / 100);
    final protein = lines.fold<double>(0, (s, x) => s + x.$1.protein * x.$2 / 100);
    ref.watch(packsProvider);
    final (mains, sides) = _offer;
    final dishNames = [for (final (_, n) in mains) n];
    final sideNames = [for (final (_, n) in sides) n];
    final portionNames = [l.eoSmall, l.eoNormal, l.eoBig, l.eoHuge];

    Widget chips(List<String> names, bool Function(int) on, void Function(int) tap) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final (i, n) in names.indexed) VChip(label: n, on: on(i), onTap: () => tap(i))],
    );

    return GapCol(
      gap: 14,
      cross: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GapCol(gap: 4, children: [EmTitle(l.eatOutTitleEm, size: 24), Muted(l.eatOutSub)]),
        ),
        Eyebrow(l.eoWhat, padding: const EdgeInsetsDirectional.only(start: 4)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (i, n) in dishNames.indexed)
              VChip(label: n, on: _dish == i, onTap: () => setState(() => _dish = _dish == i ? null : i)),
            VChip(
              label: l.eoOther,
              icon: 'plus',
              on: _dish == _other,
              onTap: () => setState(() => _dish = _dish == _other ? null : _other),
            ),
          ],
        ),
        if (_dish == _other) ..._otherMeal(l),
        Eyebrow(l.eoPortion, padding: const EdgeInsetsDirectional.only(start: 4)),
        chips(portionNames, (i) => _portion == i, (i) => setState(() => _portion = i)),
        Eyebrow(l.eoSides, padding: const EdgeInsetsDirectional.only(start: 4)),
        chips(
          sideNames,
          _picked.contains,
          (i) => setState(() => _picked.contains(i) ? _picked.remove(i) : _picked.add(i)),
        ),
        VCard(
          color: Volt.brandWash,
          border: Border.all(color: Volt.brandEdge),
          child: GapCol(
            gap: 10,
            cross: CrossAxisAlignment.stretch,
            children: [
              Eyebrow(l.eoEstimate, color: Volt.brandInk),
              Row(
                children: [
                  for (final (value, unit) in [
                    ('≈ ${fmtInt(context, kcal)}', l.kcal),
                    ('${fmtInt(context, protein)} g', l.protein.toLowerCase()),
                    ('±20%', l.eoRange),
                  ])
                    Expanded(
                      child: GapCol(
                        gap: 2,
                        children: [
                          Text(value, style: numStyle(20)),
                          Muted(unit),
                        ],
                      ),
                    ),
                ],
              ),
              Muted(l.eoNote),
            ],
          ),
        ),
        VBtn(
          label: l.eoLogTo(mealName(l, widget.meal).toLowerCase()),
          expand: true,
          onTap: lines.isEmpty ? null : _log,
        ),
      ],
    );
  }
}
