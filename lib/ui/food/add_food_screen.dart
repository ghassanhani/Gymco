import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/cloud.dart' show CloudException;
import '../../data/food_source.dart';
import '../../data/meal_reader.dart';
import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/ask_iron.dart';
import '../kit/kit.dart';
import '../progress/progress_screen.dart' show showNumberSheet;
import '../me/account_screen.dart' show cloudMessage;
import 'confirm_log.dart';
import 'eat_out_mode.dart';
import 'photo_mode.dart';
import 'write_mode.dart';
import '../../state/config_providers.dart';

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

  // Write and Voice share one text and one reader.
  final _log = TextEditingController();
  Timer? _readDebounce;
  int _readSeq = 0;
  List<WrittenItem> _written = [];
  final _dropped = <int>{};

  /// 'write' or 'voice': which mode the text came from.
  String _textFrom = 'write';
  bool _listening = false;
  bool? _micOk;

  @override
  void initState() {
    super.initState();
    _run('');
    if (_mode == 'barcode') WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _readDebounce?.cancel();
    if (_listening) ref.read(dictationProvider).stop();
    _q.dispose();
    _log.dispose();
    super.dispose();
  }

  void _onLogChanged(String _) {
    setState(() {});
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 250), _read);
  }

  Future<void> _read() async {
    final seq = ++_readSeq;
    final items = await readWrittenMeal(ref.read(dbProvider), _log.text);
    if (!mounted || seq != _readSeq) return;
    setState(() {
      _written = items;
      _dropped.clear();
    });
  }

  List<WrittenItem> get _toAdd => [
    for (final (i, it) in _written.indexed)
      if (it.food != null && !_dropped.contains(i)) it,
  ];

  Future<void> _addWritten() async {
    final l = AppLocalizations.of(context);
    final day = ref.read(todayKeyProvider);
    final items = _toAdd;
    final ok = await confirmLog(
      context,
      meal: mealName(l, _meal).toLowerCase(),
      lines: [
        for (final it in items)
          (name: foodName(context, it.food!.id, it.food!.name), grams: it.grams, kcal: it.kcal, protein: it.protein),
      ],
    );
    if (!ok || !mounted) return;
    for (final it in items) {
      await ref.read(logActionsProvider).add(LogEntry.of(it.food!, day: day, meal: _meal, grams: it.grams));
    }
    if (!mounted) return;
    setState(() {
      _log.clear();
      _written = [];
    });
    showVToast(context, l.itemsLoggedTo(items.length, mealName(l, _meal).toLowerCase()));
    context.go('/meal/${_meal.name}');
  }

  bool _asking = false;

  bool get _signedIn => (ref.read(accountProvider).value ?? ref.read(cloudProvider).email) != null;

  /// The model needs an account (it keeps the daily count), so say so.
  bool _needAccount() {
    if (_signedIn) return false;
    showVToast(context, AppLocalizations.of(context).aiNeedsAccount, info: true);
    context.push('/account');
    return true;
  }

  /// Every food the reader could not match, sent to the model in one go,
  /// using the words as written. A written weight wins over its guess.
  Future<void> _askAll() async {
    if (_needAccount()) return;
    final l = AppLocalizations.of(context);
    final missing = [
      for (final (i, it) in _written.indexed)
        if (it.food == null && !_dropped.contains(i)) i,
    ];
    if (missing.isEmpty) return;
    setState(() => _asking = true);
    try {
      final note = missing.map((i) => _written[i].phrase.text).join('\n');
      final (foods, _) = await ref
          .read(cloudProvider)
          .scanPhoto(
            null,
            languageCode: Localizations.localeOf(context).languageCode,
            note: note,
            bucket: ref.read(installBucketProvider),
          );
      final db = ref.read(dbProvider);
      if (foods.length == missing.length) {
        for (final (k, i) in missing.indexed) {
          final food = await resolveEstimate(db, foods[k]);
          if (food == null) continue;
          final it = _written[i];
          _written[i] = WrittenItem(
            phrase: it.phrase,
            food: food,
            grams: it.phrase.grams ?? foods[k].grams ?? food.servingGrams ?? 100,
          );
        }
      } else {
        // Counts differ: ask about each one on its own.
        for (final i in missing) {
          await _estimateWritten(i, quiet: true);
        }
      }
      if (!mounted) return;
      final still = missing.where((i) => _written[i].food == null).length;
      if (still > 0) showVToast(context, l.aiCouldNot(still), info: true);
    } on CloudException catch (e) {
      if (mounted) showVToast(context, cloudMessage(l, e.failure), info: true);
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  /// A food the reader could not match: ask the model for its figures,
  /// using the words as written. Takes one of the day's scans.
  Future<void> _estimateWritten(int i, {bool quiet = false}) async {
    if (!quiet && _needAccount()) return;
    final l = AppLocalizations.of(context);
    final it = _written[i];
    try {
      final (foods, _) = await ref
          .read(cloudProvider)
          .scanPhoto(
            null,
            languageCode: Localizations.localeOf(context).languageCode,
            note: it.phrase.text,
            bucket: ref.read(installBucketProvider),
          );
      final guess = foods.firstOrNull;
      final food = guess == null ? null : await resolveEstimate(ref.read(dbProvider), guess);
      if (!mounted) return;
      if (food == null) {
        if (!quiet) showVToast(context, l.notInDbYet, info: true);
        return;
      }
      setState(
        () => _written[i] = WrittenItem(
          phrase: it.phrase,
          food: food,
          grams: it.phrase.grams ?? guess!.grams ?? food.servingGrams ?? 100,
        ),
      );
    } on CloudException catch (e) {
      if (quiet) rethrow;
      if (mounted) showVToast(context, cloudMessage(l, e.failure), info: true);
    }
  }

  void _findByName(String name) {
    _q.text = name;
    setState(() => _mode = 'search');
    _run(_q.text);
  }

  /// Not on the phone yet: look for it the usual way.
  void _findWritten(WrittenItem it) {
    _q.text = it.phrase.food;
    setState(() => _mode = 'search');
    _run(_q.text);
  }

  void _editWritten(int i) {
    final l = AppLocalizations.of(context);
    final it = _written[i];
    showNumberSheet(
      context,
      title: l.howMuchOf(foodName(context, it.food!.id, it.food!.name).toLowerCase()),
      unit: 'g',
      initial: it.grams,
      note: l.gramsNote,
      max: 3000,
      onSave: (g) => setState(() => _written[i] = it.withGrams(g)),
    );
  }

  Future<void> _listen() async {
    if (_listening) return;
    setState(() {
      _listening = true;
      _textFrom = 'voice';
    });
    final ok = await ref
        .read(dictationProvider)
        .start(
          languageCode: Localizations.localeOf(context).languageCode,
          onWords: (w) {
            if (!mounted) return;
            _log.text = w;
            _onLogChanged(w);
          },
        );
    if (!mounted) return;
    if (!ok) setState(() => _listening = false);
    setState(() => _micOk = ok);
  }

  Future<void> _stopListening() async {
    if (!_listening) return;
    await ref.read(dictationProvider).stop();
    if (mounted) setState(() => _listening = false);
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

  List<Widget> _savedMeals(AppLocalizations l) {
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
                VIcon('star', size: 19, color: Volt.t3),
                ItemText(m.name, sub: l.savedMealSub(m.items.length, fmtInt(context, m.kcal))),
                const Pick(),
              ],
            ),
        ],
      ),
    ];
  }

  List<Widget> _recipes(AppLocalizations l) {
    final recipes = ref.watch(recipesProvider).value ?? const <Recipe>[];
    return [
      VBtn(
        label: l.newRecipe,
        kind: BtnKind.ghost,
        icon: 'plus',
        expand: true,
        onTap: () => context.push('/recipe/new'),
      ),
      if (recipes.isEmpty)
        _Shelf(text: l.noRecipes)
      else
        VList(
          children: [
            for (final r in recipes)
              VItem(
                semantics: r.name,
                onTap: () =>
                    context.push('/serving/${Uri.encodeComponent(Recipe.foodId(r.id))}?meal=${_meal.name}&confirm=1'),
                children: [
                  VIcon('food', size: 19, color: Volt.t3),
                  ItemText(r.name, sub: l.recipeSub(r.servings, fmtInt(context, r.kcalPerServing))),
                  IconBtn(
                    'more',
                    label: l.editRecipe,
                    size: 32,
                    iconSize: 16,
                    background: Colors.transparent,
                    color: Volt.t3,
                    onTap: () => context.push('/recipe/${r.id}'),
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
      context.push('/serving/${Uri.encodeComponent(food.id)}?meal=${_meal.name}&confirm=1');
    }
  }

  void _pickMode(String m) {
    if (m == 'barcode') {
      _scan();
      return;
    }
    if (_mode == 'voice') _stopListening();
    setState(() {
      _mode = m;
      if (m == 'write') _textFrom = 'write';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    final totals = DayTotals(ref.watch(dayEntriesProvider(ref.watch(todayKeyProvider))).value ?? const []);
    final q = _q.text.trim();
    final results = [..._local, ..._online];
    final meal = mealName(l, _meal).toLowerCase();

    final rc = ref.watch(remoteConfigProvider);
    final methods = [
      Method('search', l.mSearch, 'search'),
      Method('write', l.mWrite, 'list'),
      if (rc.dictate) Method('voice', l.mVoice, 'mic'),
      if (rc.photoLog) Method('camera', l.mPhoto, 'camera'),
      Method('barcode', l.mBarcode, 'scan'),
      if (rc.eatingOut) Method('eatout', l.mEatOut, 'food'),
    ];

    final left = profile == null
        ? ''
        : l.leftToday(
            fmtInt(context, (profile.targetKcal - totals.kcal).clamp(0, 99999)),
            fmtInt(context, (profile.targets.protein - totals.macros.protein).clamp(0, 9999)),
          );

    void nextMeal() => setState(() => _meal = Meal.values[(_meal.index + 1) % 4]);
    // As the Food tab it opens like the other tabs: the big title and its
    // line, no close button (the tab bar is the way out). Pushed from a meal
    // it keeps the compact title and a close button.
    final titleRow = widget.asTab
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: nextMeal,
              behavior: HitTestBehavior.opaque,
              child: Semantics(
                button: true,
                label: l.addToMeal(meal),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: EmTitle(l.addToMeal(meal))),
                        const SizedBox(width: 6),
                        VIcon('down', size: 20, color: Volt.t3),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(left, style: TextStyle(fontSize: 12.5, color: Volt.t3)),
                  ],
                ),
              ),
            ),
          )
        : Row(
            children: [
              Expanded(
                child: GapCol(
                  gap: 2,
                  children: [
                    GestureDetector(
                      onTap: nextMeal,
                      child: Text(
                        l.addToMeal(meal),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Volt.t1),
                      ),
                    ),
                    Muted(left),
                  ],
                ),
              ),
              IconBtn(
                'close',
                label: MaterialLocalizations.of(context).closeButtonTooltip,
                iconSize: 18,
                onTap: () => context.pop(),
              ),
            ],
          );
    final header = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: widget.asTab
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: Volt.line)),
            ),
      child: GapCol(
        cross: CrossAxisAlignment.stretch,
        children: [
          titleRow,
          MethodRow(methods: methods, current: _mode, onPick: _pickMode),
          if (_mode == 'search') ...[
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(13), border: Volt.edge),
              child: Row(
                children: [
                  VIcon('search', size: 18, color: Volt.t3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _q,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(fontSize: 15, color: Volt.t1),
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

    final heard = _textFrom == 'voice' && _log.text.trim().isNotEmpty;
    final rows = _log.text.trim().isEmpty
        ? null
        : WrittenRows(
            items: _written,
            dropped: _dropped,
            onDrop: (i) => setState(() => _dropped.add(i)),
            onSearch: _findWritten,
            onEstimate: _estimateWritten,
            onAskAll: _askAll,
            asking: _asking,
            onEdit: _editWritten,
          );
    final List<Widget> body;
    if (_mode == 'write') {
      body = [
        AskIron(
          question: l.ironQFood,
          controller: _log,
          onChanged: _onLogChanged,
          hint: l.writeHint,
          minLines: 4,
          maxLines: null,
        ),
        rows ?? const WriteEmpty(),
      ];
    } else if (_mode == 'voice') {
      body = [
        VCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
          child: GapCol(
            gap: 14,
            cross: CrossAxisAlignment.center,
            children: [
              MicButton(listening: _listening, onStart: _listen, onStop: _stopListening),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Muted(
                  _micOk == false
                      ? l.voiceUnavailable
                      : _listening
                      ? l.voiceListening
                      : heard
                      ? l.voiceHeard
                      : l.voiceHold,
                  align: TextAlign.center,
                  color: _micOk == false ? Volt.warn : null,
                ),
              ),
            ],
          ),
        ),
        if (heard) ...[
          GapCol(
            gap: 8,
            cross: CrossAxisAlignment.stretch,
            children: [
              Eyebrow(l.transcriptLbl, padding: const EdgeInsetsDirectional.only(start: 4)),
              LogArea(controller: _log, onChanged: _onLogChanged, rows: 3),
            ],
          ),
          ?rows,
        ],
      ];
    } else if (_mode == 'eatout') {
      body = [
        EatOutMode(
          meal: _meal,
          onDone: (n) {
            showVToast(context, l.itemsLoggedTo(n, mealName(l, _meal).toLowerCase()));
            context.go('/meal/${_meal.name}');
          },
        ),
      ];
    } else if (_mode == 'camera') {
      body = [
        PhotoMode(
          meal: _meal,
          onSearch: _findByName,
          onDone: (n) {
            showVToast(context, l.itemsLoggedTo(n, mealName(l, _meal).toLowerCase()));
            context.go('/meal/${_meal.name}');
          },
        ),
      ];
    } else if (q.isEmpty && _shelf == 1) {
      body = _savedMeals(l);
    } else if (q.isEmpty && _shelf == 2) {
      body = _recipes(l);
    } else if (q.isEmpty && _shelf == 3) {
      final custom = ref.watch(customFoodsProvider).value ?? const <Food>[];
      body = custom.isEmpty
          ? [_Shelf(text: l.noCustomFoods)]
          : [
              VList(
                children: [
                  for (final f in custom)
                    _FoodItem(food: f, on: _picks.any((p) => p.id == f.id), onTap: () => _toggle(f)),
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
              VIcon('wifioff', size: 16, color: Volt.warn),
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
              for (final f in results) _FoodItem(food: f, on: _picks.any((p) => p.id == f.id), onTap: () => _toggle(f)),
            ],
          ),
      ];
    }

    final pickKcal = _picks.fold<double>(0, (s, f) => s + f.kcal * (f.servingGrams ?? 150) / 100);
    final pickP = _picks.fold<double>(0, (s, f) => s + f.protein * (f.servingGrams ?? 150) / 100);

    final toAdd = (_mode == 'write' || (_mode == 'voice' && heard)) ? _toAdd : const <WrittenItem>[];
    final wk = toAdd.fold<double>(0, (s, it) => s + it.kcal);
    final screen = VScreen(
      overlays: [
        if (toAdd.isNotEmpty)
          LogBar(
            aboveTabs: widget.asTab,
            children: [
              Expanded(
                child: GapCol(
                  gap: 1,
                  children: [
                    Text(l.kcalChange(fmtInt(context, wk)), style: numStyle(22, weight: FontWeight.w800)),
                    Text(
                      l.pcfLine(
                        fmtInt(context, toAdd.fold<double>(0, (s, it) => s + it.protein)),
                        fmtInt(context, toAdd.fold<double>(0, (s, it) => s + it.carbs)),
                        fmtInt(context, toAdd.fold<double>(0, (s, it) => s + it.fat)),
                      ),
                      style: numStyle(15, weight: FontWeight.w500, color: Volt.t2),
                    ),
                  ],
                ),
              ),
              VBtn(
                label: l.addN(toAdd.length),
                minHeight: 54,
                fontSize: 17,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                onTap: _addWritten,
              ),
            ],
          ),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                    Text(
                      l.kcalAndProtein(fmtInt(context, pickKcal), fmtInt(context, pickP)),
                      style: numStyle(17, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              VBtn(
                label: l.logN(_picks.length),
                minHeight: 54,
                fontSize: 17,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                onTap: _logPicks,
              ),
            ],
          ),
      ],
      child: Column(
        children: [
          header,
          Expanded(
            child: Pad(
              top: 12,
              bottom: _picks.isNotEmpty || toAdd.isNotEmpty ? 168 : (widget.asTab ? 116 : 24),
              children: body,
            ),
          ),
        ],
      ),
    );
    return widget.asTab ? screen : Scaffold(body: screen);
  }
}

class _FoodItem extends StatelessWidget {
  const _FoodItem({required this.food, required this.on, required this.onTap});
  final Food food;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final g = food.servingGrams ?? 150;
    final brand =
        food.brand ??
        (food.source == 'usda' ? l.genericUsda : (food.source == 'pack' ? l.packFoodLabel : l.customFood));
    return VItem(
      color: on ? Volt.brandWash : null,
      onTap: onTap,
      semantics: foodName(context, food.id, food.name),
      children: [
        ItemText(
          foodName(context, food.id, food.name),
          sub: '$brand · ${fmtInt(context, g)} ${l.grams} · ${fmtInt(context, food.kcal * g / 100)} ${l.kcal}',
          trailingName: food.verified ? VIcon('check', size: 14, color: Volt.blue) : null,
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
    child: Text(text, style: TextStyle(fontSize: 14, height: 1.45, color: Volt.t3)),
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
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
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
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
                        ),
                        Muted(l.barcodeMissBody),
                      ],
                    ),
                  ),
                  Consumer(
                    builder: (_, ref, _) => ref.watch(remoteConfigProvider).barcodeContribute
                        ? VBtn(
                            label: l.contributeOff,
                            trailingIcon: 'fwd',
                            onTap: () => launchUrl(openFoodFactsAddUrl(code), mode: LaunchMode.externalApplication),
                          )
                        : const SizedBox.shrink(),
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
