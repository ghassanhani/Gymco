import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart';
import '../../domain/coach.dart';
import '../../domain/remote_config.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/coach_providers.dart';
import '../../state/config_providers.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/ask_iron.dart';
import '../common/iron_avatar.dart';
import '../kit/kit.dart';
import '../me/account_screen.dart' show cloudMessage;
import 'ai_routine_screen.dart' show PlannedRoutineCard;
import 'iron_settings_screen.dart' show ironReadsLine;

/// Iron builds a whole program from the user's numbers, like a personal
/// trainer: daily eating targets, a week of training and three habits.
class IronScreen extends ConsumerStatefulWidget {
  const IronScreen({super.key});

  @override
  ConsumerState<IronScreen> createState() => _IronScreenState();
}

class _IronScreenState extends ConsumerState<IronScreen> {
  final _ask = TextEditingController();
  var _busy = false;
  var _saving = false;
  IronProgram? _program;

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  Future<void> _build() async {
    final l = AppLocalizations.of(context);
    if (!ref.read(remoteConfigProvider).coachAi) {
      showVToast(context, l.ironOff, info: true);
      return;
    }
    if ((ref.read(accountProvider).value ?? ref.read(cloudProvider).email) == null) {
      showVToast(context, l.aiNeedsAccount, info: true);
      context.push('/account');
      return;
    }
    await ref.read(ironOnProvider.notifier).set(true);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _program = null;
    });
    try {
      final p = await ref
          .read(ironActionsProvider)
          .program(languageCode: Localizations.localeOf(context).languageCode, ask: _ask.text);
      if (!mounted) return;
      setState(() => _program = p);
      if (p.isEmpty) showVToast(context, l.aiRoutineNone, info: true);
    } on CloudException catch (e) {
      if (mounted) showVToast(context, cloudMessage(l, e.failure), info: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _use(IronProgram p) async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final held = await ref.read(ironActionsProvider).apply(p);
    if (!mounted) return;
    showVToast(
      context,
      held ? '${l.ironUsed} ${l.ironHeld(fmtInt(context, RemoteConfig.current.maxWeeklyChange))}' : l.ironUsed,
    );
    context.go('/train');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lib = ref.watch(exerciseLibraryProvider).value;
    final profile = ref.watch(profileProvider);
    final p = _program;

    Widget head(String text) =>
        Eyebrow(text, color: ironGradient[1], padding: const EdgeInsetsDirectional.only(start: 4, top: 4));

    return Scaffold(
      body: VScreen(
        overlays: [
          if (p != null && !p.isEmpty)
            LogBar(
              aboveTabs: false,
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
              children: [
                Expanded(
                  child: AiBtn(
                    label: l.ironUse,
                    busy: _saving,
                    colors: ironGradient,
                    foreground: Colors.white,
                    onTap: () => _use(p),
                  ),
                ),
              ],
            ),
        ],
        child: Column(
          children: [
            BackBar(
              title: l.ironProgramTitle,
              sub: l.ironProgramSub,
              onBack: () => context.canPop() ? context.pop() : context.go('/today'),
            ),
            Expanded(
              child: Pad(
                bottom: 130,
                children: [
                  AskIron(
                    question: l.ironQProgram,
                    busyQuestion: l.ironQProgramBusy,
                    controller: _ask,
                    hint: l.ironAskHint,
                    maxLength: 400,
                    busy: _busy,
                    mood: p == null ? null : IronMood.cheer,
                    sendEmpty: true,
                    sendLabel: p == null ? l.ironBuild : l.aiRoutineAgain,
                    onSend: lib == null ? null : _build,
                    suggestions: [l.ironAskEx1, l.ironAskEx2, l.ironAskEx3],
                  ),
                  Muted(l.ironProgramIntro, size: 12, align: TextAlign.center),
                  Muted('${ironReadsLine(l, ref)}. ${l.ironPhotosNever}', size: 11.5, align: TextAlign.center),
                  if (p != null && !p.isEmpty) ...[
                    if (p.summary.isNotEmpty)
                      VCard(
                        color: ironGradient[1].withValues(alpha: 0.1),
                        border: Border.all(color: ironGradient[1].withValues(alpha: 0.35)),
                        child: Muted(p.summary, size: 13.5, color: Volt.t1),
                      ),
                    if (p.kcal > 0) ...[
                      head(l.ironEatHeader),
                      VCard(
                        child: GapCol(
                          gap: 12,
                          cross: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(child: Text(l.ironKcalDay(fmtInt(context, p.kcal)), style: numStyle(22))),
                                if (profile != null) Muted(l.ironNowVs(fmtInt(context, profile.targetKcal)), size: 12),
                              ],
                            ),
                            Row(
                              children: [
                                for (final (name, g, c) in [
                                  (l.protein, p.macros.protein, Volt.protein),
                                  (l.carbs, p.macros.carbs, Volt.carbs),
                                  (l.fat, p.macros.fat, Volt.fat),
                                ])
                                  Expanded(
                                    child: GapCol(
                                      gap: 2,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                            ),
                                            const SizedBox(width: 6),
                                            Muted(name, size: 12),
                                          ],
                                        ),
                                        Text('${fmtInt(context, g)} g', style: numStyle(16)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (p.why.isNotEmpty) Muted(p.why, size: 12.5),
                          ],
                        ),
                      ),
                    ],
                    if (p.plan.routines.isNotEmpty && lib != null) ...[
                      head(l.ironTrainHeader),
                      for (final r in p.plan.routines) PlannedRoutineCard(routine: r, lib: lib),
                      if (p.plan.missing.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Muted(l.aiRoutineMissing(p.plan.missing.join(', '))),
                        ),
                    ],
                    if (p.habits.isNotEmpty) ...[
                      head(l.ironHabitsHeader),
                      VList(
                        children: [
                          for (final h in p.habits)
                            VItem(
                              children: [
                                VIcon('check', size: 16, color: Volt.ok),
                                ItemText(h),
                              ],
                            ),
                        ],
                      ),
                    ],
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.aiRoutineCheck)),
                  ],
                  if (p == null && ref.watch(ironOnProvider))
                    Center(
                      child: TextButton(
                        onPressed: () async {
                          await ref.read(ironOnProvider.notifier).set(false);
                          if (context.mounted) context.canPop() ? context.pop() : context.go('/today');
                        },
                        child: Text(l.ironTurnOff, style: TextStyle(fontSize: 13, color: Volt.t3)),
                      ),
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
