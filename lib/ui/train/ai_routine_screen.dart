import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart';
import '../../data/training.dart';
import '../../domain/routine_ai.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/config_providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/ask_iron.dart';
import '../common/iron_options.dart';
import '../common/iron_avatar.dart';
import '../kit/kit.dart';
import '../me/account_screen.dart' show cloudMessage;
import 'train_kit.dart';

/// Type what you want to train; the AI builds the routines, you look them
/// over, and they go into the weekly plan in one tap.
class AiRoutineScreen extends ConsumerStatefulWidget {
  const AiRoutineScreen({super.key});

  @override
  ConsumerState<AiRoutineScreen> createState() => _AiRoutineScreenState();
}

class _AiRoutineScreenState extends ConsumerState<AiRoutineScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  var _busy = false;
  var _saving = false;
  AiPlan? _plan;

  /// What the user has asked so far; null until the first send.
  List<String>? _asked;

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    final l = AppLocalizations.of(context);
    final text = _text.text.trim();
    final lib = ref.read(exerciseLibraryProvider).value;
    if (text.isEmpty || lib == null) return;
    if (!ref.read(remoteConfigProvider).routineAi) {
      showVToast(context, l.aiRoutineOff, info: true);
      return;
    }
    if ((ref.read(accountProvider).value ?? ref.read(cloudProvider).email) == null) {
      showVToast(context, l.aiNeedsAccount, info: true);
      context.push('/account');
      return;
    }
    FocusScope.of(context).unfocus();
    final before = _asked;
    final asked = [...?_asked, text];
    setState(() {
      _busy = true;
      _plan = null;
      _asked = asked;
      _text.clear();
    });
    // The answer comes at the top: go there, not stay at the button.
    if (_scroll.hasClients)
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    try {
      final (data, _) = await ref
          .read(cloudProvider)
          .planRoutines(
            asked.join('\n'),
            exercises: plannableNames(lib),
            languageCode: Localizations.localeOf(context).languageCode,
            bucket: ref.read(installBucketProvider),
          );
      if (!mounted) return;
      final plan = planFrom(data, lib);
      setState(() => _plan = plan);
    } on CloudException catch (e) {
      if (!mounted) return;
      setState(() {
        _text.text = text;
        _asked = before;
      });
      showVToast(context, cloudMessage(l, e.failure), info: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add(AiPlan plan) async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final actions = ref.read(routineActionsProvider);
    for (final r in plan.routines) {
      await actions.save(r.copyWith(name: await actions.freeName(r.name)));
    }
    if (!mounted) return;
    showVToast(context, l.aiRoutineAdded(plan.routines.length));
    context.canPop() ? context.pop() : context.go('/train');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lib = ref.watch(exerciseLibraryProvider).value;
    final plan = _plan;

    return Scaffold(
      body: VScreen(
        overlays: [
          if (plan != null && !plan.isEmpty)
            LogBar(
              aboveTabs: false,
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
              children: [
                Expanded(
                  child: VBtn(
                    label: l.aiRoutineAdd(plan.routines.length),
                    expand: true,
                    onTap: _saving ? null : () => _add(plan),
                  ),
                ),
              ],
            ),
        ],
        child: Column(
          children: [
            BackBar(
              title: l.aiRoutineTitle,
              sub: l.aiRoutineSub,
              onBack: () => context.canPop() ? context.pop() : context.go('/train'),
            ),
            Expanded(
              child: Pad(
                controller: _scroll,
                bottom: 170,
                children: [
                  if (_asked == null) ...[
                    IronStage(title: l.ironRoutineHi, question: l.ironQRoutine),
                    IronOptions(
                      buildLabel: l.aiRoutineBuild,
                      busy: lib == null,
                      fallback: l.ironRoutineDefault,
                      onBuild: (note) {
                        _text.text = note;
                        _build();
                      },
                    ),
                  ] else ...[
                    for (final a in _asked!) UserBubble(a),
                    IronSays(
                      typing: _busy,
                      mood: plan == null || plan.isEmpty ? IronMood.happy : IronMood.cheer,
                      child: IronBubble(
                        plan == null || plan.isEmpty
                            ? l.aiRoutineNone
                            : plan.summary.isNotEmpty
                            ? plan.summary
                            : l.ironRoutineReady,
                      ),
                    ),
                  ],
                  if (plan != null && !plan.isEmpty) ...[
                    for (final r in plan.routines) PlannedRoutineCard(routine: r, lib: lib!),
                    if (plan.missing.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Muted(l.aiRoutineMissing(plan.missing.join(', '))),
                      ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.aiRoutineCheck)),
                  ],
                  if (_asked != null && !_busy && lib != null)
                    IronOptions(
                      buildLabel: l.aiRoutineAgain,
                      fallback: l.ironRoutineDefault,
                      onBuild: (note) {
                        _text.text = note;
                        _build();
                      },
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

/// One routine the AI made: its name, when it runs, and each exercise with
/// its sets and reps.
class PlannedRoutineCard extends StatelessWidget {
  const PlannedRoutineCard({super.key, required this.routine, required this.lib});
  final Routine routine;
  final ExerciseLibrary lib;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VCard(
      child: GapCol(
        gap: 10,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GapCol(
                  gap: 2,
                  children: [
                    Text(
                      routine.name,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Volt.t1),
                    ),
                    Muted('${whenLine(context, routine)} · ${l.setsAbout(routine.totalSets, routineMinutes(routine))}'),
                  ],
                ),
              ),
            ],
          ),
          for (final it in routine.items)
            Row(
              children: [
                ExAv(lib[it.exerciseId]?.badge ?? '', small: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lib[it.exerciseId]?.shortName ?? it.exerciseId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Volt.t1),
                  ),
                ),
                Text(
                  '${it.sets} × ${it.repLow}–${it.repHigh}',
                  style: numStyle(13, weight: FontWeight.w500, color: Volt.t2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
