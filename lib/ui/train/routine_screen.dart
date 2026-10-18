import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import 'library_screen.dart';
import 'exercise_photo.dart';
import 'train_kit.dart';

/// One routine, read-only: what it holds and what it does to the week.
class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key, required this.routineId});
  final int routineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final r = (ref.watch(routinesProvider).value ?? const <Routine>[]).where((x) => x.id == routineId).firstOrNull;
    final lib = ref.watch(exerciseLibraryProvider).value;
    if (r == null) return const Scaffold(body: VScreen(child: SizedBox.shrink()));
    final last = ref.watch(lastRunProvider)[r.id];
    final lastLine = last == null
        ? l.neverRun
        : (DateUtils.isSameDay(last, DateTime.now())
              ? l.todayLbl.toLowerCase()
              : l.doneOn(DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(last)));
    final folder = r.folder == RoutineFolder.plan ? l.folderPlan : l.folderMine;

    return Scaffold(
      body: VScreen(
        overlays: [
          LogBar(
            aboveTabs: false,
            padding: const EdgeInsets.all(8),
            children: [
              VBtn(
                label: l.edit,
                kind: BtnKind.ghost,
                small: true,
                minHeight: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: () => context.push('/routine/${r.id}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: VBtn(
                  label: l.startRoutineFull,
                  small: true,
                  minHeight: 44,
                  expand: true,
                  onTap: () => startRoutine(context, ref, r),
                ),
              ),
            ],
          ),
        ],
        child: Column(
          children: [
            BackBar(
              title: r.name,
              sub: '$folder · $lastLine',
              right: IconBtn(
                'more',
                label: l.optionsFor(r.name),
                small: true,
                iconSize: 18,
                background: Colors.transparent,
                color: Volt.t3,
                onTap: () => showRoutineOptions(context, ref, r),
              ),
            ),
            Expanded(
              child: Pad(
                bottom: 150,
                children: [
                  VCard(
                    child: Row(
                      children: [
                        for (final (k, v) in [
                          (l.estDuration, l.minutesShort('${routineMinutes(r)}')),
                          (l.exercisesLbl, '${r.items.length}'),
                          (l.setsLabel, '${r.totalSets}'),
                        ])
                          Expanded(
                            child: GapCol(
                              gap: 3,
                              children: [
                                Eyebrow(k),
                                Text(v, style: numStyle(17)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  VList(
                    children: [
                      for (final it in r.items)
                        VItem(
                          onTap: () => context.push('/exercise/${Uri.encodeComponent(it.exerciseId)}'),
                          children: [
                            ExThumb(lib?[it.exerciseId], size: 44),
                            ItemText(
                              lib?[it.exerciseId]?.name ?? it.exerciseId,
                              weight: FontWeight.w600,
                              sub: l.itemLine(it.sets, ltr(it.reps), it.rir, fmtRest(it.restSeconds)),
                            ),
                          ],
                        ),
                    ],
                  ),
                  VolumeCard(items: r.items, title: l.weekEffect, exceptRoutineId: r.weekday == null ? null : r.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
