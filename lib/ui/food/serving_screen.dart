import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import 'confirm_log.dart';
import '../kit/kit.dart';

/// The serving editor: a big amount, unit chips, live macros, the keypad.
/// Kcal and macros track every digit.
class ServingScreen extends ConsumerStatefulWidget {
  const ServingScreen({
    super.key,
    required this.foodId,
    required this.meal,
    this.entryId,
    this.grams,
    this.returnAfterAdd = false,
    this.confirm = false,
  });
  final String foodId;
  final Meal meal;

  /// Set when changing a portion already logged.
  final int? entryId;

  /// A suggested amount to start from, such as a photo's estimate.
  final double? grams;

  /// Go back where it came from after adding, rather than to the meal.
  final bool returnAfterAdd;

  /// Ask once more before adding: for foods that came from a scan or photo.
  final bool confirm;

  @override
  ConsumerState<ServingScreen> createState() => _ServingScreenState();
}

class _ServingScreenState extends ConsumerState<ServingScreen> {
  Food? _food;
  LogEntry? _entry;
  String _amount = '0';
  int _unit = 0;
  late Meal _meal = widget.meal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(dbProvider);
    final f = await db.foodById(widget.foodId);
    LogEntry? e;
    if (widget.entryId != null) {
      e = (await db.entriesFor(ref.read(todayKeyProvider))).where((x) => x.id == widget.entryId).firstOrNull;
    }
    if (!mounted) return;
    setState(() {
      _food = f;
      _entry = e;
      _amount = (e?.grams ?? widget.grams ?? f?.servingGrams ?? 150).round().toString();
    });
  }

  double get _value => double.tryParse(_amount.replaceAll(',', '.')) ?? 0;
  double get _grams => _unit == 0 ? _value : _value * (_food?.servingGrams ?? 1);

  void _key(String k) {
    setState(() {
      if (k == 'del') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (k == ',' || k == '.') {
        if (!_amount.contains(',')) _amount = '$_amount,';
      } else {
        final next = (_amount == '0' ? '' : _amount) + k;
        if ((double.tryParse(next.replaceAll(',', '.')) ?? 0) <= 9999) _amount = next;
      }
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final f = _food!;
    final logs = ref.read(logActionsProvider);
    final name = foodName(context, f.id, f.name).split(',').first;
    if (_entry != null) {
      await logs.setGrams(_entry!, _grams, _meal);
      if (mounted) showVToast(context, l.setTo(name, fmtInt(context, _grams)));
    } else {
      if (widget.confirm) {
        final ok = await confirmLog(
          context,
          meal: mealName(l, _meal).toLowerCase(),
          lines: [
            (
              name: foodName(context, f.id, f.name),
              grams: _grams,
              kcal: f.kcal * _grams / 100,
              protein: f.protein * _grams / 100,
            ),
          ],
        );
        if (!ok || !mounted) return;
      }
      await logs.add(LogEntry.of(f, day: ref.read(todayKeyProvider), meal: _meal, grams: _grams));
      if (mounted) showVToast(context, l.foodAdded(name));
      if (widget.returnAfterAdd) {
        if (mounted) context.pop(true);
        return;
      }
    }
    if (mounted) context.go('/meal/${_meal.name}');
  }

  Future<void> _toggleFavourite() async {
    final l = AppLocalizations.of(context);
    final f = _food!;
    await ref.read(dbProvider).setFavourite(f.id, !f.favourite);
    final next = await ref.read(dbProvider).foodById(f.id);
    if (!mounted) return;
    setState(() => _food = next);
    showVToast(context, next!.favourite ? l.savedToFavourites : l.removedFromFavourites);
  }

  Future<void> _saveCustom() async {
    final l = AppLocalizations.of(context);
    await ref.read(dbProvider).saveAsCustom(_food!);
    ref.invalidate(customFoodsProvider);
    if (mounted) showVToast(context, l.savedAsCustom);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final f = _food;
    if (f == null) return const Scaffold(body: VScreen(child: SizedBox.shrink()));
    final k = _grams / 100;
    final kcal = f.kcal * k;

    Widget macro(String label, double v, Color c) => Expanded(
      child: MacroTile(
        label: label,
        value: '${v < 10 ? fmtDec(context, v) : fmtInt(context, v)} ${l.grams}',
        color: c,
        compact: true,
      ),
    );

    final units = [l.grams, if (f.servingGrams != null) l.oneServing(fmtInt(context, f.servingGrams!))];

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBtn(
                    'back',
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: GapCol(
                        gap: 4,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  foodName(context, f.id, f.name),
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
                                ),
                              ),
                              if (f.verified) ...[const SizedBox(width: 6), VIcon('check', size: 15, color: Volt.blue)],
                            ],
                          ),
                          Muted(
                            f.source == 'off'
                                ? l.labelVerifiedOff(f.brand ?? '')
                                : f.source == 'usda'
                                ? l.genericUsdaVerified
                                : f.source == 'ai'
                                ? l.aiEstimateLabel
                                : f.source == 'recipe'
                                ? l.yourRecipe
                                : f.source == 'pack'
                                ? l.packFoodLabel
                                : '${f.brand ?? l.customFood} · ${l.createdByYou}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconBtn(
                    'star',
                    label: l.saveToFavourites,
                    iconSize: 19,
                    color: f.favourite ? Volt.brandInk : null,
                    onTap: _toggleFavourite,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GapCol(
                cross: CrossAxisAlignment.stretch,
                children: [
                  VCard(
                    child: GapCol(
                      gap: 14,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Volt.lime, width: 2)),
                                    ),
                                    child: Text(_amount, style: numStyle(44, height: 1.05)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _unit == 0 ? l.grams : '×',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Volt.t2),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(fmtInt(context, kcal), style: numStyle(24, height: 1.2)),
                                Text(l.kcal, style: TextStyle(fontSize: 11, color: Volt.t3)),
                              ],
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < units.length; i++)
                              VChip(
                                label: units[i],
                                on: i == _unit,
                                onTap: () => setState(() {
                                  _unit = i;
                                  _amount = i == 0 ? (f.servingGrams ?? 150).round().toString() : '1';
                                }),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            macro(l.protein, f.protein * k, Volt.protein),
                            const SizedBox(width: 8),
                            macro(l.carbs, f.carbs * k, Volt.carbs),
                            const SizedBox(width: 8),
                            macro(l.fat, f.fat * k, Volt.fat),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VCard(
                    tight: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l.mealLabel, style: TextStyle(fontSize: 13, color: Volt.t2)),
                        ),
                        Pressable(
                          onTap: () => setState(() => _meal = Meal.values[(_meal.index + 1) % 4]),
                          child: Row(
                            children: [
                              Text(
                                mealName(l, _meal),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                              ),
                              const SizedBox(width: 6),
                              VIcon('down', size: 15, color: Volt.t1),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Keypad(onKey: _key, deleteLabel: l.deleteDigit),
            Container(
              color: Volt.card,
              padding: EdgeInsets.fromLTRB(12, 8, 12, 18 + MediaQuery.paddingOf(context).bottom),
              child: Row(
                children: [
                  if (f.source != 'local' && f.source != 'recipe') ...[
                    Expanded(
                      flex: 10,
                      child: VBtn(label: l.saveAsCustom, kind: BtnKind.ghost, expand: true, onTap: _saveCustom),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 14,
                    child: VBtn(
                      label: _entry == null ? l.addKcal(fmtInt(context, kcal)) : l.saveKcal(fmtInt(context, kcal)),
                      expand: true,
                      onTap: _grams > 0 ? _save : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
