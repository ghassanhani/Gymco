import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/training.dart';
import '../../l10n/app_localizations.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import 'train_kit.dart';
import 'train_screen.dart' show TemplateList;

/// The routine library: where routines are made and edited, not where you
/// train. Two folders, each a stack of routine cards.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _open = {RoutineFolder.plan: true, RoutineFolder.mine: true};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    final lib = ref.watch(exerciseLibraryProvider).value;
    final live = ref.watch(activeWorkoutProvider) != null;

    Widget folder(RoutineFolder f, String title) {
      final rows = routines.where((r) => r.folder == f).toList()
        ..sort((a, b) => (a.weekday ?? 9).compareTo(b.weekday ?? 9));
      final open = _open[f]!;
      return GapCol(
        gap: 10,
        cross: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            onTap: () => setState(() => _open[f] = !open),
            scale: 1,
            label: title,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: open ? 0 : -0.25,
                    duration: const Duration(milliseconds: 280),
                    curve: const Cubic(0.32, 0.72, 0, 1),
                    child: VIcon('down', size: 18, color: Volt.t3),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Eyebrow('$title (${rows.length})', color: Volt.t2)),
                ],
              ),
            ),
          ),
          if (open) ...[
            for (final r in rows) _RoutineCard(routine: r, lib: lib),
            if (f == RoutineFolder.mine)
              Pressable(
                onTap: () => context.push('/routine/new'),
                label: l.addToFolder,
                child: DottedBox(
                  child: Row(
                    children: [
                      VIcon('plus', size: 17, color: Volt.t3),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l.addToFolder, style: TextStyle(fontSize: 14, color: Volt.t3)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VScreen(
        overlays: const [ResumeBar()],
        child: Column(
          children: [
            BackBar(
              title: l.allRoutines,
              sub: l.routinesSubLib(routines.length),
              onBack: () => context.canPop() ? context.pop() : context.go('/train'),
              right: VBtn(
                label: l.newShort,
                kind: BtnKind.ghost,
                small: true,
                icon: 'plus',
                minHeight: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                onTap: () => context.push('/routine/new'),
              ),
            ),
            Expanded(
              child: Pad(
                bottom: live ? 190 : 116,
                children: [
                  VList(
                    children: [
                      VItem(
                        semantics: l.describeIt,
                        onTap: () => context.push('/routine/ai'),
                        children: [
                          const AiMark(size: 32),
                          ItemText(l.describeIt, sub: l.describeItSub, weight: FontWeight.w600),
                          VIcon('fwd', size: 18, color: Volt.t3),
                        ],
                      ),
                    ],
                  ),
                  folder(RoutineFolder.plan, l.folderPlan),
                  folder(RoutineFolder.mine, l.folderMine),
                  VList(
                    children: [
                      VItem(
                        onTap: () => context.push('/exercises/browse'),
                        children: [
                          ItemText(l.myExercises, sub: l.myExercisesSub(lib?.all.length ?? 0), weight: FontWeight.w600),
                          VIcon('fwd', size: 18, color: Volt.t1),
                        ],
                      ),
                      VItem(
                        onTap: () => showVSheet<void>(
                          context,
                          title: l.exploreRoutines,
                          body: (ctx) => [
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.exploreSub)),
                            TemplateList(
                              onDone: (t) {
                                Navigator.pop(ctx);
                                showVToast(context, l.templateAdded(t));
                              },
                            ),
                          ],
                        ),
                        children: [
                          ItemText(l.exploreRoutines, sub: l.exploreSub, weight: FontWeight.w600),
                          VIcon('fwd', size: 18, color: Volt.t1),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  const _RoutineCard({required this.routine, required this.lib});
  final Routine routine;
  final ExerciseLibrary? lib;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final r = routine;
    return VCard(
      padding: const EdgeInsets.all(14),
      child: GapCol(
        gap: 10,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Pressable(
                  onTap: () => context.push('/routine/${r.id}/view'),
                  scale: 0.99,
                  label: r.name,
                  child: Text(
                    r.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                  ),
                ),
              ),
              IconBtn(
                'more',
                label: l.optionsFor(r.name),
                size: 34,
                iconSize: 18,
                background: Colors.transparent,
                color: Volt.t3,
                onTap: () => showRoutineOptions(context, ref, r),
              ),
            ],
          ),
          ExList(
            children: [for (final it in r.items) ExLine(item: it, exercise: lib?[it.exerciseId])],
          ),
          Row(
            children: [
              Expanded(child: Muted(l.routineCardSub(whenLine(context, r), r.totalSets))),
              VBtn(label: l.startRoutine, kind: BtnKind.start, small: true, onTap: () => startRoutine(context, ref, r)),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> startRoutine(BuildContext context, WidgetRef ref, Routine r) async {
  final lib = await ref.read(exerciseLibraryProvider.future);
  await ref.read(activeWorkoutProvider.notifier).startRoutine(r, lib);
  if (context.mounted) context.push('/workout');
}

/// Start, edit, duplicate, delete: the routine's own menu.
Future<void> showRoutineOptions(BuildContext context, WidgetRef ref, Routine r) {
  final l = AppLocalizations.of(context);
  return showVSheet<void>(
    context,
    title: r.name,
    body: (ctx) => [
      SRow(
        label: l.startRoutineFull,
        onTap: () {
          Navigator.pop(ctx);
          startRoutine(context, ref, r);
        },
      ),
      SRow(
        label: l.editRoutine,
        sub: l.editRoutineSub,
        onTap: () {
          Navigator.pop(ctx);
          context.push('/routine/${r.id}');
        },
      ),
      SRow(
        label: l.duplicate,
        sub: l.duplicateSub,
        onTap: () async {
          Navigator.pop(ctx);
          final name = await ref.read(routineActionsProvider).duplicate(r, l.copyName(r.name));
          if (context.mounted) showVToast(context, l.duplicated(name));
        },
      ),
      SRow(
        label: l.deleteRoutine,
        sub: l.deleteRoutineSub,
        tint: Volt.brandInk,
        onTap: () {
          Navigator.pop(ctx);
          confirmDeleteRoutine(context, ref, r);
        },
      ),
    ],
  );
}

Future<void> confirmDeleteRoutine(BuildContext context, WidgetRef ref, Routine r, {VoidCallback? after}) {
  final l = AppLocalizations.of(context);
  return showVSheet<void>(
    context,
    title: l.deleteNamed(r.name),
    body: (ctx) => [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.deleteRoutineBody)),
      SRow(label: l.keepIt, onTap: () => Navigator.pop(ctx)),
      SRow(
        label: l.deleteRoutine,
        tint: Volt.brandInk,
        onTap: () async {
          Navigator.pop(ctx);
          await ref.read(routineActionsProvider).delete(r.id!);
          after?.call();
        },
      ),
    ],
  );
}

/// The dashed "add" row at the end of a folder.
class DottedBox extends StatelessWidget {
  const DottedBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRRect(),
    child: Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: child,
    ),
  );
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    final path = Path()..addRRect(rr.deflate(0.5));
    final paint = Paint()
      ..color = Volt.line2
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => false;
}
