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
import '../common/widgets.dart';
import 'serving_sheet.dart';

/// The meal a bare "add food" goes to, from the time of day.
Meal mealForHour(int h) => h < 11
    ? Meal.breakfast
    : h < 16
    ? Meal.lunch
    : h < 21
    ? Meal.dinner
    : Meal.snack;

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key, required this.meal, this.asTab = false});
  final Meal meal;

  /// Shown as the Food tab rather than pushed over Today.
  final bool asTab;

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

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(v));
  }

  /// The phone answers first; the network only adds to it.
  Future<void> _run(String q) async {
    final seq = ++_seq;
    final db = ref.read(dbProvider);
    final local = await db.searchFoods(q);
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

  Future<void> _pick(Food f) async {
    final logged = await showServingSheet(context, food: f, meal: widget.meal);
    if (logged && mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.logged(f.name))));
      if (!widget.asTab) context.pop();
    }
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
      await _barcodeMiss(code);
    } else {
      await _pick(food);
    }
  }

  Future<void> _barcodeMiss(String code) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.barcodeMiss, style: t.titleLarge),
              const SizedBox(height: 8),
              Text(l.barcodeMissBody, style: t.bodyMedium),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GlowButton(
                  label: l.contributeOff,
                  onPressed: () {
                    launchUrl(openFoodFactsAddUrl(code), mode: LaunchMode.externalApplication);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final q = _q.text.trim();
    final results = [..._local, ..._online];

    final body = SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                if (!widget.asTab) const BackButton(),
                Expanded(child: Text(l.addTo(mealName(l, widget.meal)), style: t.titleLarge)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.searchFoods,
                      prefixIcon: const Icon(Icons.search_rounded, color: Volt.t3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: l.scanBarcode,
                  onPressed: _scan,
                  style: IconButton.styleFrom(
                    backgroundColor: Volt.card2,
                    foregroundColor: Volt.t1,
                    minimumSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                ),
              ],
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          if (_offline)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 16, color: Volt.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.offlineSearch, style: t.bodySmall?.copyWith(color: Volt.warn)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: results.isEmpty && q.isNotEmpty && !_searching
                ? _NoResults(query: q, onScan: _scan)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
                    itemCount: results.length + (q.isEmpty && results.isNotEmpty ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      if (q.isEmpty) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: Text(l.recent, style: t.labelSmall),
                          );
                        }
                        i -= 1;
                      }
                      return _FoodRow(food: results[i], onTap: () => _pick(results[i]));
                    },
                  ),
          ),
        ],
      ),
    );

    return widget.asTab ? VoltBackground(child: body) : Scaffold(body: VoltBackground(child: body));
  }
}

class _FoodRow extends ConsumerWidget {
  const _FoodRow({required this.food, required this.onTap});
  final Food food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final noNumbers = ref.watch(settingsProvider.select((s) => s.noNumbers));
    final sub = [?food.brand, if (!noNumbers) '${fmtInt(context, food.kcal)} ${l.kcal} ${l.per100g}'].join(' · ');
    return VoltCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleMedium?.copyWith(fontSize: 15),
                ),
                if (sub.isNotEmpty) ...[const SizedBox(height: 2), Text(sub, style: t.bodySmall)],
              ],
            ),
          ),
          const Icon(Icons.add_rounded, color: Volt.brand),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.onScan});
  final String query;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 40, color: Volt.t3),
          const SizedBox(height: 12),
          Text(l.noResults(query), textAlign: TextAlign.center, style: t.titleMedium),
          const SizedBox(height: 6),
          Text(l.noResultsBody, textAlign: TextAlign.center, style: t.bodyMedium),
          const SizedBox(height: 16),
          GhostButton(label: l.scanBarcode, icon: Icons.qr_code_scanner_rounded, onPressed: onScan),
        ],
      ),
    );
  }
}
