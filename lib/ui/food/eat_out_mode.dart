import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'confirm_log.dart';

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

class _EatOutModeState extends ConsumerState<EatOutMode> {
  int? _dish;
  int _portion = 1;
  final _picked = <int>{};

  List<(_Dish, double)> get _lines => [
    if (_dish != null) (_dishes[_dish!], _dishes[_dish!].g * _portions[_portion]),
    for (final i in _picked) (_sides[i], _sides[i].g),
  ];

  Future<void> _log() async {
    final l = AppLocalizations.of(context);
    final lines = _lines;
    final ok = await confirmLog(
      context,
      meal: mealName(l, widget.meal).toLowerCase(),
      lines: [
        for (final (d, g) in lines)
          (name: foodName(context, 'eatout:${d.id}', d.name), grams: g, kcal: d.kcal * g / d.g, protein: d.p * g / d.g),
      ],
    );
    if (!ok || !mounted) return;
    final db = ref.read(dbProvider);
    await db.upsertFoods([for (final (d, _) in lines) _asFood(d)]);
    final day = ref.read(todayKeyProvider);
    for (final (d, g) in lines) {
      await ref.read(logActionsProvider).add(LogEntry.of(_asFood(d), day: day, meal: widget.meal, grams: g));
    }
    if (mounted) widget.onDone(lines.length);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lines = _lines;
    final kcal = lines.fold<double>(0, (s, x) => s + x.$1.kcal * x.$2 / x.$1.g);
    final protein = lines.fold<double>(0, (s, x) => s + x.$1.p * x.$2 / x.$1.g);
    final dishNames = [l.eoBurger, l.eoPizza, l.eoPasta, l.eoShawarma, l.eoSushi, l.eoCurry, l.eoSalad, l.eoGrill];
    final sideNames = [l.eoFries, l.eoGarlic, l.eoBread, l.eoSoda];
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
        chips(dishNames, (i) => _dish == i, (i) => setState(() => _dish = _dish == i ? null : i)),
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
