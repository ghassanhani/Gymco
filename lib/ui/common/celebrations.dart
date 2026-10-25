import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

import '../../app.dart' show routerProvider;
import '../../data/models.dart';
import '../../domain/streak.dart';
import '../../l10n/app_localizations.dart';
import '../../state/awards_providers.dart';
import '../../state/celebration_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';
import '../progress/awards_screen.dart' show Medal, awardDesc, awardName;
import '../progress/badge3d.dart';
import 'format.dart';

const _seenKey = 'awardsSeen';

/// Watches the streak and, when a log moves today forward or earns an award,
/// shows the flame sheet or the award moment over whatever screen is open.
/// They are drawn here, above the navigator, so a screen closing right after
/// it logs can never take the celebration down with it.
class CelebrationHost extends ConsumerStatefulWidget {
  const CelebrationHost({super.key});

  @override
  ConsumerState<CelebrationHost> createState() => _CelebrationHostState();
}

class _CelebrationHostState extends ConsumerState<CelebrationHost> with WidgetsBindingObserver {
  DayProgress? _last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The phone's back gesture closes the celebration, not the screen under it.
  @override
  Future<bool> didPopRoute() async {
    if (_showing == null) return false;
    _close();
    return true;
  }

  final _queue = <Celebration>[];
  Celebration? _showing;

  void _onStreak(StreakInfo info) {
    final prefs = ref.read(prefsProvider);
    final now = ref.read(clockProvider)();
    final after = DayProgress.of(info, dayKey(now));
    final saved = prefs.getStringList(_seenKey);
    final r = decideCelebrations(
      // Before the first ever run, everything already earned counts as seen.
      before: saved == null ? null : _last,
      after: after,
      awards: info.awards,
      seen: {...?saved},
    );
    _last = after;
    prefs.setStringList(_seenKey, r.seen.toList()..sort());
    if (r.show.isEmpty) return;
    _queue.addAll(r.show);
    // A beat after the log, so the screen it came from has settled.
    Future<void>.delayed(const Duration(milliseconds: 450), _next);
  }

  void _next() {
    if (!mounted || _showing != null || _queue.isEmpty) return;
    final c = _queue.removeAt(0);
    setState(() => _showing = c);
    if (c is AwardCelebration) {
      HapticFeedback.heavyImpact();
      CelebrationSound.play('award');
    } else if (c is DayCelebration && c.justKept) {
      HapticFeedback.mediumImpact();
      CelebrationSound.play('day');
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _close() {
    setState(() => _showing = null);
    Future<void>.delayed(const Duration(milliseconds: 320), _next);
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(celebrationsOnProvider)) {
      ref.listen(streakProvider, (_, next) {
        final info = next.value;
        if (info != null && !next.isLoading) _onStreak(info);
      });
    }
    final c = _showing;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
      child: c == null
          ? const SizedBox.shrink()
          : KeyedSubtree(
              key: ObjectKey(c),
              child: Material(
                type: MaterialType.transparency,
                child: switch (c) {
                  DayCelebration() => DaySheet(celebration: c, onClose: _close),
                  AwardCelebration() => AwardMoment(celebration: c, onClose: _close),
                },
              ),
            ),
    );
  }
}

/// Short sounds for a kept day and an award. They play as ambient sound, so
/// the phone's silent switch and its volume decide, and never in tests.
abstract final class CelebrationSound {
  static Future<void> play(String name) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final p = AudioPlayer();
      await p.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
      p.onPlayerComplete.first.then((_) => p.dispose());
      await p.play(AssetSource('sounds/$name.wav'));
    } catch (_) {
      // A sound that won't play is never worth an error.
    }
  }
}

// ---------------------------------------------------------------- the flame

const flameOrange = Color(0xFFFF8A00);

/// The streak flame, from assets/animations/fire.json (a looping Lottie):
/// grey, filling from the bottom with [fill] (0 to 1) in its own colours,
/// fully lit and glowing when the day is kept. [animate] off holds its first
/// frame, for the small flames in the week.
class StreakFlame extends StatefulWidget {
  const StreakFlame({super.key, required this.fill, required this.size, this.glow = false, this.animate = true});
  final double fill;
  final double size;
  final bool glow;
  final bool animate;

  // Read once for every flame on screen.
  static final _composition = AssetLottie('assets/animations/fire.json').load();

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame> with SingleTickerProviderStateMixin {
  // The grey and the lit layers share one clock, so their outlines match.
  late final _clock = AnimationController(vsync: this);

  // The flame takes the middle third of the animation's square canvas.
  static const _zoom = 2.7;

  @override
  void initState() {
    super.initState();
    StreakFlame._composition.then((c) {
      if (!mounted) return;
      _clock.duration = c.duration;
      if (widget.animate && !(WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations)) {
        _clock.repeat();
      }
    });
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Widget _fire(LottieComposition c) {
    final size = widget.size;
    return ClipRect(
      child: SizedBox.square(
        dimension: size,
        child: OverflowBox(
          maxWidth: size * _zoom,
          maxHeight: size * _zoom,
          alignment: const Alignment(0, 0.1),
          child: Lottie(composition: c, controller: _clock, width: size * _zoom, height: size * _zoom),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final f = widget.fill.clamp(0.0, 1.0);
    return SizedBox.square(
      dimension: size,
      child: FutureBuilder<LottieComposition>(
        future: StreakFlame._composition,
        builder: (context, snap) {
          final c = snap.data;
          if (c == null) return const SizedBox.shrink();
          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              if (widget.glow)
                Positioned(
                  left: -size * 0.45,
                  right: -size * 0.45,
                  top: -size * 0.3,
                  bottom: -size * 0.3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          flameOrange.withValues(alpha: Volt.isLight ? 0.22 : 0.3),
                          flameOrange.withValues(alpha: 0),
                        ],
                        stops: const [0.15, 0.7],
                      ),
                    ),
                  ),
                ),
              // Unlit: the same flame in grey.
              if (f < 1)
                Opacity(
                  opacity: Volt.isLight ? 0.35 : 0.3,
                  child: ColorFiltered(colorFilter: _grey, child: _fire(c)),
                ),
              if (f > 0)
                ClipRect(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    // The flame runs from about 8% to 92% of the box, bottom up.
                    heightFactor: f >= 1 ? 1 : 0.08 + f * 0.84,
                    child: _fire(c),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

const _grey = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

// ---------------------------------------------------------------- the day sheet

/// After a log: the flame filling to where today stands, the streak, what is
/// done and what is left, and the week in flames.
class DaySheet extends ConsumerWidget {
  const DaySheet({super.key, required this.celebration, required this.onClose});
  final DayCelebration celebration;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = celebration.now;
    final info = ref.watch(streakProvider).value;
    final now = ref.watch(clockProvider)();
    final kept = celebration.justKept || p.kept;
    final missingMeal = [Meal.breakfast, Meal.lunch, Meal.dinner];
    final meals = ref.watch(dayEntriesProvider(p.day)).value ?? const <LogEntry>[];
    final have = {for (final e in meals) e.meal};
    final nextMeal = missingMeal.where((m) => !have.contains(m)).firstOrNull;
    final String sub = kept
        ? l.keepBurning
        : nextMeal != null
        ? l.logToKeep(mealName(l, nextMeal).toLowerCase(), p.dayNumber)
        : l.trainToKeep(p.plannedToday ?? l.workoutTask.toLowerCase(), p.dayNumber);
    final reduce = MediaQuery.disableAnimationsOf(context);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: Volt.isLight ? 0.32 : 0.55)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduce ? 0 : 1, end: 0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => FractionalTranslation(translation: Offset(0, t), child: child),
            child: Container(
              width: double.infinity,
              decoration: smooth(
                BoxDecoration(
                  color: Volt.sheet,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(Volt.rSheet)),
                  border: Volt.isLight ? Border(top: BorderSide(color: Volt.line)) : null,
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: smooth(BoxDecoration(color: Volt.line2, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 18),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduce ? p.fraction : celebration.from, end: p.fraction),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, f, _) {
                      final lit = f >= 0.999;
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(lit),
                        tween: Tween(begin: lit && !reduce ? 0.7 : 1, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (context, s, _) => Transform.scale(
                          scale: s,
                          child: StreakFlame(fill: f, size: 112, glow: lit),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  AnimatedNum(
                    p.dayNumber.toDouble(),
                    from: (kept && celebration.justKept ? p.dayNumber - 1 : p.dayNumber).toDouble(),
                    format: (_, v) => '${v.round()}',
                    style: numStyle(
                      58,
                      weight: FontWeight.w800,
                      color: kept ? flameOrange : Volt.t1,
                    ).copyWith(height: 1),
                  ),
                  Text(
                    l.streakDaysLabel,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kept ? flameOrange : Volt.t3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    kept ? l.dayKeptCheer(p.streak) : l.doneOfToday(p.done, DayProgress.total),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Volt.t1),
                  ),
                  const SizedBox(height: 6),
                  Muted(sub, size: 14, align: TextAlign.center),
                  const SizedBox(height: 18),
                  _Tasks(p: p, have: have),
                  if (info != null) ...[
                    const SizedBox(height: 18),
                    _FlameWeek(info: info, now: now, todayFill: p.fraction),
                  ],
                  const SizedBox(height: 22),
                  VBtn(label: l.continueBtn, onTap: onClose, expand: true),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tasks extends StatelessWidget {
  const _Tasks({required this.p, required this.have});
  final DayProgress p;
  final Set<Meal> have;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = [
      for (final m in [Meal.breakfast, Meal.lunch, Meal.dinner]) (mealName(l, m), have.contains(m)),
      (p.trained || !p.rest ? l.workoutTask : l.restDay, p.trained || p.rest),
    ];
    return Row(
      children: [
        for (final (i, (label, done)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: smooth(
                BoxDecoration(
                  color: done ? Volt.brandWash : Volt.card2,
                  borderRadius: BorderRadius.circular(14),
                  border: done ? Border.all(color: Volt.lime.withValues(alpha: 0.6)) : null,
                ),
              ),
              child: Column(
                children: [
                  Pop(
                    trigger: done,
                    child: VIcon(
                      done ? 'check' : 'plus',
                      size: 18,
                      color: done ? Volt.brandInk : Volt.t4,
                      strokeWidth: done ? 2.2 : 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: done ? Volt.t1 : Volt.t3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Monday to Sunday as small flames: lit when kept, today filled as far as it got.
class _FlameWeek extends StatelessWidget {
  const _FlameWeek({required this.info, required this.now, required this.todayFill});
  final StreakInfo info;
  final DateTime now;
  final double todayFill;

  @override
  Widget build(BuildContext context) {
    final loc = Localizations.localeOf(context).toString();
    final today = DateTime(now.year, now.month, now.day);
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          () {
            final d = DateTime(monday.year, monday.month, monday.day + i);
            final mark = info.state.marks[d];
            final isToday = d == today;
            final fill = mark == DayMark.kept ? 1.0 : (isToday ? todayFill : 0.0);
            return Column(
              children: [
                Text(
                  DateFormat.EEEEE(loc).format(d),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday ? Volt.t1 : Volt.t3,
                  ),
                ),
                const SizedBox(height: 6),
                mark == DayMark.frozen
                    ? SizedBox.square(
                        dimension: 28,
                        child: Center(child: VIcon('freeze', size: 18, color: Volt.blue)),
                      )
                    : StreakFlame(fill: fill, size: 28, animate: false),
              ],
            );
          }(),
      ],
    );
  }
}

// ---------------------------------------------------------------- the award moment

/// An award just earned: the badge spins in through falling confetti, with
/// its name and line, a way to the awards and a share.
class AwardMoment extends ConsumerWidget {
  const AwardMoment({super.key, required this.celebration, required this.onClose});
  final AwardCelebration celebration;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = celebration.award;
    final now = ref.watch(clockProvider)();
    final loc = Localizations.localeOf(context).toString();
    final name = awardName(l, a, now, loc);
    final date = DateFormat.yMMMMd(loc).format(a.earnedOn ?? now);
    final month = a.id == 'month' ? DateFormat.MMM(loc).format(now).toUpperCase() : null;
    final pad = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: Volt.bg,
      child: Stack(
        children: [
          const Positioned.fill(child: VScreen(child: SizedBox.expand())),
          const Positioned.fill(child: IgnorePointer(child: Confetti())),
          Padding(
            padding: EdgeInsets.fromLTRB(20, pad.top + 8, 20, pad.bottom + 20),
            child: Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        l.awardUnlockedEyebrow,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t3),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: onClose,
                          child: Text(
                            l.doneBtn,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Volt.t1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox.square(
                  dimension: 250,
                  child: Center(
                    child: badgeArt.containsKey(a.id)
                        ? Badge3D(
                            award: a,
                            size: 236,
                            month: month,
                            name: name,
                            date: date,
                            spinIn: !MediaQuery.disableAnimationsOf(context),
                          )
                        : Medal(award: a, size: 210, month: month),
                  ),
                ),
                const SizedBox(height: 28),
                Entrance(
                  delay: const Duration(milliseconds: 900),
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Volt.t1, height: 1.15),
                  ),
                ),
                const SizedBox(height: 10),
                Entrance(
                  delay: const Duration(milliseconds: 1050),
                  child: Muted(awardDesc(l, a, loc), size: 15, align: TextAlign.center),
                ),
                const Spacer(flex: 2),
                VBtn(
                  label: l.seeYourAwards,
                  icon: 'medal',
                  expand: true,
                  onTap: () {
                    onClose();
                    ref.read(routerProvider).push('/progress/award/${a.id}');
                  },
                ),
                const SizedBox(height: 10),
                VBtn(
                  label: l.shareAward,
                  kind: BtnKind.ghost,
                  expand: true,
                  onTap: () => SharePlus.instance.share(ShareParams(text: l.shareAwardText(name))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold and lime flakes drifting down, turning as they fall.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final _flakes = () {
    final r = math.Random(11);
    return List.generate(90, (_) => _Flake(r));
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_flakes, _c.value), size: Size.infinite),
    );
  }
}

class _Flake {
  _Flake(math.Random r)
    : x = r.nextDouble(),
      phase = r.nextDouble(),
      speed = 0.7 + r.nextDouble() * 0.6,
      sway = 6 + r.nextDouble() * 18,
      spin = (r.nextDouble() - 0.5) * 14,
      w = 3 + r.nextDouble() * 4,
      h = 6 + r.nextDouble() * 7,
      color = const [
        Color(0xFFFFC94A),
        Color(0xFFE8A93A),
        Color(0xFFFFE08A),
        Color(0xFFC6F432),
        Color(0xFFB07A2A),
      ][r.nextInt(5)];
  final double x, phase, speed, sway, spin, w, h;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.flakes, this.t);
  final List<_Flake> flakes;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final f in flakes) {
      final p = (t * f.speed + f.phase) % 1.0;
      final y = -20 + p * (size.height + 40);
      final x = f.x * size.width + math.sin((p + f.phase) * math.pi * 4) * f.sway;
      final a = (p + f.phase) * f.spin;
      // Turning in 3D: the flake narrows as it rolls over.
      final roll = math.cos(a * 1.3).abs().clamp(0.15, 1.0);
      paint.color = f.color.withValues(alpha: 0.9);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(a);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: f.w, height: f.h * roll),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
