import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/coach.dart';
import '../../domain/iron_rules.dart';
import '../../domain/session.dart';
import '../../domain/recovery.dart';
import '../../l10n/app_localizations.dart';
import '../../state/cloud_providers.dart';
import '../../state/coach_providers.dart';
import '../../state/health_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/iron_avatar.dart';
import '../food/add_food_screen.dart' show mealForHour;
import '../kit/kit.dart';
import '../train/iron_settings_screen.dart' show ironReadsLine;
import '../train/swap_pain.dart' show painAreaName;

/// Iron, the coach, on Today: once turned on, today's tip with the one
/// button that acts on it, and the way into a full program.
class IronCard extends ConsumerWidget {
  const IronCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (ref.watch(ironHiddenProvider) && !ref.watch(ironOnProvider)) return const SizedBox.shrink();
    final on = ref.watch(ironOnProvider);
    final signedIn = (ref.watch(accountProvider).value ?? ref.watch(cloudProvider).email) != null;

    if (!on || !signedIn) {
      return _Frame(
        trailing: on
            ? null
            : IconBtn(
                'close',
                label: l.ironHide,
                size: 30,
                iconSize: 14,
                color: Volt.t3,
                onTap: () => ref.read(ironHiddenProvider.notifier).hide(),
              ),
        children: [
          Text(
            l.ironMeetTitle,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Volt.t1),
          ),
          Muted(l.ironMeetBody, size: 13, color: Volt.t2),
          Muted(l.ironPrivacy, size: 11.5),
          AiBtn(
            colors: ironGradient,
            foreground: Colors.white,
            label: signedIn ? l.ironTurnOn : l.ironSignIn,
            onTap: () async {
              await ref.read(ironOnProvider.notifier).set(true);
              if (!signedIn && context.mounted) context.push('/account');
            },
          ),
        ],
      );
    }

    final warnings = ref.watch(ironWarningsProvider);
    final gear = IconBtn(
      'gear',
      label: l.ironSettings,
      size: 30,
      iconSize: 15,
      color: Volt.t3,
      onTap: () => context.push('/iron/settings'),
    );
    if (warnings.isNotEmpty) {
      // The alert sounds once a day for a given set of warnings, not on
      // every rebuild of Today.
      final prefs = ref.read(prefsProvider);
      final stamp = '${ref.watch(todayKeyProvider)}:${warnings.map((w) => w.id).join(',')}';
      final announce = prefs.getString('ironAlerted') != stamp;
      if (announce) prefs.setString('ironAlerted', stamp);
      return _Frame(
        mood: IronMood.alert,
        announce: announce,
        trailing: gear,
        children: [for (final w in warnings) _Warning(w)],
      );
    }

    final tip = ref.watch(ironTipProvider);
    final weekday = ref.watch(clockProvider)().weekday;
    return _Frame(
      trailing: gear,
      mood: tip.isLoading
          ? IronMood.thinking
          : tip.value == null
          ? IronMood.idle
          : tip.value!.action == IronAction.rest || ref.watch(recoveryProvider).value?.readiness == Readiness.easy
          ? IronMood.sleepy
          : IronMood.happy,
      children: [
        if (tip.isLoading)
          Row(
            children: [
              SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Volt.t3)),
              const SizedBox(width: 10),
              Expanded(child: Muted(l.ironThinking, size: 13)),
            ],
          )
        else if (tip.value case final t?) ...[
          Text(
            t.title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.2, color: Volt.t1),
          ),
          Muted(t.tip, size: 13.5, color: Volt.t2),
        ] else
          Muted(l.ironNoTip, size: 13),
        Row(
          children: [
            if (tip.value case final t? when _act(context, ref, t.action) != null) ...[
              Expanded(
                child: VBtn(
                  label: _label(l, t.action),
                  kind: BtnKind.ghost,
                  small: true,
                  minHeight: 40,
                  expand: true,
                  onTap: _act(context, ref, t.action),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: AiBtn(
                label: l.ironGetProgram,
                small: true,
                colors: ironGradient,
                foreground: Colors.white,
                onTap: () => context.push('/iron'),
              ),
            ),
          ],
        ),
        if (weekday == DateTime.sunday || weekday == DateTime.monday)
          VItem(
            onTap: () => context.push('/iron/review'),
            color: ironGradient[1].withValues(alpha: 0.08),
            children: [
              VIcon('chart', size: 17, color: ironGradient[1]),
              ItemText(l.ironWeekReview, sub: l.ironWeekReviewSub),
              VIcon('fwd', size: 14, color: Volt.t4),
            ],
          ),
        Muted(ironReadsLine(l, ref), size: 11),
      ],
    );
  }

  static String _label(AppLocalizations l, IronAction a) => switch (a) {
    IronAction.logFood => l.actLogFood,
    IronAction.startWorkout => l.actStartWorkout,
    IronAction.drinkWater => l.actDrinkWater,
    IronAction.weighIn => l.actWeighIn,
    IronAction.rest => l.actRest,
    IronAction.walk => l.actWalk,
    IronAction.none => '',
  };

  /// What the tip's button does; null when there is nothing to tap.
  static VoidCallback? _act(BuildContext context, WidgetRef ref, IronAction a) => switch (a) {
    IronAction.logFood => () => context.push('/add/${mealForHour(ref.read(clockProvider)().hour).name}'),
    IronAction.startWorkout || IronAction.rest => () => context.go('/train'),
    IronAction.weighIn => () => context.go('/progress'),
    IronAction.drinkWater => () async {
      await ref.read(waterProvider(ref.read(todayKeyProvider)).notifier).add(250);
      HapticFeedback.lightImpact();
      if (context.mounted) showVToast(context, AppLocalizations.of(context).waterAddedMl(250));
    },
    IronAction.walk || IronAction.none => null,
  };
}

/// One warning sign: what the rule saw, what to do, and a doctor when it
/// matters. Iron stops pushing while one is showing.
class _Warning extends ConsumerWidget {
  const _Warning(this.signal);
  final IronSignal signal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final v = signal.values;
    String area() => painAreaName(l, PainArea.values.byName('${v['area']}')).toLowerCase();
    final (title, body) = switch (signal.id) {
      'rhr_high' => (l.warnRhrTitle, l.warnRhrBody(v['now']! as int, v['usual']! as int)),
      'fast_loss' => (l.warnFastLossTitle, l.warnFastLossBody(((v['pct_week']! as num).abs()).toString())),
      'under_eating' => (l.warnUnderTitle, l.warnUnderBody),
      'sharp_pain' => (l.warnSharpTitle, l.warnSharpBody(area())),
      'repeated_pain' => (l.warnRepeatTitle(area()), l.warnRepeatBody),
      _ => (l.warnClearTitle, l.warnClearBody),
    };
    final clearance = signal.id == 'needs_clearance';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Volt.warn.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Volt.warn.withValues(alpha: 0.4)),
      ),
      child: GapCol(
        gap: 8,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VIcon('warn', size: 18, color: Volt.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.25, color: Volt.t1),
                ),
              ),
            ],
          ),
          Muted(body, size: 13, color: Volt.t2),
          Muted(l.ironNotDoctor, size: 11.5),
          Row(
            children: [
              Expanded(
                child: VBtn(
                  label: l.warnGotIt,
                  kind: BtnKind.ghost,
                  small: true,
                  minHeight: 38,
                  expand: true,
                  onTap: () => ref.read(ironDismissedProvider.notifier).dismiss(signal.id),
                ),
              ),
              if (clearance) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: VBtn(
                    label: l.warnCleared,
                    small: true,
                    minHeight: 38,
                    expand: true,
                    onTap: () {
                      final h = ref.read(healthProfileProvider);
                      if (h != null) ref.read(healthProfileProvider.notifier).save(h.copyWith(cleared: true));
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The card itself: a thin AI-gradient edge, Iron's mark and name on top.
class _Frame extends StatelessWidget {
  const _Frame({required this.children, this.trailing, this.mood = IronMood.idle, this.announce = false});
  final List<Widget> children;
  final Widget? trailing;
  final IronMood mood;
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [for (final c in ironGradient) c.withValues(alpha: 0.9)]),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(18.5)),
        child: GapCol(
          gap: 10,
          cross: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IronAvatar(mood: mood, size: 44, announce: announce),
                const SizedBox(width: 10),
                Expanded(
                  child: GapCol(
                    gap: 0,
                    children: [
                      AiText(
                        l.ironName,
                        colors: ironGradient,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Muted(l.ironRole, size: 11.5),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
