import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../domain/checkin.dart';
import '../../domain/energy.dart';
import '../../l10n/app_localizations.dart';
import '../../state/progress_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

/// The weekly check-in. What the week measured, and next week's target.
class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

enum _Choice { recommended, alternative, keep }

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  _Choice _choice = _Choice.recommended;

  String _n(num v) => fmtInt(context, v);
  String _signed(double v, {int digits = 0}) =>
      '${v > 0 ? '+' : (v < 0 ? '−' : '')}${digits == 0 ? _n(v.abs()) : fmtDec(context, v.abs(), digits: digits)}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = ref.watch(checkInProvider).value;
    final p = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();
    if (c == null || p == null) return const Scaffold(body: VScreen(child: SizedBox.shrink()));
    final loc = Localizations.localeOf(context).toString();
    final from = now.subtract(const Duration(days: 6));
    final week = now.difference(p.startedOn).inDays ~/ 7 + 1;
    final range = '${DateFormat.MMMd(loc).format(from)} – ${DateFormat.MMMd(loc).format(now)}';
    final sub = l.checkInSub(range, week);

    final (title, body, ghost, primary, onPrimary) = switch (c.kind) {
      CheckInKind.notEnough => (l.yourWeek, _notEnough(c), null, l.doneBtn, () => context.pop()),
      CheckInKind.onPlan => (l.yourWeek, _onPlan(c), l.adjustBtn, l.acceptTargets, () => _accept(c)),
      CheckInKind.fast => (
        l.yourWeek,
        _fast(c),
        l.laterBtn,
        _choice == _Choice.recommended ? l.applyKcal(_signed(c.fastExtraKcal)) : l.applyChoice,
        () => _applyFast(c),
      ),
      CheckInKind.stall => (
        l.flatWeeks,
        _stall(c),
        l.notNow,
        _choice == _Choice.recommended ? l.startBreak : l.applyChoice,
        () => _applyStall(c),
      ),
    };

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: title, sub: sub, titleSize: 20),
            Expanded(child: Pad(bottom: 24, children: body)),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: Row(
                children: [
                  if (ghost != null) ...[
                    Expanded(
                      flex: 10,
                      child: VBtn(
                        label: ghost,
                        kind: BtnKind.ghost,
                        expand: true,
                        onTap: () => c.kind == CheckInKind.onPlan ? context.push('/onboarding') : context.pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    flex: 16,
                    child: VBtn(label: primary, expand: true, onTap: onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(CheckIn c) async {
    final l = AppLocalizations.of(context);
    await ref.read(progressActionsProvider).acceptCheckIn(c);
    if (!mounted) return;
    showVToast(context, l.targetsUpdated(_n(c.nextKcal)));
    context.pop();
  }

  Future<void> _applyFast(CheckIn c) async {
    final l = AppLocalizations.of(context);
    final a = ref.read(progressActionsProvider);
    switch (_choice) {
      case _Choice.recommended:
        await a.shiftTarget(c.fastExtraKcal);
      case _Choice.alternative:
        await a.shiftTarget((c.expenditure ?? c.currentKcal) - c.currentKcal);
      case _Choice.keep:
        await a.shiftTarget(0);
    }
    if (!mounted) return;
    showVToast(
      context,
      _choice == _Choice.keep ? l.askedNextWeek : l.targetsUpdated(_n(ref.read(profileProvider)!.targetKcal)),
    );
    context.pop();
  }

  Future<void> _applyStall(CheckIn c) async {
    final l = AppLocalizations.of(context);
    final a = ref.read(progressActionsProvider);
    switch (_choice) {
      case _Choice.recommended:
        await a.shiftTarget((c.expenditure ?? c.currentKcal) - c.currentKcal);
      case _Choice.alternative:
        if (mounted) context.go('/today');
        return;
      case _Choice.keep:
        await a.shiftTarget(-150);
    }
    if (!mounted) return;
    showVToast(context, l.targetsUpdated(_n(ref.read(profileProvider)!.targetKcal)));
    context.pop();
  }

  Widget _tile(String k, String v, String sub, {Color? subColor}) => Expanded(
    child: VCard(
      tight: true,
      child: GapCol(
        gap: 4,
        children: [
          Muted(k),
          Text(v, textDirection: TextDirection.ltr, style: numStyle(16)),
          Text(sub, style: TextStyle(fontSize: 11, color: subColor ?? Volt.t3)),
        ],
      ),
    ),
  );

  Widget _rateTiles(CheckIn c) {
    final l = AppLocalizations.of(context);
    final r = c.observedRatePct;
    final rateSub = r == null
        ? l.needsTwoWeighIns
        : (c.rateOnPlan ? l.onPlan : (r.abs() > c.goalRatePct.abs() ? l.fasterThanPlan : l.slowerThanPlan));
    return Row(
      children: [
        _tile(
          l.rateVsGoal,
          r == null
              ? '— / ${fmtDec(context, c.goalRatePct.abs(), digits: 2)}'
              : '${fmtDec(context, r.abs(), digits: 2)} / ${fmtDec(context, c.goalRatePct.abs(), digits: 2)}',
          rateSub,
          subColor: c.rateOnPlan ? Volt.ok : Volt.t3,
        ),
        const SizedBox(width: 10),
        _tile(l.daysLogged, l.nOfSeven(c.daysLogged), c.daysLogged == 7 ? l.allSevenDays : l.fullDaysOnly),
      ],
    );
  }

  List<Widget> _notEnough(CheckIn c) {
    final l = AppLocalizations.of(context);
    return [
      VCard(
        child: GapCol(
          gap: 10,
          cross: CrossAxisAlignment.stretch,
          children: [
            Muted(l.measuredExpenditure),
            Text(
              l.notMeasuredYet,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Volt.t1),
            ),
            Muted(l.notEnoughBody(c.daysToMeasure), color: Volt.t2),
            VBar(fraction: math.min(1, c.usableDays / minWindowDays), color: Volt.lime),
          ],
        ),
      ),
      _rateTiles(c),
      _targets(c, unchanged: true),
    ];
  }

  List<Widget> _onPlan(CheckIn c) {
    final l = AppLocalizations.of(context);
    final e = c.expenditure!;
    final prev = c.previousExpenditure;
    final diff = prev == null ? null : (e - prev);
    final change = c.trendChangeKg;
    final explain = c.avgIntake == null || change == null
        ? l.expenditureShort(_n(e))
        : (change <= 0
              ? l.expenditureFell(_n(c.avgIntake!), fmtDec(context, change.abs(), digits: 2), _n(e))
              : l.expenditureRose(_n(c.avgIntake!), fmtDec(context, change.abs(), digits: 2), _n(e)));
    return [
      VCard(
        child: GapCol(
          gap: 12,
          cross: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GapCol(
                    gap: 3,
                    children: [
                      Muted(l.measuredExpenditure),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(_n(e), style: numStyle(28)),
                          const SizedBox(width: 8),
                          Text(l.kcal, style: TextStyle(fontSize: 13, color: Volt.t2)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (diff != null && diff.abs() >= 10)
                  VChip(
                    label: _n(diff.abs()),
                    icon: diff > 0 ? 'up' : 'down',
                    flat: true,
                    color: Volt.okWash,
                    textColor: Volt.ok,
                  ),
              ],
            ),
            Muted(explain, color: Volt.t2),
          ],
        ),
      ),
      _rateTiles(c),
      const _DietMeetsTraining(),
      _targets(c),
    ];
  }

  Widget _targets(CheckIn c, {bool unchanged = false}) {
    final l = AppLocalizations.of(context);
    final m = c.nextMacros;
    return VCard(
      child: GapCol(
        gap: 12,
        cross: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  l.nextWeekTargets,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
              ),
              Muted(c.change == 0 ? l.noChange : l.kcalChange(_signed(c.change))),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (c.change != 0) ...[
                Text(
                  _n(c.currentKcal),
                  style: numStyle(
                    15,
                    weight: FontWeight.w400,
                    color: Volt.t4,
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
                const SizedBox(width: 10),
                VIcon('fwd', size: 15, color: Volt.t3),
                const SizedBox(width: 10),
              ],
              Text(_n(c.nextKcal), style: numStyle(26)),
              const SizedBox(width: 8),
              Text(l.kcal, style: TextStyle(fontSize: 13, color: Volt.t2)),
            ],
          ),
          Row(
            children: [
              for (final (i, (k, v)) in [('P', m.protein), ('C', m.carbs), ('F', m.fat)].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: smooth(
                      BoxDecoration(
                        color: Volt.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Volt.line),
                      ),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: '$k ',
                        style: TextStyle(fontSize: 12, color: Volt.t2),
                        children: [
                          TextSpan(
                            text: '${_n(v)} ${l.grams}',
                            style: numStyle(12, color: Volt.t1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Muted(unchanged ? l.targetsHoldNote : l.targetsMoveNote),
        ],
      ),
    );
  }

  Widget _option(_Choice k, String title, String sub) {
    final on = _choice == k;
    return Pressable(
      onTap: () => setState(() => _choice = k),
      scale: 0.99,
      label: title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: smooth(
          BoxDecoration(
            color: on ? Volt.brandWash : Volt.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? Volt.lime : Volt.line, width: 1.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GapCol(
                gap: 3,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                  ),
                  Muted(sub),
                ],
              ),
            ),
            if (on) const Padding(padding: EdgeInsets.only(top: 2), child: Pick(on: true)),
          ],
        ),
      ),
    );
  }

  Widget _floorNote() {
    final l = AppLocalizations.of(context);
    return VCard(
      tight: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1),
            child: VIcon('info', size: 17, color: Volt.t3),
          ),
          const SizedBox(width: 10),
          Expanded(child: Muted(l.floorWarnNote(_n(defaultKcalFloor)), color: Volt.t2)),
        ],
      ),
    );
  }

  List<Widget> _fast(CheckIn c) {
    final l = AppLocalizations.of(context);
    final r = c.observedRatePct!.abs();
    return [
      VCard(
        color: Volt.warnWash,
        border: Border.all(color: Volt.warnEdge),
        child: GapCol(
          gap: 12,
          cross: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Volt.warnEdge, shape: BoxShape.circle),
                  child: Center(child: VIcon('warn', size: 20, color: Volt.warn)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GapCol(
                    gap: 3,
                    children: [
                      Text(l.fasterThanPlanned, style: TextStyle(fontSize: 12, color: Volt.warn)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${fmtDec(context, r, digits: 2)} %',
                            textDirection: TextDirection.ltr,
                            style: numStyle(26),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(l.perWeekLbl, style: TextStyle(fontSize: 13, color: Volt.t2)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              l.fastBody(fmtDec(context, c.goalRatePct.abs(), digits: 1)),
              style: TextStyle(fontSize: 13, height: 1.5, color: Volt.t2),
            ),
          ],
        ),
      ),
      Row(
        children: [
          _tile(l.intakeLbl, c.avgIntake == null ? '—' : _n(c.avgIntake!), l.floorIs(_n(defaultKcalFloor))),
          const SizedBox(width: 10),
          _tile(l.measuredShort, _n(c.expenditure!), l.kcalADay),
        ],
      ),
      VCard(
        child: GapCol(
          gap: 12,
          cross: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.whatToDo,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
            ),
            _option(
              _Choice.recommended,
              l.eatMore(_n(c.fastExtraKcal)),
              l.eatMoreSub(fmtDec(context, c.goalRatePct.abs(), digits: 1)),
            ),
            _option(_Choice.alternative, l.twoWeeksMaintenance, l.maintenanceThenResume),
            _option(_Choice.keep, l.keepGoingAsIAm, l.askedAgain),
          ],
        ),
      ),
      _floorNote(),
    ];
  }

  List<Widget> _stall(CheckIn c) {
    final l = AppLocalizations.of(context);
    final p = ref.read(profileProvider)!;
    final weeks = ref.read(clockProvider)().difference(p.startedOn).inDays ~/ 7;
    return [
      VCard(
        child: Text(l.stallBody(weeks), style: TextStyle(fontSize: 13, height: 1.5, color: Volt.t2)),
      ),
      VCard(
        child: GapCol(
          gap: 12,
          cross: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.threeOptions,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
            ),
            _option(_Choice.recommended, l.twoWeeksMaintenance, l.maintenanceSub(_n(c.expenditure!))),
            _option(_Choice.alternative, l.checkLogging, l.checkLoggingSub),
            _option(_Choice.keep, l.cut150, l.cut150Sub),
          ],
        ),
      ),
      VCard(
        tight: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1),
              child: VIcon('info', size: 17, color: Volt.t3),
            ),
            const SizedBox(width: 10),
            Expanded(child: Muted(l.dietBreakEvidence, color: Volt.t2)),
          ],
        ),
      ),
    ];
  }
}

/// On a cut, whether strength is holding: the most-trained lifts' change.
class _DietMeetsTraining extends ConsumerWidget {
  const _DietMeetsTraining();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = ref.watch(profileProvider);
    final lifts = (ref.watch(liftTrendsProvider).value ?? const <LiftTrend>[])
        .where((t) => t.changePct != null)
        .take(3)
        .toList();
    if (p == null || !p.goal.losing || lifts.isEmpty) return const SizedBox.shrink();
    final holding = lifts.every((t) => t.changePct! > -1);
    return VCard(
      color: Volt.brandWash,
      border: Border.all(color: Volt.brandEdge),
      child: GapCol(
        gap: 10,
        cross: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(l.dietMeetsTraining, color: Volt.brandInk),
          Text(
            holding ? l.strengthHolding : l.strengthSlipping,
            style: TextStyle(fontSize: 13, height: 1.55, color: Volt.t1),
          ),
          Row(
            children: [
              for (final (i, t) in lifts.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                    alignment: Alignment.center,
                    decoration: smooth(BoxDecoration(color: Volt.bg, borderRadius: BorderRadius.circular(12))),
                    child: Text.rich(
                      TextSpan(
                        text: '${t.exercise.shortName.split(' ').last} ',
                        style: TextStyle(fontSize: 12, color: Volt.t2),
                        children: [
                          TextSpan(
                            text: '${t.changePct! >= 0 ? '+' : '−'}${fmtDec(context, t.changePct!.abs())}%',
                            style: numStyle(12, color: t.changePct! > 0.05 ? Volt.ok : Volt.t2),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
