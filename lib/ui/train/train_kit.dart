import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../data/training.dart';
import '../../domain/volume.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

/// 3:00, 2:30, 0:45.
String fmtRest(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// Monday … Sunday in the user's language, from a 0 = Monday index.
String weekdayName(BuildContext context, int w) =>
    DateFormat.EEEE(Localizations.localeOf(context).toString()).format(DateTime(2024, 1, 1 + w));

String weekdayShort(BuildContext context, int w) =>
    DateFormat.E(Localizations.localeOf(context).toString()).format(DateTime(2024, 1, 1 + w));

String groupName(AppLocalizations l, MuscleGroup g) => switch (g) {
  MuscleGroup.chest => l.m_chest,
  MuscleGroup.shoulders => l.m_shoulders,
  MuscleGroup.triceps => l.m_triceps,
  MuscleGroup.back => l.gBack,
  MuscleGroup.biceps => l.m_biceps,
  MuscleGroup.legs => l.gLegs,
  MuscleGroup.core => l.gCore,
};

/// "Chest · shoulders, triceps", the prototype's muscle line.
String muscleLine(AppLocalizations l, Exercise e) {
  final main = e.primary.map((m) => muscleName(l, m)).join(', ');
  final also = e.secondary.take(3).map((m) => muscleName(l, m).toLowerCase()).join(', ');
  return also.isEmpty ? main : '$main · $also';
}

/// When a routine runs: "Every Saturday" or "Any day".
String whenLine(BuildContext context, Routine r) {
  final l = AppLocalizations.of(context);
  return r.weekday == null ? l.anyDay : l.everyDay(weekdayName(context, r.weekday!));
}

/// The plan's minutes, the prototype's honest estimate.
int routineMinutes(Routine r) => planMinutes([for (final i in r.items) (i.sets, i.restSeconds)]);

/// `.exline`: one exercise of a plan, on the surface. The name opens it; the
/// play button starts that exercise on its own.
class ExLine extends StatelessWidget {
  const ExLine({
    super.key,
    required this.item,
    required this.exercise,
    this.lead = false,
    this.onStart,
    this.done = false,
    this.onBrand = false,
  });
  final RoutineItem item;
  final Exercise? exercise;
  final bool lead;
  final VoidCallback? onStart;
  final bool done;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = exercise?.name ?? item.exerciseId;
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      child: Row(
        children: [
          if (lead) ...[ExAv(exercise?.badge ?? '··', small: true), const SizedBox(width: 8)],
          Expanded(
            child: Pressable(
              onTap: () => context.push('/exercise/${Uri.encodeComponent(item.exerciseId)}'),
              scale: 0.99,
              radius: 12,
              label: l.exLineLabel(name, item.sets, item.reps),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: done ? Volt.t3 : Volt.t1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item.sets} × ${item.reps}',
            textDirection: TextDirection.ltr,
            style: numStyle(12.5, weight: FontWeight.w400, color: done ? Volt.t4 : Volt.t3),
          ),
          if (done) ...[
            const SizedBox(width: 8),
            Semantics(
              label: l.loggedLbl,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(color: Volt.okWash, shape: BoxShape.circle),
                child: const Center(child: VIcon('check', size: 14, color: Volt.ok)),
              ),
            ),
          ] else if (onStart != null) ...[
            const SizedBox(width: 8),
            Pressable(
              onTap: onStart,
              label: l.startOnItsOwn(name),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Volt.brandWash,
                  shape: BoxShape.circle,
                  border: Border.all(color: Volt.brandEdge),
                ),
                child: const Center(child: VIcon('play', size: 14, color: Volt.brandInk)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.exlist`: the lines with hairlines between them.
class ExList extends StatelessWidget {
  const ExList({super.key, required this.children, this.onBrand = false});
  final List<Widget> children;
  final bool onBrand;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) Container(height: 1, color: onBrand ? Volt.brandEdge : Volt.line),
        children[i],
      ],
    ],
  );
}

/// The weekly-volume read-out the routine detail and the builder share.
class VolumeCard extends ConsumerWidget {
  const VolumeCard({super.key, required this.items, required this.title, this.exceptRoutineId});
  final List<RoutineItem> items;
  final String title;

  /// The routine being shown, so it is not counted twice.
  final int? exceptRoutineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final lib = ref.watch(exerciseLibraryProvider).value;
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    if (lib == null || items.isEmpty) return const SizedBox.shrink();
    String? muscle(String id) {
      final e = lib[id];
      return e == null || e.primary.isEmpty ? null : e.primary.first;
    }

    final plan = [
      for (final i in items)
        if (muscle(i.exerciseId) case final m?) (m, i.sets),
    ];
    final rest = [
      for (final r in routines)
        if (r.weekday != null && r.id != exceptRoutineId)
          for (final i in r.items)
            if (muscle(i.exerciseId) case final m?) (m, i.sets),
    ];
    final rows = weeklyVolume(plan, rest);
    if (rows.isEmpty) return const SizedBox.shrink();
    return VCard(
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(title),
          for (final g in rows) _VolumeRow(g: g),
          Muted(l.volumeNote),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.g});
  final GroupVolume g;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (color, state) = switch (g.state) {
      VolumeState.inRange => (Volt.ok, l.inRange),
      VolumeState.under => (Volt.t3, l.belowRange),
      VolumeState.over => (Volt.warn, l.aboveRange),
    };
    return GapCol(
      gap: 5,
      cross: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                groupName(l, g.group),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Volt.t2),
              ),
            ),
            Text('${g.total}', style: numStyle(13)),
            const SizedBox(width: 6),
            Text(l.setsWkState(state), style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
        VolumeBar(total: g.total, color: color),
      ],
    );
  }
}

/// A 6 px track with the 10–20 band washed in and the total filled.
class VolumeBar extends StatelessWidget {
  const VolumeBar({super.key, required this.total, required this.color, this.height = 6, this.scale = 24});
  final int total;
  final Color color;
  final double height;
  final int scale;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) {
      final w = c.maxWidth;
      final pct = (total / scale).clamp(0.04, 1.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: Container(color: Volt.line)),
              PositionedDirectional(
                start: w * volumeLow / scale,
                width: w * (volumeHigh - volumeLow) / scale,
                top: 0,
                bottom: 0,
                child: Container(color: Volt.okWash),
              ),
              PositionedDirectional(
                start: 0,
                width: w * pct,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A live session follows you around the app, the way a music player does.
class ResumeBar extends ConsumerWidget {
  const ResumeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(activeWorkoutProvider);
    if (s == null) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, _) {
        final now = ref.read(clockProvider)();
        return LogBar(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 8, 8),
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Volt.brand,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Volt.brandWash, spreadRadius: 4)],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GapCol(
                gap: 1,
                children: [
                  Text(
                    l.inProgressName(s.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Volt.t1),
                  ),
                  Text(
                    l.resumeSub(fmtClock(s.elapsed(now)), s.setsDone, s.setsPlanned),
                    style: numStyle(12, weight: FontWeight.w400, color: Volt.t3),
                  ),
                ],
              ),
            ),
            VBtn(
              label: l.discardShort,
              kind: BtnKind.ghost,
              small: true,
              minHeight: 36,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onTap: () {
                ref.read(activeWorkoutProvider.notifier).discard();
                showVToast(context, l.workoutDiscarded, info: true);
              },
            ),
            const SizedBox(width: 8),
            VBtn(
              label: l.resumeWorkout,
              small: true,
              minHeight: 36,
              fontSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              onTap: () => context.push('/workout'),
            ),
          ],
        );
      },
    );
  }
}

/// The dashed box with a dumbbell that empty states use.
class DumbbellEmpty extends StatelessWidget {
  const DumbbellEmpty({super.key, required this.text, this.size = 60});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => VCard(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
    child: Column(
      children: [
        EmptyArt(size: size),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Muted(text, align: TextAlign.center),
        ),
      ],
    ),
  );
}
