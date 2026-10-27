import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/site.dart';
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
          Semantics(
            link: true,
            label: '${l.ironTermsLine} ${l.readTerms}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => openSite('terms'),
              child: Text.rich(
                TextSpan(
                  text: '${l.ironTermsLine} ',
                  children: [
                    TextSpan(
                      text: l.readTerms,
                      style: TextStyle(color: ironGradient[1], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 11.5, height: 1.4, color: Volt.t3),
              ),
            ),
          ),
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
    // Everything else Iron does lives in the Iron Center.
    final gear = IconBtn(
      'fwd',
      label: l.ironCenter,
      size: 30,
      iconSize: 15,
      color: Volt.t3,
      onTap: () => context.push('/iron/home'),
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
        onOpen: () => context.push('/iron/home'),
        children: [for (final w in warnings) IronWarningCard(w)],
      );
    }

    final tips = ref.watch(ironTipProvider);
    final list = tips.value ?? const <IronTip>[];
    final done = ref.watch(ironTipsDoneProvider);
    final allDone = list.isNotEmpty && list.indexed.every((e) => done.contains(e.$1));
    final weekday = ref.watch(clockProvider)().weekday;
    final first = list.firstOrNull;

    Widget extra({required String icon, required String title, required String sub, required String go}) => GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: ironGradient[1].withValues(alpha: 0.12), shape: BoxShape.circle),
              child: VIcon(icon, size: 17, color: ironGradient[1]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.2, color: Volt.t1),
              ),
            ),
          ],
        ),
        Muted(sub, size: 13.5, color: Volt.t2),
        VBtn(
          label: l.ironOpen,
          kind: BtnKind.ghost,
          small: true,
          minHeight: 40,
          expand: true,
          onTap: () => context.push(go),
        ),
      ],
    );

    return _Frame(
      trailing: gear,
      onOpen: () => context.push('/iron/home'),
      mood: tips.isLoading
          ? IronMood.thinking
          : first == null
          ? IronMood.idle
          : allDone
          ? IronMood.cheer
          : first.action == IronAction.rest || ref.watch(recoveryProvider).value?.readiness == Readiness.easy
          ? IronMood.sleepy
          : IronMood.happy,
      children: [
        if (list.isNotEmpty) _Progress(done: done, total: list.length),
        _Deck(
          pages: [
            if (tips.isLoading)
              Row(
                key: const ValueKey('loading'),
                children: [
                  SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Volt.t3)),
                  const SizedBox(width: 10),
                  Expanded(child: Muted(l.ironThinking, size: 13)),
                ],
              )
            else if (list.isEmpty)
              Muted(l.ironNoTip, key: const ValueKey('none'), size: 13),
            for (final (i, t) in list.indexed) _TipPage(t, index: i, done: done.contains(i), key: ValueKey('tip$i')),
            if (weekday == DateTime.sunday || weekday == DateTime.monday)
              KeyedSubtree(
                key: const ValueKey('review'),
                child: extra(icon: 'chart', title: l.ironWeekReview, sub: l.ironWeekReviewSub, go: '/iron/review'),
              ),
            KeyedSubtree(
              key: const ValueKey('program'),
              child: extra(icon: 'dumb', title: l.ironProgramTitle, sub: l.ironProgramSub, go: '/iron'),
            ),
          ],
        ),
        const _HomeAsk(),
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

/// Today's tips, one at a time: swipe sideways or tap a dot for the next,
/// each with the button that acts on it.
/// Today's tips with Iron's other cards after them, one at a time: swipe
/// sideways or tap a dot for the next.
class _Deck extends StatefulWidget {
  const _Deck({required this.pages});
  final List<Widget> pages;

  @override
  State<_Deck> createState() => _DeckState();
}

class _DeckState extends State<_Deck> {
  var _at = 0;
  var _forward = true;

  void _go(int i) {
    if (i < 0 || i >= widget.pages.length || i == _at) return;
    HapticFeedback.selectionClick();
    setState(() {
      _forward = i > _at;
      _at = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = widget.pages;
    final at = _at.clamp(0, pages.length - 1);
    final page = pages[at];
    if (pages.length == 1) return page;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      label: l.ironTipOf(at + 1, pages.length),
      onIncrease: at + 1 < pages.length ? () => _go(at + 1) : null,
      onDecrease: at > 0 ? () => _go(at - 1) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 150) return;
          // Swiping towards the start shows the next one, either way round.
          final next = (v < 0) != rtl;
          _go(at + (next ? 1 : -1));
        },
        child: GapCol(
          gap: 10,
          cross: CrossAxisAlignment.stretch,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (current, previous) =>
                    Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                transitionBuilder: (child, anim) {
                  final incoming = child.key == page.key;
                  final from = (incoming == _forward ? 0.18 : -0.18) * (rtl ? -1 : 1);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: Offset(from, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  );
                },
                child: page,
              ),
            ),
            _Dots(count: pages.length, at: at, onTap: _go),
          ],
        ),
      ),
    );
  }
}

/// One of today's tips: what to do, a tick to mark it done, and the button
/// that does it, which ticks it too.
class _TipPage extends ConsumerWidget {
  const _TipPage(this.tip, {required this.index, required this.done, super.key});
  final IronTip tip;
  final int index;
  final bool done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final act = IronCard._act(context, ref, tip.action);
    final mark = ref.read(ironTipsDoneProvider.notifier);
    return GapCol(
      gap: 10,
      cross: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                tip.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: done ? Volt.t3 : Volt.t1,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: Volt.t3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Tick(
              done: done,
              label: done ? l.ironTipUndo : l.ironTipMarkDone,
              onTap: () {
                if (!done) HapticFeedback.mediumImpact();
                mark.set(index, !done);
              },
            ),
          ],
        ),
        Muted(tip.tip, size: 13.5, color: done ? Volt.t3 : Volt.t2),
        if (act != null && !done)
          VBtn(
            label: IronCard._label(l, tip.action),
            kind: BtnKind.ghost,
            small: true,
            minHeight: 40,
            expand: true,
            onTap: () {
              mark.set(index, true);
              act();
            },
          ),
      ],
    );
  }
}

/// The round tick on a tip; filled once it is done.
class _Tick extends StatelessWidget {
  const _Tick({required this.done, required this.label, required this.onTap});
  final bool done;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      checked: done,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done ? LinearGradient(colors: ironGradient) : null,
              border: done ? null : Border.all(color: Volt.t4, width: 1.5),
            ),
            child: AnimatedScale(
              scale: done ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: const VIcon('check', size: 15, color: Colors.white),
            ),
          ),
        ),
      ),
    ),
  );
}

/// How many of today's tips are done, as a line and a bar of one piece a tip.
class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});
  final Set<int> done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final count = done.where((i) => i < total).length;
    final all = count == total;
    return GapCol(
      gap: 6,
      cross: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                all ? l.ironTipsAllDone : l.ironTodayTips,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: all ? ironGradient[1] : Volt.t3),
              ),
            ),
            Text(
              l.ironTipsDone(count, total),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Volt.t2),
            ),
          ],
        ),
        Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: done.contains(i) ? LinearGradient(colors: ironGradient) : null,
                    color: done.contains(i) ? null : Volt.t4.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Which tip is showing; each dot opens its tip.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.at, required this.onTap});
  final int count;
  final int at;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Tooltip(
            message: l.ironTipOf(i + 1, count),
            excludeFromSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: i == at ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: i == at ? LinearGradient(colors: ironGradient) : null,
                    color: i == at ? null : Volt.t4.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One warning sign: what the rule saw, what to do, and a doctor when it
/// matters. Iron stops pushing while one is showing.
class IronWarningCard extends ConsumerWidget {
  const IronWarningCard(this.signal, {super.key});
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
      decoration: smooth(
        BoxDecoration(
          color: Volt.warn.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Volt.warn.withValues(alpha: 0.4)),
        ),
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

/// What Iron can do from Today, as choices rather than a message box: each
/// opens the one task.
class _HomeAsk extends StatelessWidget {
  const _HomeAsk();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget chip(String icon, String label, VoidCallback onTap) =>
        VChip(label: label, icon: icon, iconSize: 14, height: 38, onTap: onTap);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('dumb', l.ironGetProgram, () => context.push('/iron')),
        chip('repeat', l.ironShortRoutine, () => context.push('/routine/ai')),
        chip('chart', l.ironWeekReview, () => context.push('/iron/review')),
        chip('sparkles', l.requestFeature, () => context.push('/feature')),
      ],
    );
  }
}

/// The card itself: a thin AI-gradient edge, Iron's mark and name on top.
class _Frame extends StatelessWidget {
  const _Frame({required this.children, this.trailing, this.mood = IronMood.idle, this.announce = false, this.onOpen});
  final List<Widget> children;

  /// Tapping Iron's face or name opens the Iron Center, once Iron is on.
  final VoidCallback? onOpen;
  final Widget? trailing;
  final IronMood mood;
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: smooth(
        BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [for (final c in ironGradient) c.withValues(alpha: 0.9)]),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: smooth(BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(18.5))),
        child: GapCol(
          gap: 10,
          cross: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onOpen,
                    child: Row(
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
                      ],
                    ),
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
