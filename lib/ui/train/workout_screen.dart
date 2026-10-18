import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../data/training.dart';
import '../../domain/session.dart';
import '../../domain/workout.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'exercise_photo.dart';
import 'swap_pain.dart';
import 'train_kit.dart';

const workoutRests = [0, 60, 90, 120, 150, 180, 240, 300];

/// The live session. Everything is drawn from the session's own
/// timestamps; a once-a-second tick only asks for a repaint.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Timer? _tick;
  bool _restWasRunning = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  ActiveWorkoutNotifier get _n => ref.read(activeWorkoutProvider.notifier);

  Future<void> _addExercises() async {
    final picked = await context.push<List<Exercise>>('/exercises/pick');
    if (picked != null && picked.isNotEmpty) {
      await _n.addExercises(picked);
      if (mounted) showVToast(context, AppLocalizations.of(context).exAdded(picked.first.shortName));
    }
  }

  Future<void> _finish(WorkoutSession s) async {
    final l = AppLocalizations.of(context);
    final unticked = s.setsPlanned - s.setsDone;
    final done = await _n.finish();
    if (!mounted || done == null) return;
    if (done.session.isEmpty) {
      showVToast(context, l.nothingTicked, info: true);
      return context.pop();
    }
    context.pushReplacement('/summary', extra: done);
    if (unticked > 0) showVToast(context, l.setsUnticked(unticked), info: true);
  }

  void _discard() {
    final l = AppLocalizations.of(context);
    showVSheet<void>(
      context,
      title: l.discardTitle,
      body: (ctx) => [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.discardBody)),
        SRow(label: l.keepGoing, onTap: () => Navigator.pop(ctx)),
        SRow(
          label: l.discard,
          tint: Volt.brandInk,
          onTap: () {
            Navigator.pop(ctx);
            _n.discard();
            showVToast(context, l.workoutDiscarded, info: true);
            context.pop();
          },
        ),
      ],
    );
  }

  void restSheet(int ex) {
    final l = AppLocalizations.of(context);
    final s = ref.read(activeWorkoutProvider);
    if (s == null || ex >= s.exercises.length) return;
    final e = s.exercises[ex];
    final name = ref.read(exerciseLibraryProvider).value?[e.exerciseId]?.shortName ?? e.name;
    showVSheet<void>(
      context,
      title: l.restAfterEachTitle(name),
      body: (ctx) => [
        RGrid(
          children: [
            for (final r in workoutRests)
              RChip(
                label: r == 0 ? l.offLbl : fmtRest(r),
                on: e.restSeconds == r,
                onTap: () {
                  Navigator.pop(ctx);
                  _n.update((x, _) => x.setRest(ex, r));
                },
              ),
          ],
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.restNote)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(activeWorkoutProvider);
    final now = ref.watch(clockProvider)();
    if (s == null) return const Scaffold(body: VScreen(child: SizedBox.shrink()));

    final restLeft = s.restLeft(now);
    if (_restWasRunning && restLeft == null) HapticFeedback.heavyImpact();
    _restWasRunning = restLeft != null;
    final clock = fmtClock(s.elapsed(now));

    final cards = <Widget>[];
    for (var i = 0; i < s.exercises.length; i++) {
      final e = s.exercises[i];
      final pairStart = e.linkNext && (i == 0 || !s.exercises[i - 1].linkNext);
      if (pairStart && i + 1 < s.exercises.length) {
        // A superset: this one and every linked one after it, in a violet group.
        final group = <int>[i];
        var j = i;
        while (j + 1 < s.exercises.length && s.exercises[j].linkNext) {
          group.add(++j);
        }
        cards.add(_Superset(indices: group, onUnlink: () => _n.update((x, _) => x.link(i, false)), host: this));
        i = j;
      } else {
        cards.add(_ExerciseCard(index: i, host: this));
      }
    }

    return Scaffold(
      body: VScreen(
        overlays: [
          if (restLeft != null)
            _RestBar(
              left: restLeft,
              total: s.restSeconds ?? restLeft,
              label: _nextLabel(l, s),
              onMinus: () => _n.update((x, _) => x.adjustRest(-15)),
              onSkip: () => _n.update((x, _) => x.skipRest()),
            ),
        ],
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
              child: Row(
                children: [
                  IconBtn('down', small: true, iconSize: 18, label: l.minimise, onTap: () => context.pop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GapCol(
                      gap: 1,
                      children: [
                        Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                        ),
                        Text(clock, style: numStyle(12.5, color: Volt.brandInk)),
                      ],
                    ),
                  ),
                  IconBtn('clock', small: true, iconSize: 18, label: l.restTimer, onTap: () => restSheet(0)),
                  const SizedBox(width: 10),
                  VBtn(
                    label: l.finish,
                    small: true,
                    minHeight: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onTap: () => _finish(s),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  for (final (k, v) in [
                    (l.durationLbl, clock),
                    (l.volumeLbl, '${fmtInt(context, s.volume)} ${l.kgLbl}'),
                    (l.setsDoneLbl, '${s.setsDone} / ${s.setsPlanned}'),
                  ])
                    Expanded(
                      child: GapCol(
                        gap: 2,
                        children: [
                          Eyebrow(k),
                          Text(v, textDirection: TextDirection.ltr, style: numStyle(16)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Pad(
                top: 12,
                bottom: restLeft != null ? 130 : 40,
                children: [
                  if (s.exercises.isEmpty) DumbbellEmpty(text: l.emptyWorkoutBody),
                  ...cards,
                  VBtn(
                    label: l.addExercise,
                    kind: BtnKind.ghost,
                    icon: 'plus',
                    expand: true,
                    color: Volt.brandInk,
                    onTap: _addExercises,
                  ),
                  VBtn(
                    label: l.discard,
                    kind: BtnKind.ghost,
                    small: true,
                    expand: true,
                    color: Volt.brandInk,
                    onTap: _discard,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextLabel(AppLocalizations l, WorkoutSession s) {
    final lib = ref.read(exerciseLibraryProvider).value;
    final n = s.nextSet;
    if (n == null) return l.lastSetDone;
    final e = s.exercises[n.$1];
    final name = lib?[e.exerciseId]?.shortName ?? e.name;
    // A fresh exercise is announced by name; within one, by set.
    return e.sets.any((x) => x.done) ? l.nextSetOf(name, n.$2 + 1) : l.thenEx(name);
  }
}

/// Several exercises run back to back with no rest between.
class _Superset extends StatelessWidget {
  const _Superset({required this.indices, required this.onUnlink, required this.host});
  final List<int> indices;
  final VoidCallback onUnlink;
  final _WorkoutScreenState host;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Color.alphaBlend(Volt.violet.withValues(alpha: 0.08), Volt.bg),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Volt.line2, width: 1.5),
      ),
      child: GapCol(
        gap: 8,
        cross: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Volt.violet, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    'A',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Eyebrow(l.supersetBadge, color: Volt.violet)),
                VChip(label: l.unlink, height: 26, onTap: onUnlink),
              ],
            ),
          ),
          for (final i in indices) _ExerciseCard(index: i, host: host),
          Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 2), child: Muted(l.supersetNote)),
        ],
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.index, required this.host});
  final int index;
  final _WorkoutScreenState host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(activeWorkoutProvider)!;
    final e = s.exercises[index];
    final ex = ref.watch(exerciseLibraryProvider).value?[e.exerciseId];
    final n = ref.read(activeWorkoutProvider.notifier);
    final name = ex?.name ?? e.name;
    var counted = 0;

    void options() => showVSheet<void>(
      context,
      title: name,
      body: (ctx) => [
        SRow(
          label: l.restTimer,
          sub: e.restSeconds == 0 ? l.restOffFor : l.restAfterEach(fmtRest(e.restSeconds)),
          onTap: () {
            Navigator.pop(ctx);
            host.restSheet(index);
          },
        ),
        if (!e.linkNext)
          SRow(
            label: l.supersetNext,
            sub: l.supersetNextSub,
            onTap: () {
              Navigator.pop(ctx);
              if (index >= s.exercises.length - 1) {
                showVToast(context, l.nothingAfter, info: true);
              } else {
                n.update((x, _) => x.link(index, true));
                showVToast(context, l.supersetted);
              }
            },
          ),
        SRow(
          label: l.swapExercise,
          sub: l.swapExerciseSub,
          onTap: () {
            Navigator.pop(ctx);
            swapSheet(context, ref, index);
          },
        ),
        SRow(
          label: l.seeHistory,
          onTap: () {
            Navigator.pop(ctx);
            context.push('/exercise/${Uri.encodeComponent(e.exerciseId)}');
          },
        ),
        SRow(
          label: l.removeFromWorkout,
          tint: Volt.brandInk,
          onTap: () {
            Navigator.pop(ctx);
            n.update((x, _) => x.removeExercise(index));
            showVToast(context, l.removedFromWorkout(ex?.shortName ?? e.name));
          },
        ),
      ],
    );

    return VCard(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      child: GapCol(
        gap: 8,
        cross: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExThumb(ex, size: 44),
                const SizedBox(width: 10),
                Expanded(
                  child: GapCol(
                    gap: 2,
                    children: [
                      Pressable(
                        onTap: () => context.push('/exercise/${Uri.encodeComponent(e.exerciseId)}'),
                        scale: 0.99,
                        label: name,
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.brandInk),
                        ),
                      ),
                      if (ex != null) Muted(muscleLine(l, ex)),
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
                  onTap: options,
                ),
              ],
            ),
          ),
          PainReminder(exerciseId: e.exerciseId, today: dayKey(s.startedAt)),
          _Note(index: index, initial: e.note),
          Pressable(
            onTap: () => host.restSheet(index),
            scale: 0.99,
            label: l.restTimer,
            child: _DashedBox(
              child: Row(
                children: [
                  VIcon('clock', size: 16, color: e.restSeconds == 0 ? Volt.t4 : Volt.brandInk),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.restTimer,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Volt.t2),
                    ),
                  ),
                  Text(
                    e.restSeconds == 0 ? l.offLbl : fmtRest(e.restSeconds),
                    style: numStyle(13, color: e.restSeconds == 0 ? Volt.t4 : Volt.t1),
                  ),
                  const SizedBox(width: 6),
                  const VIcon('fwd', size: 15, color: Volt.t2),
                ],
              ),
            ),
          ),
          _SetGrid(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
            cells: [
              Eyebrow(l.setH),
              Eyebrow(l.previous),
              Center(child: Eyebrow(l.kgLbl)),
              Center(child: Eyebrow(l.repsLabel)),
              Center(child: Eyebrow(l.rirLbl)),
              const SizedBox.shrink(),
            ],
          ),
          for (final (i, set) in e.sets.indexed)
            () {
              if (set.type == SetType.normal || set.type == SetType.failure) counted++;
              return _SetRow(index: index, setIndex: i, number: counted, exercise: e, set: set);
            }(),
          Pressable(
            onTap: () => n.update((x, _) => x.addSet(index)),
            label: l.addSet,
            child: Container(
              height: 40,
              margin: const EdgeInsets.fromLTRB(6, 2, 6, 0),
              decoration: BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const VIcon('plus', size: 16, color: Volt.t2),
                  const SizedBox(width: 6),
                  Text(
                    l.addSet,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Volt.t2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.setrow`: 28 / 80 / 1fr / 1fr / 38 / 36, gap 6.
class _SetGrid extends StatelessWidget {
  const _SetGrid({required this.cells, this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6)});
  final List<Widget> cells;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        SizedBox(width: 28, child: cells[0]),
        const SizedBox(width: 6),
        SizedBox(width: 80, child: cells[1]),
        const SizedBox(width: 6),
        Expanded(child: cells[2]),
        const SizedBox(width: 6),
        Expanded(child: cells[3]),
        const SizedBox(width: 6),
        SizedBox(width: 38, child: cells[4]),
        const SizedBox(width: 6),
        SizedBox(width: 36, child: cells[5]),
      ],
    ),
  );
}

class _SetRow extends ConsumerWidget {
  const _SetRow({
    required this.index,
    required this.setIndex,
    required this.number,
    required this.exercise,
    required this.set,
  });
  final int index;
  final int setIndex;
  final int number;
  final SessionExercise exercise;
  final SessionSet set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final n = ref.read(activeWorkoutProvider.notifier);
    final type = set.type;
    final label = _label;
    final typeColor = switch (type) {
      SetType.warmup => Volt.warn,
      SetType.failure => Volt.brandInk,
      SetType.drop => Volt.violet,
      SetType.normal => Volt.t2,
    };
    final prev = exercise.previousOf(setIndex);
    final prevText = prev == null || prev.weightKg == null || prev.reps == null
        ? '—'
        : ltr('${fmtKg(context, prev.weightKg!)} × ${prev.reps}${prev.rir == null ? '' : ' @${prev.rir}'}');
    final (bg, border) = set.done
        ? (Volt.brandWash, null)
        : (type == SetType.warmup ? (Volt.card2, null) : (Volt.bg, Border.all(color: Volt.line2, width: 1.5)));

    Widget num(String text, bool dim, VoidCallback onTap, String semantic) => Pressable(
      onTap: onTap,
      scale: 0.96,
      label: semantic,
      child: SizedBox(
        height: 36,
        child: Center(
          child: Text(text, style: numStyle(15, color: dim ? Volt.t4 : Volt.t1)),
        ),
      ),
    );

    void edit() => editSet(context, ref, index, setIndex, number: label);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: voltEase,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: border),
      child: _SetGrid(
        cells: [
          Pressable(
            onTap: () => _typeSheet(context, ref),
            label: set.pain == null
                ? l.setTypeLabel(_typeName(l, type))
                : '${l.setTypeLabel(_typeName(l, type))}, ${l.painFlaggedOn(painAreaName(l, set.pain!.area))}',
            child: SizedBox(
              height: 26,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Text(
                    label,
                    style: numStyle(12, weight: FontWeight.w700, color: set.pain == null ? typeColor : Volt.warn),
                  ),
                  if (set.pain != null)
                    PositionedDirectional(
                      top: -1,
                      end: 0,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Volt.warn, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Text(
            prevText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: numStyle(11.5, weight: FontWeight.w400, color: Volt.t4),
          ),
          num(
            set.weightKg == null ? '—' : fmtKg(context, set.weightKg!),
            !set.done || set.weightKg == null,
            edit,
            l.kgLbl,
          ),
          num(set.reps == null ? '—' : '${set.reps}', set.reps == null, edit, l.repsLabel),
          Pressable(
            onTap: () => _rirSheet(context, ref),
            label: l.rirLbl,
            child: SizedBox(
              height: 36,
              child: Center(
                child: Text(
                  set.rir == null ? '—' : '${set.rir}',
                  style: numStyle(13, weight: FontWeight.w400, color: Volt.t2),
                ),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Pressable(
              onTap: () {
                if (!set.done && set.weightKg == null) return edit();
                HapticFeedback.lightImpact();
                n.update((x, now) => x.toggleDone(index, setIndex, now));
              },
              label: l.completeSet(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: voltEase,
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: set.done ? Volt.brand : Volt.card2,
                  shape: BoxShape.circle,
                  border: Border.all(color: set.done ? Volt.brand : Volt.line2),
                  boxShadow: set.done
                      ? const [
                          BoxShadow(color: Color(0xB3C6F432), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -6),
                        ]
                      : null,
                ),
                child: Center(child: VIcon('check', size: 15, color: set.done ? Volt.ink : Volt.t1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _label => switch (set.type) {
    SetType.warmup => 'W',
    SetType.drop => 'D',
    SetType.failure => 'F',
    SetType.normal => '$number',
  };

  void _typeSheet(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final n = ref.read(activeWorkoutProvider.notifier);
    showVSheet<void>(
      context,
      title: l.setTypeTitle,
      body: (ctx) => [
        for (final (t, k, color, name, sub) in [
          (SetType.warmup, 'W', Volt.warn, l.stWarmup, l.stWarmupSub),
          (SetType.normal, 'N', Volt.t1, l.stNormal, l.stNormalSub),
          (SetType.failure, 'F', Volt.brandInk, l.stFailure, l.stFailureSub),
          (SetType.drop, 'D', Volt.violet, l.stDrop, l.stDropSub),
        ])
          SRow(
            label: name,
            sub: sub,
            on: set.type == t,
            lead: SizedBox(
              width: 26,
              child: Center(
                child: Text(
                  k,
                  style: numStyle(12, weight: FontWeight.w700, color: color),
                ),
              ),
            ),
            trail: set.type == t ? const VIcon('check', size: 18, color: Volt.brandInk) : null,
            onTap: () {
              Navigator.pop(ctx);
              n.update((x, _) => x.updateSet(index, setIndex, (s) => s.copyWith(type: t)));
            },
          ),
        if (set.pain == null)
          SRow(
            label: l.flagPain,
            sub: l.flagPainSub,
            tint: Volt.warn,
            onTap: () {
              Navigator.pop(ctx);
              painSheet(context, ref, index, setIndex, number: _label);
            },
          )
        else
          SRow(
            label: l.clearPain,
            sub: painAreaName(l, set.pain!.area),
            onTap: () {
              Navigator.pop(ctx);
              n.flagPain(index, setIndex, null);
            },
          ),
        SRow(
          label: l.removeSet,
          tint: Volt.brandInk,
          onTap: () {
            Navigator.pop(ctx);
            n.update((x, _) => x.removeSet(index, setIndex));
            showVToast(context, l.setRemoved);
          },
        ),
      ],
    );
  }

  void _rirSheet(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final n = ref.read(activeWorkoutProvider.notifier);
    showVSheet<void>(
      context,
      title: l.rirTitle,
      body: (ctx) => [
        RGrid(
          columns: 4,
          children: [
            for (final v in [null, 0, 1, 2, 3, 4, 5])
              RChip(
                label: v == null ? '—' : '$v',
                on: set.rir == v,
                onTap: () {
                  Navigator.pop(ctx);
                  n.update((x, _) => x.updateSet(index, setIndex, (s) => s.copyWith(rir: () => v)));
                },
              ),
          ],
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.rirNote)),
      ],
    );
  }
}

String _typeName(AppLocalizations l, SetType t) => switch (t) {
  SetType.warmup => l.stWarmup,
  SetType.normal => l.stNormal,
  SetType.failure => l.stFailure,
  SetType.drop => l.stDrop,
};

/// Weight and reps on the number pad. Saving a set that was not ticked
/// leaves it unticked; the tick stays the user's.
Future<void> editSet(BuildContext context, WidgetRef ref, int ex, int i, {required String number}) {
  final l = AppLocalizations.of(context);
  final s = ref.read(activeWorkoutProvider)!;
  final e = s.exercises[ex];
  final set = e.sets[i];
  final prev = e.previousOf(i);
  final lib = ref.read(exerciseLibraryProvider).value;
  final decimal = fmtDec(context, 1.5).contains(',') ? ',' : '.';
  String show(double v) => fmtKg(context, v).replaceAll(RegExp('[^0-9,.]'), '');
  var kg = set.weightKg == null ? (prev?.weightKg == null ? '' : show(prev!.weightKg!)) : show(set.weightKg!);
  var reps = set.reps == null ? (prev?.reps?.toString() ?? e.repLow?.toString() ?? '') : '${set.reps}';
  var field = 0;
  return showVSheet<void>(
    context,
    title: l.editSetTitle(number, lib?[e.exerciseId]?.shortName ?? e.name),
    body: (ctx) => [
      StatefulBuilder(
        builder: (ctx, setState) {
          void key(String k) => setState(() {
            var v = field == 0 ? kg : reps;
            if (k == 'del') {
              v = v.isEmpty ? v : v.substring(0, v.length - 1);
            } else if (k == decimal) {
              if (field == 0 && !v.contains(decimal)) v = v.isEmpty ? '0$decimal' : '$v$decimal';
            } else if (v.length < 6) {
              v = v == '0' ? k : v + k;
            }
            field == 0 ? kg = v : reps = v;
          });
          Widget box(int f, String label, String value) => Expanded(
            child: Pressable(
              onTap: () => setState(() => field = f),
              label: label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Volt.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: field == f ? Volt.brand : Volt.line, width: field == f ? 1.5 : 1),
                ),
                child: GapCol(
                  gap: 2,
                  children: [
                    Eyebrow(label, color: field == f ? Volt.brandInk : Volt.t3),
                    Text(value.isEmpty ? '—' : value, style: numStyle(30, height: 1.1)),
                  ],
                ),
              ),
            ),
          );
          return GapCol(
            gap: 12,
            cross: CrossAxisAlignment.stretch,
            children: [
              Row(children: [box(0, l.kgLbl, kg), const SizedBox(width: 10), box(1, l.repsLabel, reps)]),
              if (prev != null && prev.weightKg != null && prev.reps != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Muted(l.lastTimeSet(ltr('${fmtKg(context, prev.weightKg!)} × ${prev.reps}'))),
                ),
              Keypad(onKey: key, decimal: decimal, deleteLabel: l.deleteDigit),
              VBtn(
                label: l.doneBtn,
                expand: true,
                onTap: () {
                  final w = double.tryParse(kg.replaceAll(',', '.'));
                  final r = int.tryParse(reps);
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .update((x, _) => x.editSet(ex, i, weightKg: w, reps: r == 0 ? null : r));
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _Note extends ConsumerStatefulWidget {
  const _Note({required this.index, required this.initial});
  final int index;
  final String initial;

  @override
  ConsumerState<_Note> createState() => _NoteState();
}

class _NoteState extends ConsumerState<_Note> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: _c,
        style: const TextStyle(fontSize: 13, color: Volt.t1),
        onChanged: (v) => ref.read(activeWorkoutProvider.notifier).update((x, _) => x.setNote(widget.index, v)),
        decoration: InputDecoration(
          isDense: true,
          hintText: l.notePlaceholder,
          hintStyle: const TextStyle(fontSize: 13, color: Volt.t4),
          filled: true,
          fillColor: Volt.card2,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Volt.line2),
          ),
        ),
      ),
    );
  }
}

class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: CustomPaint(
      painter: _Dashes(),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: child),
    ),
  );
}

class _Dashes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), const Radius.circular(12)));
    final p = Paint()
      ..color = Volt.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), p);
      }
    }
  }

  @override
  bool shouldRepaint(_Dashes old) => false;
}

/// The rest timer only takes up room while it runs.
class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.left,
    required this.total,
    required this.label,
    required this.onMinus,
    required this.onSkip,
  });
  final int left;
  final int total;
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PositionedDirectional(
      start: 14,
      end: 14,
      bottom: 14 + MediaQuery.paddingOf(context).bottom,
      child: Semantics(
        liveRegion: true,
        label: l.restingFor(fmtRest(left)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
          decoration: BoxDecoration(
            gradient: Volt.glow,
            borderRadius: BorderRadius.circular(Volt.rCard),
            boxShadow: const [
              BoxShadow(color: Color(0x8CC6F432), blurRadius: 34, offset: Offset(0, 14), spreadRadius: -12),
              BoxShadow(color: Color(0xCC000000), blurRadius: 30, offset: Offset(0, 18), spreadRadius: -16),
            ],
          ),
          child: GapCol(
            gap: 12,
            cross: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GapCol(
                      gap: 2,
                      children: [
                        Row(
                          children: [
                            const VIcon('clock', size: 14, color: Color(0xB30A0B09)),
                            const SizedBox(width: 6),
                            Eyebrow(l.resting, color: const Color(0xB30A0B09)),
                          ],
                        ),
                        Text(
                          fmtRest(left),
                          style: numStyle(52, weight: FontWeight.w700, color: Volt.ink, height: 1.05),
                        ),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xB30A0B09)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BarBtn(label: l.minus15, onTap: onMinus),
                        const SizedBox(height: 8),
                        _BarBtn(label: l.skip, onTap: onSkip, solid: true),
                      ],
                    ),
                  ),
                ],
              ),
              VBar(fraction: total == 0 ? 0 : left / total, color: Volt.ink, height: 8, track: const Color(0x2E0A0B09)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The rest bar's buttons: ink-tinted, or solid ink for the main one.
class _BarBtn extends StatelessWidget {
  const _BarBtn({required this.label, required this.onTap, this.solid = false});
  final String label;
  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    child: Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: solid ? Volt.ink : const Color(0x1F0A0B09),
        borderRadius: BorderRadius.circular(999),
        border: solid ? null : Border.all(color: const Color(0x400A0B09)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: solid ? Volt.brand : Volt.ink),
      ),
    ),
  );
}
