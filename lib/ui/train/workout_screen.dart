import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/training.dart';
import '../../domain/session.dart';
import '../../domain/workout.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

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
    // The clock and the rest timer are drawn from the session's timestamps;
    // this only asks for a repaint once a second.
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
    if (picked != null) _n.addExercises(picked);
  }

  Future<bool> _confirm(String title, String body, String yes, String no) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Volt.card,
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(no)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _finish(WorkoutSession s) async {
    final l = AppLocalizations.of(context);
    if (s.hasUnfinishedSets && !s.isEmpty) {
      if (!await _confirm(l.unfinishedTitle, l.unfinishedBody, l.finishAnyway, l.keepGoing)) return;
    }
    final done = await _n.finish();
    if (!mounted || done == null) return;
    if (!done.session.isEmpty) await _summary(done);
    if (mounted) context.pop();
  }

  Future<void> _discard() async {
    final l = AppLocalizations.of(context);
    if (await _confirm(l.discardTitle, l.discardBody, l.discard, l.keepGoing)) {
      _n.discard();
      if (mounted) context.pop();
    }
  }

  Future<void> _summary(FinishedWorkout f) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final names = {for (final e in f.session.exercises) e.exerciseId: e.name};
    // Everything the sheet shows is worked out here: the workout screen
    // closes while the sheet animates away, so the sheet must not reach back.
    final time = fmtClock(f.endedAt.difference(f.session.startedAt));
    final volume = '${fmtInt(context, f.session.volume)} ${l.kgLbl}';
    final bests = [
      for (final b in f.bests.entries) (l.newBest(names[b.key] ?? b.key), l.estOneRm(fmtDec(context, b.value))),
    ];
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
              AccentTitle(template: '{accent}', accent: l.summaryTitle, size: 26),
              const SizedBox(height: 16),
              _Stats(time: time, volume: volume, sets: '${f.session.setsDone}'),
              for (final (title, sub) in bests) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined, color: Volt.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: t.titleMedium),
                          Text(sub, style: t.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GlowButton(label: l.doneBtn, onPressed: () => Navigator.pop(ctx)),
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
    final s = ref.watch(activeWorkoutProvider);
    final now = ref.watch(clockProvider)();

    if (s == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final restLeft = s.restLeft(now);
    if (_restWasRunning && restLeft == null) HapticFeedback.heavyImpact();
    _restWasRunning = restLeft != null;

    return Scaffold(
      body: VoltBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                    ),
                    Expanded(
                      child: Text(s.name, style: t.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      color: Volt.card2,
                      onSelected: (_) => _discard(),
                      itemBuilder: (_) => [PopupMenuItem(value: 'discard', child: Text(l.discard))],
                    ),
                    GlowButton(label: l.finish, onPressed: () => _finish(s)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _Stats(
                  time: fmtClock(s.elapsed(now)),
                  volume: '${fmtInt(context, s.volume)} ${l.kgLbl}',
                  sets: '${s.setsDone} / ${s.setsPlanned}',
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                  children: [
                    if (s.exercises.isEmpty) VoltCard(child: Text(l.startWorkoutHint, style: t.bodyMedium)),
                    for (var ex = 0; ex < s.exercises.length; ex++) ...[
                      _ExerciseCard(index: ex, exercise: s.exercises[ex]),
                      const SizedBox(height: 12),
                    ],
                    GhostButton(label: l.addExercise, icon: Icons.add_rounded, onPressed: _addExercises),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: restLeft == null
          ? null
          : _RestBar(
              left: restLeft,
              total: s.restSeconds ?? restLeft,
              onMinus: () => _n.update((x, _) => x.adjustRest(-15)),
              onPlus: () => _n.update((x, _) => x.adjustRest(15)),
              onSkip: () => _n.update((x, _) => x.skipRest()),
            ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.time, required this.volume, required this.sets});
  final String time;
  final String volume;
  final String sets;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget stat(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(Volt.rRow)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.bodySmall),
            Text(value, style: t.titleMedium, maxLines: 1),
          ],
        ),
      ),
    );
    return Row(
      children: [
        stat(l.durationLbl, time),
        const SizedBox(width: 8),
        stat(l.volumeLbl, volume),
        const SizedBox(width: 8),
        stat(l.setsDoneLbl, sets),
      ],
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.index, required this.exercise});
  final int index;
  final SessionExercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final n = ref.read(activeWorkoutProvider.notifier);
    final prev = ref.watch(lastSetsProvider(exercise.exerciseId)).value ?? const <SessionSet>[];

    var working = 0;
    return VoltCard(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/exercise/${Uri.encodeComponent(exercise.exerciseId)}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(exercise.name, style: t.titleMedium?.copyWith(color: Volt.brandInk)),
                        if (exercise.repLow != null)
                          Text(
                            '${l.repRange(exercise.repLow!, exercise.repHigh!)} · ${l.restSeconds(exercise.restSeconds)}',
                            style: t.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Volt.t3),
                color: Volt.card2,
                onSelected: (_) => n.update((s, _) => s.removeExercise(index)),
                itemBuilder: (_) => [PopupMenuItem(value: 'remove', child: Text(l.removeExercise))],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(flex: 3, child: Text(l.previous, style: t.bodySmall)),
                Expanded(
                  flex: 2,
                  child: Text(l.kgLbl, style: t.bodySmall, textAlign: TextAlign.center),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l.repsLbl, style: t.bodySmall, textAlign: TextAlign.center),
                ),
                const SizedBox(width: 52),
              ],
            ),
          ),
          for (var i = 0; i < exercise.sets.length; i++)
            _SetRow(
              key: ValueKey('${exercise.exerciseId}-$index-$i'),
              exIndex: index,
              setIndex: i,
              set: exercise.sets[i],
              label: switch (exercise.sets[i].type) {
                SetType.warmup => 'W',
                SetType.failure => 'F',
                SetType.drop => 'D',
                SetType.normal => '${++working}',
              },
              previous: i < prev.length ? prev[i] : null,
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => n.update((s, _) => s.addSet(index)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l.addSet),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  const _SetRow({
    super.key,
    required this.exIndex,
    required this.setIndex,
    required this.set,
    required this.label,
    this.previous,
  });
  final int exIndex;
  final int setIndex;
  final SessionSet set;
  final String label;
  final SessionSet? previous;

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final _kg = TextEditingController(text: _kgText(widget.set.weightKg));
  late final _reps = TextEditingController(text: widget.set.reps?.toString() ?? '');
  final _kgFocus = FocusNode();
  final _repsFocus = FocusNode();

  static String _kgText(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.round().toString() : v.toString());

  @override
  void didUpdateWidget(_SetRow old) {
    super.didUpdateWidget(old);
    // Keep the boxes in step when the model changes from elsewhere (a new set
    // copied from the last, a removed row) without fighting the user's typing.
    if (!_kgFocus.hasFocus && _kgText(widget.set.weightKg) != _kg.text) _kg.text = _kgText(widget.set.weightKg);
    final r = widget.set.reps?.toString() ?? '';
    if (!_repsFocus.hasFocus && r != _reps.text) _reps.text = r;
  }

  @override
  void dispose() {
    _kg.dispose();
    _reps.dispose();
    _kgFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  ActiveWorkoutNotifier get _n => ref.read(activeWorkoutProvider.notifier);

  void _edit(SessionSet Function(SessionSet) f) => _n.update((s, _) => s.updateSet(widget.exIndex, widget.setIndex, f));

  Future<void> _pickType() async {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final picked = await showModalBottomSheet<Object>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l.setTypeTitle, style: t.titleLarge),
              ),
              const SizedBox(height: 8),
              for (final (type, title, sub) in [
                (SetType.warmup, l.stWarmup, l.stWarmupSub),
                (SetType.normal, l.stNormal, l.stNormalSub),
                (SetType.failure, l.stFailure, l.stFailureSub),
                (SetType.drop, l.stDrop, l.stDropSub),
              ])
                ListTile(
                  selected: widget.set.type == type,
                  selectedColor: Volt.brand,
                  title: Text(title),
                  subtitle: Text(sub, style: t.bodySmall),
                  onTap: () => Navigator.pop(ctx, type),
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(l.removeSet),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked is SetType) _edit((s) => s.copyWith(type: picked));
    if (picked == 'remove') _n.update((s, _) => s.removeSet(widget.exIndex, widget.setIndex));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final s = widget.set;
    final p = widget.previous;
    final done = s.done;

    InputDecoration box() => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      fillColor: done ? Volt.brandWash : Volt.card2,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: done ? Volt.brandWash.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 44,
            child: TextButton(
              onPressed: _pickType,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(40, 44)),
              child: Text(
                widget.label,
                style: t.titleMedium?.copyWith(
                  color: s.type == SetType.normal ? Volt.t1 : (s.type == SetType.warmup ? Volt.warn : Volt.orange),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(p == null ? '—' : '${fmtKg(context, p.weightKg ?? 0)} × ${p.reps}', style: t.bodySmall),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: TextField(
                controller: _kg,
                focusNode: _kgFocus,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: box().copyWith(hintText: p?.weightKg == null ? null : _kgText(p!.weightKg)),
                style: t.titleMedium,
                onChanged: (v) => _edit((x) => x.copyWith(weightKg: () => double.tryParse(v.replaceAll(',', '.')))),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: TextField(
                controller: _reps,
                focusNode: _repsFocus,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: box().copyWith(hintText: p?.reps?.toString()),
                style: t.titleMedium,
                onChanged: (v) => _edit((x) => x.copyWith(reps: () => int.tryParse(v))),
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: IconButton(
              tooltip: l.tickSetHint,
              onPressed: s.complete || done
                  ? () {
                      HapticFeedback.selectionClick();
                      FocusScope.of(context).unfocus();
                      _n.update((x, now) => x.toggleDone(widget.exIndex, widget.setIndex, now));
                    }
                  : null,
              icon: Icon(
                done ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                color: done ? Volt.brand : (s.complete ? Volt.t2 : Volt.t4),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.left,
    required this.total,
    required this.onMinus,
    required this.onPlus,
    required this.onSkip,
  });
  final int left;
  final int total;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
        decoration: BoxDecoration(
          color: Volt.card2,
          borderRadius: BorderRadius.circular(Volt.rCard),
          border: Border.all(color: Volt.brandEdge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(l.restRunning, style: t.bodySmall),
                      const SizedBox(width: 10),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            fmtClock(Duration(seconds: left)),
                            style: t.headlineMedium?.copyWith(fontSize: 26, color: Volt.brand),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (final (label, tap) in [('−15', onMinus), ('+15', onPlus), (l.skip, onSkip)])
                  TextButton(
                    onPressed: tap,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    // A minus sign must not flip to the end in right-to-left text.
                    child: Text(label, textDirection: TextDirection.ltr),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : left / total,
                minHeight: 5,
                color: Volt.brand,
                backgroundColor: Volt.card,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
