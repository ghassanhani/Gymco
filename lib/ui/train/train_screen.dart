import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final active = ref.watch(activeWorkoutProvider);
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    final history = ref.watch(recentWorkoutsProvider).value ?? const <WorkoutRecord>[];
    final lib = ref.watch(exerciseLibraryProvider).value;
    final now = ref.watch(clockProvider)();

    Future<void> start(Routine r) async {
      if (lib == null) return;
      await ref.read(activeWorkoutProvider.notifier).startRoutine(r, lib);
      if (context.mounted) context.push('/workout');
    }

    return VoltBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 140),
          children: [
            AccentTitle(template: l.trainTitleTpl('{accent}'), accent: l.trainAccent),
            const SizedBox(height: 18),
            if (active != null) ...[
              _ActiveCard(
                name: active.name,
                elapsed: fmtClock(active.elapsed(now)),
                onResume: () => context.push('/workout'),
              ),
              const SizedBox(height: 12),
            ],
            if (active == null)
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: l.emptyWorkout,
                      icon: Icons.add_rounded,
                      onPressed: () {
                        ref.read(activeWorkoutProvider.notifier).startEmpty(l.workoutDefaultName);
                        context.push('/workout');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GhostButton(
                      label: l.newRoutine,
                      icon: Icons.playlist_add_rounded,
                      onPressed: () => context.push('/routine/new'),
                    ),
                  ),
                ],
              ),
            SectionHeader(l.routines),
            if (routines.isEmpty)
              VoltCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.noRoutinesTitle, style: t.titleMedium),
                    const SizedBox(height: 4),
                    Text(l.noRoutinesBody, style: t.bodyMedium),
                  ],
                ),
              ),
            for (final r in routines) ...[
              _RoutineCard(
                routine: r,
                lib: lib,
                canStart: active == null,
                onStart: () => start(r),
                onEdit: () => context.push('/routine/${r.id}'),
              ),
              const SizedBox(height: 10),
            ],
            SectionHeader(l.history),
            if (history.isEmpty) VoltCard(child: Text(l.noHistory, style: t.bodyMedium)),
            for (final w in history) ...[
              VoltCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name, style: t.titleMedium),
                          Text(
                            '${fmtDay(context, w.startedAt)} · ${l.minutesShort(fmtInt(context, w.duration.inMinutes))} · ${l.setsCount(w.sets)}',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text('${fmtInt(context, w.volume)} ${l.kgLbl}', style: t.titleMedium),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.name, required this.elapsed, required this.onResume});
  final String name;
  final String elapsed;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Volt.brandWash,
        borderRadius: BorderRadius.circular(Volt.rCard),
        border: Border.all(color: Volt.brand, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: t.titleLarge),
                Text(l.inProgress(elapsed), style: t.bodySmall?.copyWith(color: Volt.brandInk)),
              ],
            ),
          ),
          GlowButton(label: l.resumeWorkout, onPressed: onResume),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.routine,
    required this.lib,
    required this.canStart,
    required this.onStart,
    required this.onEdit,
  });
  final Routine routine;
  final ExerciseLibrary? lib;
  final bool canStart;
  final VoidCallback onStart;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return VoltCard(
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(routine.name, style: t.titleLarge)),
              IconButton(
                tooltip: l.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, color: Volt.t3),
              ),
            ],
          ),
          for (final item in routine.items.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _Badge(lib?[item.exerciseId]?.badge ?? '•'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lib?[item.exerciseId]?.name ?? item.exerciseId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(color: Volt.t1),
                    ),
                  ),
                  Text('${item.sets} × ${item.repLow}–${item.repHigh}', style: t.bodySmall),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l.exercisesCount(routine.items.length)} · ${l.setsCount(routine.totalSets)}',
                  style: t.bodySmall,
                ),
              ),
              GlowButton(label: l.startRoutine, icon: Icons.play_arrow_rounded, onPressed: canStart ? onStart : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(9)),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Volt.t2),
    ),
  );
}
