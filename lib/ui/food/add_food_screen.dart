import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/food_source.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

/// The meal a bare "add food" goes to, from the time of day.
Meal mealForHour(int h) => h < 11
    ? Meal.breakfast
    : h < 16
    ? Meal.lunch
    : h < 21
    ? Meal.dinner
    : Meal.snack;

/// Write it, don't search for it: five ways in, as peers, and a search that
/// collects several foods before logging them together.
class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, required this.meal, this.asTab = false, this.mode = 'search'});
  final Meal meal;

  /// Shown as the Food tab rather than pushed over Today.
  final bool asTab;
  final String mode;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _q = TextEditingController();
  Timer? _debounce;
  List<Food> _local = [];
  List<Food> _online = [];
  bool _searching = false;
  bool _offline = false;
  int _seq = 0;
  late String _mode = widget.mode;
  late Meal _meal = widget.meal;
  final _picks = <Food>[];

  /// 0 recent, 1 my meals, 2 recipes, 3 custom.
  int _shelf = 0;

  @override
  void initState() {
    super.initState();
    _run('');
    if (_mode == 'barcode') WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(v));
  }

  /// The phone answers first; the network only adds to it.
  Future<void> _run(String q) async {
    final seq = ++_seq;
    final db = ref.read(dbProvider);
    var local = await db.searchFoods(q);
    // Nothing recent yet: offer the bundled staples instead of an empty list.
    if (q.trim().isEmpty && local.isEmpty) local = await db.staples();
    if (!mounted || seq != _seq) return;
    setState(() {
      _local = local;
      _online = [];
      _offline = false;
      _searching = q.trim().length >= 3;
    });
    if (q.trim().length < 3) return;
    try {
      final lang = Localizations.localeOf(context).languageCode;
      final found = await ref.read(foodSourceProvider).search(q, languageCode: lang);
      await db.upsertFoods(found);
      if (!mounted || seq != _seq) return;
      final known = local.map((f) => f.id).toSet();
      setState(() => _online = found.where((f) => !known.contains(f.id)).toList());
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _offline = true);
    } finally {
      if (mounted && seq == _seq) setState(() => _searching = false);
    }
  }

  void _toggle(Food f) =>
      setState(() => _picks.any((p) => p.id == f.id) ? _picks.removeWhere((p) => p.id == f.id) : _picks.add(f));

  Future<void> _logPicks() async {
    final l = AppLocalizations.of(context);
    final day = ref.read(todayKeyProvider);
    for (final f in _picks) {
      await ref.read(logActionsProvider).add(LogEntry.of(f, day: day, meal: _meal, grams: f.servingGrams ?? 150));
    }
    final n = _picks.length;
    if (!mounted) return;
    setState(_picks.clear);
    showVToast(context, l.itemsLoggedTo(n, mealName(l, _meal).toLowerCase()));
    context.go('/meal/${_meal.name}');
  }

  List<Widget> _savedMeals(AppLocalizations l, bool noNumbers) {
    final meals = ref.watch(savedMealsProvider).value ?? const <SavedMeal>[];
    if (meals.isEmpty) return [_Shelf(text: l.noSavedMeals)];
    return [
      VList(
        children: [
          for (final m in meals)
            VItem(
              semantics: m.name,
              onTap: () async {
                await ref.read(logActionsProvider).logSaved(m, _meal);
                if (!mounted) return;
                showVToast(context, l.loggedSavedMeal(m.name));
                context.go('/meal/${_meal.name}');
              },
              children: [
                const VIcon('star', size: 19, color: Volt.t3),
                ItemText(
                  m.name,
                  sub: noNumbers
                      ? l.itemsCount(m.items.length)
                      : l.savedMealSub(m.items.length, fmtInt(context, m.kcal)),
                ),
                const Pick(),
              ],
            ),
        ],
      ),
    ];
  }

  Future<void> _scan() async {
    final code = await context.push<String>('/scan');
    if (code == null || !mounted) return;
    final db = ref.read(dbProvider);
    var food = await db.foodByBarcode(code);
    if (food == null) {
      try {
        if (!mounted) return;
        final lang = Localizations.localeOf(context).languageCode;
        food = await ref.read(foodSourceProvider).byBarcode(code, languageCode: lang);
        if (food != null) await db.upsertFoods([food]);
      } catch (_) {
        food = null;
      }
    }
    if (!mounted) return;
    if (food == null) {
      context.push('/barcode-miss/$code');
    } else {
      context.push('/serving/${Uri.encodeComponent(food.id)}?meal=${_meal.name}');
    }
  }

  void _pickMode(String m) {
    if (m == 'barcode') {
      _scan();
      return;
    }
    setState(() => _mode = m);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final noNumbers = ref.watch(settingsProvider.select((s) => s.noNumbers));
    final profile = ref.watch(profileProvider);
    final totals = DayTotals(ref.watch(dayEntriesProvider(ref.watch(todayKeyProvider))).value ?? const []);
    final q = _q.text.trim();
    final results = [..._local, ..._online];
    final meal = mealName(l, _meal).toLowerCase();

    final methods = [
      Method('search', l.mSearch, 'search'),
      Method('write', l.mWrite, 'list'),
      Method('voice', l.mVoice, 'mic'),
      Method('camera', l.mPhoto, 'camera'),
      Method('barcode', l.mBarcode, 'scan'),
    ];

    final left = profile == null
        ? ''
        : l.leftToday(
            fmtInt(context, (profile.targetKcal - totals.kcal).clamp(0, 99999)),
            fmtInt(context, (profile.targets.protein - totals.macros.protein).clamp(0, 9999)),
          );

    final header = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Volt.line)),
      ),
      child: GapCol(
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GapCol(
                  gap: 2,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _meal = Meal.values[(_meal.index + 1) % 4]),
                      child: Text(
                        l.addToMeal(meal),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Volt.t1),
                      ),
                    ),
                    Muted(noNumbers ? l.logNoWeighing : left),
                  ],
                ),
              ),
              IconBtn(
                'close',
                label: MaterialLocalizations.of(context).closeButtonTooltip,
                iconSize: 18,
                onTap: () => widget.asTab ? context.go('/today') : context.pop(),
              ),
            ],
          ),
          MethodRow(methods: methods, current: _mode, onPick: _pickMode),
          if (_mode == 'search') ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(13)),
              child: Row(
                children: [
                  const VIcon('search', size: 18, color: Volt.t3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _q,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15, color: Volt.t1),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: l.whatDidYouHave(meal),
                      ),
                    ),
                  ),
                  if (_searching)
                    const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, label) in [l.recent, l.myMeals, l.recipes, l.custom].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    VChip(label: label, on: _shelf == i, onTap: () => setState(() => _shelf = i)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    final List<Widget> body;
    if (_mode != 'search') {
      body = [_ComingMode(mode: _mode)];
    } else if (q.isEmpty && _shelf == 1) {
      body = _savedMeals(l, noNumbers);
    } else if (q.isEmpty && _shelf == 2) {
      body = [_Shelf(text: l.recipesSoon)];
    } else if (q.isEmpty && _shelf == 3) {
      final custom = ref.watch(customFoodsProvider).value ?? const <Food>[];
      body = custom.isEmpty
          ? [_Shelf(text: l.noCustomFoods)]
          : [
              VList(
                children: [
                  for (final f in custom)
                    _FoodItem(
                      food: f,
                      on: _picks.any((p) => p.id == f.id),
                      noNumbers: noNumbers,
                      onTap: () => _toggle(f),
                    ),
                ],
              ),
            ];
    } else if (results.isEmpty && q.isNotEmpty && !_searching) {
      body = [_NoMatch(onScan: _scan)];
    } else {
      body = [
        if (_offline)
          Row(
            children: [
              const VIcon('wifioff', size: 16, color: Volt.warn),
              const SizedBox(width: 8),
              Expanded(child: Muted(l.offlineSearch, color: Volt.warn)),
            ],
          ),
        if (results.isNotEmpty)
          Eyebrow(
            q.isEmpty ? l.usuallyNow : l.resultsCount(results.length),
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          ),
        if (results.isNotEmpty)
          VList(
            children: [
              for (final f in results)
                _FoodItem(food: f, on: _picks.any((p) => p.id == f.id), noNumbers: noNumbers, onTap: () => _toggle(f)),
            ],
          ),
      ];
    }

    final pickKcal = _picks.fold<double>(0, (s, f) => s + f.kcal * (f.servingGrams ?? 150) / 100);
    final pickP = _picks.fold<double>(0, (s, f) => s + f.protein * (f.servingGrams ?? 150) / 100);

    final screen = VScreen(
      overlays: [
        if (_picks.isNotEmpty && _mode == 'search')
          LogBar(
            aboveTabs: widget.asTab,
            children: [
              Expanded(
                child: GapCol(
                  gap: 2,
                  children: [
                    Text(
                      l.itemsSelected(_picks.length),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                    Muted(
                      noNumbers ? l.readyToLog : l.kcalAndProtein(fmtInt(context, pickKcal), fmtInt(context, pickP)),
                    ),
                  ],
                ),
              ),
              VBtn(label: l.logN(_picks.length), small: true, onTap: _logPicks),
            ],
          ),
      ],
      child: Column(
        children: [
          header,
          Expanded(
            child: Pad(top: 12, bottom: _picks.isNotEmpty ? 168 : (widget.asTab ? 116 : 24), children: body),
          ),
        ],
      ),
    );
    return widget.asTab ? screen : Scaffold(body: screen);
  }
}

class _FoodItem extends StatelessWidget {
  const _FoodItem({required this.food, required this.on, required this.noNumbers, required this.onTap});
  final Food food;
  final bool on;
  final bool noNumbers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final g = food.servingGrams ?? 150;
    final brand = food.brand ?? (food.source == 'usda' ? l.genericUsda : l.customFood);
    return VItem(
      color: on ? Volt.brandWash : null,
      onTap: onTap,
      semantics: food.name,
      children: [
        ItemText(
          food.name,
          sub: noNumbers
              ? brand
              : '$brand · ${fmtInt(context, g)} ${l.grams} · ${fmtInt(context, food.kcal * g / 100)} ${l.kcal}',
          trailingName: food.verified ? const VIcon('check', size: 14, color: Volt.blue) : null,
        ),
        Pick(on: on),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
    child: Text(text, style: const TextStyle(fontSize: 14, height: 1.45, color: Volt.t3)),
  );
}

class _NoMatch extends StatelessWidget {
  const _NoMatch({required this.onScan});
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: GapCol(
        gap: 14,
        cross: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GapCol(
              gap: 10,
              cross: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 60, height: 60, child: CustomPaint(painter: _NoMatchArt())),
                Text(
                  l.noMatchTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
                Muted(l.noMatchBody, align: TextAlign.center),
              ],
            ),
          ),
          VBtn(
            label: l.scanBarcode,
            onTap: onScan,
            child: Row(
              children: [
                Expanded(
                  child: GapCol(
                    gap: 2,
                    children: [
                      Text(l.scanBarcode),
                      Opacity(
                        opacity: 0.9,
                        child: Text(
                          l.scanBarcodeSub,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                ),
                const VIcon('fwd', size: 18, color: Volt.ink),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.searchOtherLanguage)),
        ],
      ),
    );
  }
}

class _NoMatchArt extends CustomPainter {
  const _NoMatchArt();

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 64;
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * k
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(28 * k, 28 * k), 17 * k, p(Volt.line2));
    canvas.drawLine(Offset(40 * k, 40 * k), Offset(52 * k, 52 * k), p(Volt.line2));
    canvas.drawLine(Offset(22 * k, 28 * k), Offset(34 * k, 28 * k), p(Volt.t4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Write, Voice and Photo arrive with AI logging; until then they say so
/// rather than pretend.
class _ComingMode extends StatelessWidget {
  const _ComingMode({required this.mode});
  final String mode;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (icon, text) = switch (mode) {
      'write' => ('list', l.writeComing),
      'voice' => ('mic', l.voiceComing),
      _ => ('camera', l.photoComing),
    };
    return VCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: GapCol(
        gap: 10,
        cross: CrossAxisAlignment.center,
        children: [
          IconBtn(icon, label: text, onTap: null, iconSize: 22, color: Volt.t2),
          Muted(text, align: TextAlign.center),
        ],
      ),
    );
  }
}

/// A barcode the databases don't know: a 30-second contribution back.
class BarcodeMissScreen extends StatelessWidget {
  const BarcodeMissScreen({super.key, required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.barcodeMiss, sub: code),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  VCard(
                    child: GapCol(
                      children: [
                        Text(
                          l.barcodeMiss,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
                        ),
                        Muted(l.barcodeMissBody),
                      ],
                    ),
                  ),
                  VBtn(
                    label: l.contributeOff,
                    trailingIcon: 'fwd',
                    onTap: () => launchUrl(openFoodFactsAddUrl(code), mode: LaunchMode.externalApplication),
                  ),
                  VBtn(label: l.cancel, kind: BtnKind.ghost, onTap: () => context.pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
