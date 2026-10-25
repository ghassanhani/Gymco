import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/training.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import 'exercise_photo.dart';
import 'train_kit.dart';

/// Exercises that train what [e] trains: same main muscle first, then the
/// same kind of movement, then the most shared helpers.
List<Exercise> alternativesTo(Exercise e, ExerciseLibrary lib, {Set<String> skip = const {}, int take = 8}) {
  double score(Exercise x) {
    final main = x.primary.toSet().intersection(e.primary.toSet()).length;
    if (main == 0) return -1;
    return main * 3 +
        (x.primary.firstOrNull == e.primary.firstOrNull ? 2 : 0) +
        (x.category == e.category ? 1 : 0) +
        x.secondary.toSet().intersection(e.secondary.toSet()).length * 0.3 +
        (x.level == 'expert' ? -1 : 0);
  }

  final scored = [
    for (final x in lib.all)
      if (x.id != e.id && !skip.contains(x.id)) (x, score(x)),
  ]..removeWhere((p) => p.$2 < 0);
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (x, _) in scored.take(take)) x];
}

/// Swap an exercise mid-workout: the machine is taken, or it hurts.
Future<void> swapSheet(BuildContext context, WidgetRef ref, int index) {
  final l = AppLocalizations.of(context);
  final s = ref.read(activeWorkoutProvider)!;
  final lib = ref.read(exerciseLibraryProvider).value;
  final current = lib?[s.exercises[index].exerciseId];
  final options = current == null || lib == null
      ? const <Exercise>[]
      : alternativesTo(current, lib, skip: {for (final e in s.exercises) e.exerciseId});
  return showVSheet<void>(
    context,
    title: l.swapTitle(current?.shortName ?? s.exercises[index].name),
    body: (ctx) => [
      Padding(padding: const EdgeInsets.fromLTRB(4, 0, 4, 4), child: Muted(l.swapSub)),
      if (options.isEmpty) Padding(padding: const EdgeInsets.all(4), child: Muted(l.swapNone)),
      for (final x in options)
        SRow(
          label: x.name,
          sub: muscleLine(l, x),
          lead: ExThumb(x, size: 36),
          onTap: () async {
            Navigator.pop(ctx);
            await ref.read(activeWorkoutProvider.notifier).swap(index, x);
            if (context.mounted) showVToast(context, l.swapped(x.shortName));
          },
        ),
    ],
  );
}

String painAreaName(AppLocalizations l, PainArea a) => switch (a) {
  PainArea.shoulder => l.painShoulder,
  PainArea.elbow => l.painElbow,
  PainArea.wrist => l.painWrist,
  PainArea.back => l.painBack,
  PainArea.hip => l.painHip,
  PainArea.knee => l.painKnee,
  PainArea.other => l.painOther,
};

/// Where it hurt, then what to do about it. Sharp pain is a stop sign.
Future<void> painSheet(BuildContext context, WidgetRef ref, int ex, int set, {required String number}) {
  final l = AppLocalizations.of(context);
  return showVSheet<void>(
    context,
    title: l.painWhere,
    body: (ctx) => [
      RGrid(
        columns: 3,
        children: [
          for (final a in PainArea.values)
            RChip(
              label: painAreaName(l, a),
              on: false,
              onTap: () {
                Navigator.pop(ctx);
                _painWhat(context, ref, ex, set, a, number: number);
              },
            ),
        ],
      ),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.painNote)),
    ],
  );
}

void _painWhat(BuildContext context, WidgetRef ref, int ex, int set, PainArea area, {required String number}) {
  final l = AppLocalizations.of(context);
  final n = ref.read(activeWorkoutProvider.notifier);
  void flag(BuildContext ctx, bool sharp, void Function() then) {
    Navigator.pop(ctx);
    n.flagPain(ex, set, PainFlag(area, sharp: sharp));
    then();
  }

  showVSheet<void>(
    context,
    title: l.painOnSet(painAreaName(l, area), number),
    body: (ctx) => [
      SRow(
        label: l.painAcheLighter,
        sub: l.painAcheLighterSub,
        lead: VIcon('down', size: 18, color: Volt.warn),
        onTap: () => flag(ctx, false, () {
          n.update((x, _) => x.lighten(ex, 0.1));
          showVToast(context, l.painLightened);
        }),
      ),
      SRow(
        label: l.painAcheKeep,
        sub: l.painAcheKeepSub,
        lead: VIcon('eye', size: 18, color: Volt.t2),
        onTap: () => flag(ctx, false, () => showVToast(context, l.painFlagged, info: true)),
      ),
      SRow(
        label: l.painSharpStop,
        sub: l.painSharpStopSub,
        lead: VIcon('warn', size: 18, color: Volt.warn),
        tint: Volt.warn,
        onTap: () => flag(ctx, true, () {
          n.update((x, _) => x.stopExercise(ex));
          showVToast(context, l.painStopped, info: true);
        }),
      ),
      SRow(
        label: l.painSharpSwap,
        sub: l.painSharpSwapSub,
        lead: VIcon('repeat', size: 18, color: Volt.warn),
        tint: Volt.warn,
        onTap: () => flag(ctx, true, () => swapSheet(context, ref, ex)),
      ),
    ],
  );
}

/// On the exercise card: pain flagged on it last time, so today starts
/// careful.
class PainReminder extends ConsumerWidget {
  const PainReminder({super.key, required this.exerciseId, required this.today});
  final String exerciseId;
  final String today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final last = ref.watch(lastPainProvider)[exerciseId];
    if (last == null || last.$2 == today) return const SizedBox.shrink();
    final (pain, day) = last;
    final date = DateFormat('d MMM', Localizations.localeOf(context).toString()).format(DateTime.parse(day));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: smooth(
        BoxDecoration(
          color: Volt.warnWash,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Volt.warnEdge),
        ),
      ),
      child: Row(
        children: [
          VIcon('warn', size: 15, color: Volt.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pain.sharp
                  ? l.painLastSharp(painAreaName(l, pain.area).toLowerCase(), date)
                  : l.painLastAche(painAreaName(l, pain.area).toLowerCase(), date),
              style: TextStyle(fontSize: 12.5, color: Volt.t1, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
