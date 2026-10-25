import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/coach.dart';
import '../../l10n/app_localizations.dart';
import '../../state/coach_providers.dart';
import '../../theme/volt.dart';
import '../common/ask_iron.dart';
import '../common/format.dart';
import '../kit/kit.dart';
import '../today/iron_card.dart' show IronWarningCard;
import 'iron_settings_screen.dart' show ironReadsLine;

/// Iron's home: warning signs first, then a message box to ask Iron, today's
/// tip, the ways in to everything Iron does, and what it made before.
class IronCenterScreen extends ConsumerStatefulWidget {
  const IronCenterScreen({super.key});

  @override
  ConsumerState<IronCenterScreen> createState() => _IronCenterScreenState();
}

class _IronCenterScreenState extends ConsumerState<IronCenterScreen> {
  final _ask = TextEditingController();

  @override
  void dispose() {
    _ask.dispose();
    super.dispose();
  }

  void _send() {
    final m = _ask.text.trim();
    _ask.clear();
    FocusScope.of(context).unfocus();
    context.push('/iron', extra: m.isEmpty ? null : m);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = ref.watch(ironOnProvider);
    final warnings = ref.watch(ironWarningsProvider);
    final tip = ref.watch(ironTipProvider).value;
    final history = ref.watch(ironHistoryProvider);

    Widget head(String text) =>
        Eyebrow(text, color: ironGradient[1], padding: const EdgeInsetsDirectional.only(start: 4, top: 6));

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(
              title: l.ironCenter,
              sub: l.ironCenterSub,
              onBack: () => context.canPop() ? context.pop() : context.go('/today'),
            ),
            Expanded(
              child: Pad(
                children: [
                  if (warnings.isNotEmpty) ...[
                    head(l.ironNeedsAttention),
                    for (final w in warnings) IronWarningCard(w),
                  ],
                  IronStage(title: l.ironHi, question: on ? l.ironCenterQ : l.ironMeetBody),
                  if (on)
                    IronComposer(
                      controller: _ask,
                      hint: l.askIronHint,
                      maxLength: 400,
                      maxLines: 5,
                      sendEmpty: true,
                      sendLabel: l.ironGetProgram,
                      onSend: _send,
                    )
                  else
                    AiBtn(
                      colors: ironGradient,
                      foreground: Colors.white,
                      label: l.ironTurnOn,
                      onTap: () => ref.read(ironOnProvider.notifier).set(true),
                    ),
                  if (tip != null) ...[head(l.ironTodayTip), IronSays(child: IronBubble('${tip.title}. ${tip.tip}'))],
                  head(l.ironCanDo),
                  _Grid(
                    children: [
                      _Shortcut(
                        icon: 'dumb',
                        title: l.ironGetProgram,
                        sub: l.ironProgramSub,
                        onTap: () => context.push('/iron'),
                      ),
                      _Shortcut(
                        icon: 'repeat',
                        title: l.ironShortRoutine,
                        sub: l.describeItSub,
                        onTap: () => context.push('/routine/ai'),
                      ),
                      _Shortcut(
                        icon: 'chart',
                        title: l.ironWeekReview,
                        sub: l.ironWeekReviewSub,
                        onTap: () => context.push('/iron/review'),
                      ),
                      _Shortcut(
                        icon: 'shield',
                        title: l.healthProfileTitle,
                        sub: l.ironEditHealthSub,
                        onTap: () => context.push('/iron/health'),
                      ),
                    ],
                  ),
                  VList(
                    children: [
                      VItem(
                        onTap: () => context.push('/iron/settings'),
                        children: [
                          VIcon('gear', size: 19, color: Volt.t3),
                          ItemText(l.ironSettings, sub: ironReadsLine(l, ref)),
                          VIcon('fwd', size: 14, color: Volt.t4),
                        ],
                      ),
                    ],
                  ),
                  if (history.isNotEmpty) ...[
                    head(l.ironHistory),
                    VList(
                      children: [
                        for (final e in history.take(8))
                          VItem(
                            onTap: () =>
                                context.push(e.kind == IronHistoryEntry.review ? '/iron/review' : '/iron', extra: e),
                            children: [
                              VIcon(
                                e.kind == IronHistoryEntry.review ? 'chart' : 'dumb',
                                size: 18,
                                color: ironGradient[1],
                              ),
                              ItemText(
                                e.title,
                                sub: e.kind == IronHistoryEntry.review
                                    ? l.histWeekOf(fmtDay(context, DateTime.parse(e.day)))
                                    : '${l.ironGetProgram} · ${fmtDay(context, DateTime.parse(e.day))}',
                              ),
                              VIcon('fwd', size: 14, color: Volt.t4),
                            ],
                          ),
                      ],
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Muted('${l.ironPhotosNever} ${l.ironNotDoctor}', size: 11.5, align: TextAlign.center),
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

/// Two shortcuts a row.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i += 2) ...[
        if (i > 0) const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ],
          ),
        ),
      ],
    ],
  );
}

/// One thing Iron does: an icon on Iron's red, a name and a line on it.
class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.title, required this.sub, required this.onTap});
  final String icon;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final red = ironGradient[1];
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: Pressable(
        radius: 20,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: smooth(
            BoxDecoration(
              color: Volt.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Volt.line),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: red.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: VIcon(icon, size: 18, color: red),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(fontSize: 15, height: 1.25, fontWeight: FontWeight.w700, color: Volt.t1),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, height: 1.35, color: Volt.t3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
