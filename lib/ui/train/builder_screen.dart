import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/local_db.dart';
import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'exercise_photo.dart';
import 'train_kit.dart';

/// The rep ranges the builder offers, as (low, high).
const repRanges = [(3, 5), (5, 8), (6, 8), (6, 10), (8, 10), (8, 12), (10, 12), (10, 15), (12, 15), (15, 20), (20, 30)];
const builderRests = [45, 60, 90, 120, 150, 180, 210, 240];

/// New routine when [routineId] is null, else edit that one. [seed] starts a
/// new one from a finished workout.
class BuilderScreen extends ConsumerStatefulWidget {
  const BuilderScreen({super.key, this.routineId, this.folder = RoutineFolder.plan, this.seed});
  final int? routineId;
  final RoutineFolder folder;
  final Routine? seed;

  @override
  ConsumerState<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends ConsumerState<BuilderScreen> {
  final _name = TextEditingController();
  late RoutineFolder _folder = widget.seed?.folder ?? widget.folder;
  Set<int> _days = {};
  List<RoutineItem> _items = [];
  Routine? _editing;
  bool _loaded = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final s = widget.seed;
    if (s != null) {
      _name.text = s.name;
      _items = [...s.items];
      _days = {...s.days};
      _dirty = true;
    }
    _name.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _load(List<Routine> all) {
    if (_loaded || widget.routineId == null) return;
    final r = all.where((r) => r.id == widget.routineId).firstOrNull;
    if (r == null) return;
    _loaded = true;
    _editing = r;
    _name.text = r.name;
    _items = [...r.items];
    _days = {...r.days};
    _folder = r.folder;
    _dirty = false;
  }

  void _edit(void Function() f) => setState(() {
    f();
    _dirty = true;
  });

  Future<void> _add() async {
    final picked = await context.push<List<Exercise>>('/exercises/pick');
    if (picked == null) return;
    _edit(
      () => _items = [
        ..._items,
        for (final e in picked) RoutineItem(exerciseId: e.id, sets: 3, repLow: 8, repHigh: 12, restSeconds: 150),
      ],
    );
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    try {
      await ref
          .read(routineActionsProvider)
          .save(Routine(id: _editing?.id, name: _name.text.trim(), items: _items, days: _days, folder: _folder));
      if (!mounted) return;
      showVToast(context, l.routineSaved(_name.text.trim()));
      context.pop();
    } on DuplicateNameException {
      setState(() {});
    }
  }

  Future<void> _leave() async {
    if (!_dirty) return context.pop();
    final l = AppLocalizations.of(context);
    await showVSheet<void>(
      context,
      title: l.leaveTitle,
      body: (ctx) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Muted(_editing != null ? l.leaveEditing(_editing!.name) : l.leaveNew),
        ),
        SRow(label: l.keepEditing, onTap: () => Navigator.pop(ctx)),
        SRow(
          label: l.discardShort,
          tint: Volt.brandInk,
          onTap: () {
            Navigator.pop(ctx);
            context.pop();
          },
        ),
      ],
    );
  }

  void _repsSheet(int i, String name) {
    final l = AppLocalizations.of(context);
    final it = _items[i];
    showVSheet<void>(
      context,
      title: l.repRangeTitle(name),
      body: (ctx) => [
        RGrid(
          columns: 3,
          children: [
            for (final (lo, hi) in repRanges)
              RChip(
                label: ltr('$lo–$hi'),
                on: it.repLow == lo && it.repHigh == hi,
                onTap: () {
                  Navigator.pop(ctx);
                  _edit(() => _items[i] = it.copyWith(repLow: lo, repHigh: hi));
                },
              ),
          ],
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.repRangeNote)),
      ],
    );
  }

  void _restSheet(int i, String name) {
    final l = AppLocalizations.of(context);
    final it = _items[i];
    showVSheet<void>(
      context,
      title: l.restBetween(name),
      body: (ctx) => [
        RGrid(
          children: [
            for (final s in builderRests)
              RChip(
                label: fmtRest(s),
                on: it.restSeconds == s,
                onTap: () {
                  Navigator.pop(ctx);
                  _edit(() => _items[i] = it.copyWith(restSeconds: s));
                },
              ),
          ],
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.restBetweenNote)),
      ],
    );
  }

  void _itemSheet(int i, String name) {
    final l = AppLocalizations.of(context);
    final it = _items[i];
    void move(int d) => _edit(() {
      final x = _items.removeAt(i);
      _items.insert(i + d, x);
    });
    showVSheet<void>(
      context,
      title: name,
      body: (ctx) => [
        if (i > 0)
          SRow(
            label: l.moveUp,
            onTap: () {
              Navigator.pop(ctx);
              move(-1);
            },
          ),
        if (i < _items.length - 1)
          SRow(
            label: l.moveDown,
            onTap: () {
              Navigator.pop(ctx);
              move(1);
            },
          ),
        SRow(
          label: l.repRangeLbl,
          sub: l.repsChip(ltr(it.reps)),
          onTap: () {
            Navigator.pop(ctx);
            _repsSheet(i, name);
          },
        ),
        SRow(
          label: l.restLabel,
          sub: l.restBetweenSub(fmtRest(it.restSeconds)),
          onTap: () {
            Navigator.pop(ctx);
            _restSheet(i, name);
          },
        ),
        SRow(
          label: l.removeFromRoutine,
          tint: Volt.brandInk,
          onTap: () {
            Navigator.pop(ctx);
            _edit(() => _items.removeAt(i));
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    _load(routines);
    final lib = ref.watch(exerciseLibraryProvider).value;
    final name = _name.text.trim();
    final dupe =
        name.isNotEmpty && routines.any((r) => r.name.toLowerCase() == name.toLowerCase() && r.id != _editing?.id);
    final draft = Routine(id: null, name: name, items: _items);
    final minutes = routineMinutes(draft);
    final (ok, hint) = name.isEmpty
        ? (false, l.hintName)
        : dupe
        ? (false, l.hintTaken)
        : _items.isEmpty
        ? (false, l.hintExercise)
        : (true, l.setsAbout(draft.totalSets, minutes));
    Routine? taken(int w) => routines.where((r) => r.days.contains(w) && r.id != _editing?.id).firstOrNull;
    final clash = [
      for (final w in _days)
        if (taken(w) case final r?) (w, r),
    ].firstOrNull;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (did, _) {
        if (!did) _leave();
      },
      child: Scaffold(
        body: VScreen(
          overlays: [
            LogBar(
              aboveTabs: false,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              children: [
                Expanded(child: Muted(hint)),
                VBtn(
                  label: l.saveRoutine,
                  small: true,
                  minHeight: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  onTap: ok ? _save : null,
                ),
              ],
            ),
          ],
          child: Column(
            children: [
              BackBar(
                title: _editing != null ? l.editRoutine : l.newRoutine,
                sub: _items.isEmpty ? l.nothingYet : l.builderSub(_items.length, draft.totalSets, minutes),
                icon: 'close',
                backLabel: MaterialLocalizations.of(context).closeButtonTooltip,
                onBack: _leave,
                right: VBtn(
                  label: l.save,
                  small: true,
                  minHeight: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: ok ? _save : null,
                ),
              ),
              Expanded(
                child: Pad(
                  bottom: 156,
                  children: [
                    GapCol(
                      gap: 8,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Eyebrow(l.nameLbl, padding: const EdgeInsetsDirectional.only(start: 4)),
                        TextField(
                          controller: _name,
                          maxLength: 40,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: l.namePlaceholder,
                            hintStyle: const TextStyle(color: Volt.t4, fontWeight: FontWeight.w400),
                            filled: true,
                            fillColor: Volt.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: dupe ? Volt.warn : Volt.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(color: dupe ? Volt.warn : Volt.brand),
                            ),
                          ),
                        ),
                        if (dupe)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(start: 4),
                            child: Muted(l.nameTaken(name), color: Volt.warn),
                          ),
                      ],
                    ),
                    GapCol(
                      gap: 8,
                      children: [
                        Eyebrow(l.folderLbl, padding: const EdgeInsetsDirectional.only(start: 4)),
                        Wrap(
                          spacing: 8,
                          children: [
                            VChip(
                              label: l.folderPlan,
                              on: _folder == RoutineFolder.plan,
                              onTap: () => _edit(() => _folder = RoutineFolder.plan),
                            ),
                            VChip(
                              label: l.folderMine,
                              on: _folder == RoutineFolder.mine,
                              onTap: () => _edit(() => _folder = RoutineFolder.mine),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GapCol(
                      gap: 8,
                      children: [
                        Eyebrow(l.dayLbl, padding: const EdgeInsetsDirectional.only(start: 4)),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (var w = 0; w < 7; w++)
                              Semantics(
                                label: taken(w) == null
                                    ? weekdayName(context, w)
                                    : l.dayTakenBy(weekdayName(context, w), taken(w)!.name),
                                child: VChip(
                                  label: weekdayShort(context, w),
                                  on: _days.contains(w),
                                  // Several days: tap each one it runs on.
                                  onTap: () => _edit(() => _days.contains(w) ? _days.remove(w) : _days.add(w)),
                                ),
                              ),
                            VChip(label: l.anyDay, on: _days.isEmpty, onTap: () => _edit(() => _days = {})),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 4),
                          child: Muted(
                            clash != null
                                ? l.dayTaken(clash.$2.name, weekdayName(context, clash.$1))
                                : (_days.isEmpty ? l.anyDayNote : l.dayNoteMulti),
                          ),
                        ),
                      ],
                    ),
                    Eyebrow(l.exercisesLbl, padding: const EdgeInsetsDirectional.only(start: 4)),
                    if (_items.isEmpty) DumbbellEmpty(text: l.builderEmpty),
                    for (final (i, it) in _items.indexed) _itemCard(context, i, it, lib?[it.exerciseId]),
                    VBtn(
                      label: l.addExercise,
                      kind: BtnKind.ghost,
                      icon: 'plus',
                      expand: true,
                      color: Volt.brandInk,
                      onTap: _add,
                    ),
                    VolumeCard(
                      items: [
                        for (final _ in _days.isEmpty ? const {0} : _days) ..._items,
                      ],
                      title: l.weekIfSave,
                      exceptRoutineId: _editing?.id,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemCard(BuildContext context, int i, RoutineItem it, Exercise? e) {
    final l = AppLocalizations.of(context);
    final name = e?.name ?? it.exerciseId;
    final short = e?.shortName ?? name;
    return VCard(
      padding: const EdgeInsets.all(12),
      child: GapCol(
        gap: 10,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExThumb(e, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: GapCol(
                  gap: 2,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                    ),
                    if (e != null) Muted(muscleLine(l, e)),
                  ],
                ),
              ),
              IconBtn(
                'more',
                label: l.optionsFor(name),
                size: 32,
                iconSize: 18,
                background: Colors.transparent,
                color: Volt.t3,
                onTap: () => _itemSheet(i, name),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              VStepper(
                label: l.setsCount(it.sets),
                minusLabel: l.oneSetFewer,
                plusLabel: l.oneSetMore,
                onMinus: it.sets <= 1 ? null : () => _edit(() => _items[i] = it.copyWith(sets: it.sets - 1)),
                onPlus: it.sets >= 8 ? null : () => _edit(() => _items[i] = it.copyWith(sets: it.sets + 1)),
              ),
              VChip(label: l.repsChip(ltr(it.reps)), height: 32, color: Volt.card2, onTap: () => _repsSheet(i, short)),
              VChip(
                label: l.restChip(fmtRest(it.restSeconds)),
                height: 32,
                color: Volt.card2,
                onTap: () => _restSheet(i, short),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
