import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../domain/energy.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

enum _Step { welcome, goal, body, activity, rate, targets }

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  Goal _goal = Goal.cut;
  Sex _sex = Sex.male;
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  ActivityLevel _activity = ActivityLevel.moderate;
  double _rate = 0.5;
  bool _consent = false;
  bool _noNumbers = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    if (p != null) {
      _goal = p.goal;
      _sex = p.sex;
      _age.text = '${p.ageYears}';
      _height.text = p.heightCm.round().toString();
      _weight.text = p.weightKg.toString();
      _activity = p.activity;
      _rate = p.ratePctPerWeek.abs() == 0 ? 0.5 : p.ratePctPerWeek.abs();
      _consent = true;
      _step = _Step.goal;
    }
    _noNumbers = ref.read(settingsProvider).noNumbers;
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.replaceAll(',', '.'));
  int? get _ageV => int.tryParse(_age.text);
  bool get _bodyValid {
    final a = _ageV, h = _num(_height), w = _num(_weight);
    return a != null && a >= 16 && a <= 90 && h != null && h >= 120 && h <= 230 && w != null && w >= 35 && w <= 250;
  }

  bool get _hasRate => _goal != Goal.maintain && _goal != Goal.recomp;
  double get _signedRate => clampRate(_goal, _rate);

  /// Set by hand on the last step; replaces the calculated split.
  Macros? _manual;

  ({double kcal, Macros macros}) _targets() {
    if (_manual != null) return (kcal: _manual!.kcal.roundToDouble(), macros: _manual!);
    final w = _num(_weight)!;
    final exp = seedExpenditure(
      sex: _sex,
      weightKg: w,
      heightCm: _num(_height)!,
      ageYears: _ageV!,
      activity: _activity,
    );
    final kcal = dailyTarget(expenditure: exp, weightKg: w, ratePctPerWeek: _signedRate).roundToDouble();
    return (kcal: kcal, macros: macroTargets(kcal: kcal, weightKg: w, goal: _goal));
  }

  void _go(_Step s) => setState(() => _step = s);

  Future<void> _editMacros() async {
    final l = AppLocalizations.of(context);
    var m = _targets().macros;
    Macros round(Macros x) =>
        Macros(protein: x.protein.roundToDouble(), carbs: x.carbs.roundToDouble(), fat: x.fat.roundToDouble());
    m = round(m);
    await showVSheet<void>(
      context,
      title: l.setMacrosManually,
      body: (ctx) => [
        StatefulBuilder(
          builder: (ctx, set) {
            Widget row(String label, double v, Color c, Macros Function(double) withV, double step) => VCard(
              tight: true,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 14, color: Volt.t2)),
                  ),
                  VStepper(
                    label: '${fmtInt(ctx, v)} ${l.grams}',
                    onMinus: v - step < 0 ? null : () => set(() => m = withV(v - step)),
                    onPlus: () => set(() => m = withV(v + step)),
                    minusLabel: l.lessOf(label.toLowerCase()),
                    plusLabel: l.moreOf(label.toLowerCase()),
                  ),
                ],
              ),
            );
            return GapCol(
              gap: 10,
              cross: CrossAxisAlignment.stretch,
              children: [
                row(l.protein, m.protein, Volt.protein, (v) => Macros(protein: v, carbs: m.carbs, fat: m.fat), 5),
                row(l.carbs, m.carbs, Volt.carbs, (v) => Macros(protein: m.protein, carbs: v, fat: m.fat), 5),
                row(l.fat, m.fat, Volt.fat, (v) => Macros(protein: m.protein, carbs: m.carbs, fat: v), 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Muted(
                    m.kcal < defaultKcalFloor
                        ? l.manualBelowFloor(fmtInt(ctx, m.kcal), fmtInt(ctx, defaultKcalFloor))
                        : l.manualKcal(fmtInt(ctx, m.kcal)),
                  ),
                ),
                VBtn(
                  label: l.useTheseMacros,
                  expand: true,
                  onTap: () {
                    setState(() => _manual = m);
                    Navigator.pop(ctx);
                  },
                ),
                if (_manual != null)
                  VBtn(
                    label: l.backToCalculated,
                    kind: BtnKind.ghost,
                    expand: true,
                    onTap: () {
                      setState(() => _manual = null);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _next() => _go(switch (_step) {
    _Step.welcome => _Step.goal,
    _Step.goal => _Step.body,
    _Step.body => _Step.activity,
    _Step.activity => _hasRate ? _Step.rate : _Step.targets,
    _Step.rate || _Step.targets => _Step.targets,
  });

  void _back() => _go(switch (_step) {
    _Step.targets => _hasRate ? _Step.rate : _Step.activity,
    _Step.rate => _Step.activity,
    _Step.activity => _Step.body,
    _Step.body => _Step.goal,
    _Step.goal || _Step.welcome => _Step.welcome,
  });

  Future<void> _finish() async {
    final l = AppLocalizations.of(context);
    final tg = _targets();
    final now = ref.read(clockProvider)();
    final p = ref.read(profileProvider);
    await ref.read(settingsProvider.notifier).setNoNumbers(_noNumbers);
    await recordConsent(ref.read(prefsProvider), now);
    await ref
        .read(profileProvider.notifier)
        .save(
          Profile(
            goal: _goal,
            sex: _sex,
            ageYears: _ageV!,
            heightCm: _num(_height)!,
            weightKg: _num(_weight)!,
            activity: _activity,
            ratePctPerWeek: _signedRate,
            targetKcal: tg.kcal,
            targets: tg.macros,
            startedOn: p?.startedOn ?? now,
          ),
        );
    if (!mounted) return;
    showVToast(context, l.targetsSaved);
    // Opened again from Me: go back there. First run: on to Today.
    context.canPop() ? context.pop() : context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.welcome) return _Welcome(onStart: _next);
    final l = AppLocalizations.of(context);
    final steps = _hasRate ? 5 : 4;
    final at = switch (_step) {
      _Step.goal => 1,
      _Step.body => 2,
      _Step.activity => 3,
      _Step.rate => 4,
      _ => steps,
    };
    final (content, cta, onCta) = switch (_step) {
      _Step.goal => (_goalStep(l), l.continueBtn, _next),
      _Step.body => (_bodyStep(l), l.continueBtn, _bodyValid ? _next : null),
      _Step.activity => (_activityStep(l), l.continueBtn, _next),
      _Step.rate => (_rateStep(l), l.continueBtn, _next),
      _ => (_targetsStep(l), _consent ? l.startLogging : l.agreeToContinue, _consent ? _finish : null),
    };
    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                children: [
                  IconBtn(
                    'back',
                    small: true,
                    iconSize: 18,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    onTap: _step == _Step.goal && ref.read(profileProvider) != null ? () => context.pop() : _back,
                  ),
                  Expanded(
                    child: _Dots(step: at, of: steps),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: const Cubic(0.32, 0.72, 0, 1),
                child: KeyedSubtree(key: ValueKey(_step), child: content),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: GapCol(
                gap: 10,
                cross: CrossAxisAlignment.stretch,
                children: [
                  VBtn(label: cta, expand: true, trailingIcon: _step == _Step.targets ? null : 'fwd', onTap: onCta),
                  if (_step == _Step.targets)
                    VBtn(label: l.setMacrosManually, kind: BtnKind.ghost, expand: true, onTap: _editMacros),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title, String body) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
    child: GapCol(
      gap: 8,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w600, color: Volt.t1),
        ),
        Muted(body, size: 14),
      ],
    ),
  );

  Widget _goalStep(AppLocalizations l) {
    final goals = [
      (Goal.cut, l.goalCut, l.goalCutSub),
      (Goal.bulk, l.goalBulk, l.goalBulkSub),
      (Goal.recomp, l.goalRecomp, l.goalRecompSub),
      (Goal.maintain, l.goalMaintain, l.goalMaintainSub),
      (Goal.prep, l.goalPrep, l.goalPrepSub),
    ];
    return Pad(
      bottom: 20,
      children: [
        _heading(l.obGoalTitle, l.obGoalBody),
        for (final (g, title, sub) in goals)
          Pressable(
            onTap: () => setState(() {
              _goal = g;
              _rate = g == Goal.bulk ? 0.25 : 0.5;
            }),
            scale: 0.99,
            label: title,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _goal == g ? Volt.brandWash : Volt.card,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: _goal == g ? Volt.brand : Volt.line, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GapCol(
                      gap: 3,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                        ),
                        Muted(sub),
                      ],
                    ),
                  ),
                  if (_goal == g) const Pick(on: true),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _bodyStep(AppLocalizations l) => Pad(
    top: 16,
    bottom: 20,
    children: [
      EmTitle(l.obBodyTitleEm, size: 30, letterSpacing: -0.03, emScale: 1.12),
      Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Text(l.obBodyBody, style: const TextStyle(fontSize: 14, height: 1.5, color: Volt.t2)),
      ),
      _Field(
        label: l.sexForEquation,
        child: _Seg(
          options: [l.sexMale, l.sexFemale],
          selected: _sex.index,
          onPick: (i) => setState(() => _sex = Sex.values[i]),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: _Field(
              label: l.age,
              child: _Input(controller: _age, unit: l.yrs, onChanged: () => setState(() {})),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Field(
              label: l.heightLbl,
              child: _Input(controller: _height, unit: l.cm, onChanged: () => setState(() {})),
            ),
          ),
        ],
      ),
      _Field(
        label: l.weightToday,
        child: _Input(controller: _weight, unit: l.kgLbl, decimal: true, onChanged: () => setState(() {})),
      ),
    ],
  );

  Widget _activityStep(AppLocalizations l) {
    final options = [
      (ActivityLevel.sedentary, 'user', l.actSitting, l.actSittingSub),
      (ActivityLevel.moderate, 'bolt', l.actFeet, l.actFeetSub),
      (ActivityLevel.high, 'dumb', l.actPhysical, l.actPhysicalSub),
      (ActivityLevel.athlete, 'star', l.actVery, l.actVerySub),
    ];
    return Pad(
      top: 16,
      bottom: 20,
      children: [
        EmTitle(l.obActivityTitleEm, size: 30, letterSpacing: -0.03, emScale: 1.12),
        for (final (a, icon, title, sub) in options)
          Pressable(
            onTap: () => setState(() => _activity = a),
            scale: 0.99,
            label: title,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _activity == a ? Volt.brandWash : Volt.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _activity == a ? Volt.brand : Colors.transparent, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Volt.card2),
                    child: VIcon(icon, size: 20, color: Volt.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GapCol(
                      gap: 2,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Volt.t1),
                        ),
                        Text(sub, style: const TextStyle(fontSize: 12, color: Volt.t3)),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _activity == a ? Volt.brand : Volt.line2,
                        width: _activity == a ? 7 : 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.trainingCountedSeparately)),
      ],
    );
  }

  Widget _rateStep(AppLocalizations l) {
    final losing = _goal.losing;
    final lo = losing ? 0.25 : 0.1, hi = losing ? maxRatePctPerWeek : maxRatePctPerWeek / 2;
    final w = _num(_weight) ?? 0;
    final kg = w * _rate / 100;
    final hot = rateNeedsWarning(_signedRate);
    return Pad(
      top: 16,
      bottom: 20,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: GapCol(
            gap: 8,
            children: [
              Text(
                losing ? l.obRateTitleLose : l.obRateTitleGain,
                style: const TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w600, color: Volt.t1),
              ),
              Muted(losing ? l.obRateBodyLose : l.obRateBodyGain, size: 14),
            ],
          ),
        ),
        VCard(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: GapCol(
            gap: 18,
            cross: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(fmtDec(context, _rate, digits: 2), style: numStyle(40, height: 1.1)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l.pctPerWeek,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Volt.t2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Muted(l.about),
                      Text('${losing ? '−' : '+'}${fmtDec(context, kg, digits: 2)} ${l.kgLbl}', style: numStyle(16)),
                    ],
                  ),
                ],
              ),
              GapCol(
                gap: 10,
                cross: CrossAxisAlignment.stretch,
                children: [
                  _RateSlider(
                    value: _rate,
                    min: lo,
                    max: hi,
                    zone: losing ? (0.5, 0.75) : (0.2, 0.35),
                    hotFrom: losing ? 0.85 : null,
                    onChanged: (v) => setState(() => _rate = (v * 20).round() / 20),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final t
                          in losing
                              ? ['0.25%', '0.5%', '0.75%', l.maxPct('1.0%')]
                              : ['0.1%', '0.25%', l.maxPct('0.5%')])
                        Text(t, style: const TextStyle(fontSize: 11, color: Volt.t3)),
                    ],
                  ),
                ],
              ),
              _Banner(warn: hot, text: hot ? l.rateHot : (losing ? l.rateOkLose : l.rateOkGain)),
            ],
          ),
        ),
        _Projection(weightKg: _num(_weight)!, ratePct: _signedRate, from: ref.read(clockProvider)()),
        VCard(
          tight: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: VIcon('info', size: 18, color: Volt.t3),
              ),
              const SizedBox(width: 10),
              Expanded(child: Muted(l.floorNote(fmtInt(context, defaultKcalFloor)), color: Volt.t2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _targetsStep(AppLocalizations l) {
    final tg = _targets();
    final w = _num(_weight)!;
    Widget tile(String label, String value, String sub, Color c) => Expanded(
      child: MacroTile(label: label, value: value, sub: sub, color: c, compact: true),
    );
    return Pad(
      top: 16,
      bottom: 20,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: GapCol(
            gap: 8,
            children: [
              Text(
                l.obTargetsTitle,
                style: const TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w600, color: Volt.t1),
              ),
              Muted(l.obTargetsBody, size: 14),
            ],
          ),
        ),
        VCard(
          child: GapCol(
            gap: 16,
            cross: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(fmtInt(context, tg.kcal), style: numStyle(40, height: 1.1)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l.kcalADay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Volt.t2),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  tile(
                    l.protein,
                    '${fmtInt(context, tg.macros.protein)} ${l.grams}',
                    l.gPerKg(fmtDec(context, tg.macros.protein / w)),
                    Volt.protein,
                  ),
                  const SizedBox(width: 8),
                  tile(l.carbs, '${fmtInt(context, tg.macros.carbs)} ${l.grams}', l.theRemainder, Volt.carbs),
                  const SizedBox(width: 8),
                  tile(
                    l.fat,
                    '${fmtInt(context, tg.macros.fat)} ${l.grams}',
                    l.gPerKg(fmtDec(context, tg.macros.fat / w)),
                    Volt.fat,
                  ),
                ],
              ),
              Muted(
                _hasRate
                    ? l.targetsHow(fmtDec(context, _activity.multiplier, digits: 2), fmtDec(context, _rate, digits: 2))
                    : l.targetsHowMaintain(fmtDec(context, _activity.multiplier, digits: 2)),
              ),
            ],
          ),
        ),
        _Check(on: _consent, onTap: () => setState(() => _consent = !_consent), text: l.consentHealth),
        _Check(on: _noNumbers, onTap: () => setState(() => _noNumbers = !_noNumbers), text: l.noNumbersOfferLine),
      ],
    );
  }
}

/// Where twelve weeks at this rate lands, so the number means something.
class _Projection extends StatelessWidget {
  const _Projection({required this.weightKg, required this.ratePct, required this.from});
  final double weightKg;
  final double ratePct;
  final DateTime from;

  static const weeks = 12;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    var w = weightKg;
    for (var i = 0; i < weeks; i++) {
      w *= 1 + ratePct / 100;
    }
    final at = from.add(const Duration(days: weeks * 7));
    final date = DateFormat('d MMMM', Localizations.localeOf(context).toString()).format(at);
    return VCard(
      tight: true,
      child: Row(
        children: [
          Expanded(
            child: GapCol(
              gap: 3,
              children: [
                Muted(l.projectedKg(fmtDec(context, w, digits: w < 100 ? 1 : 0))),
                Text(
                  l.aroundDate(date),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
              ],
            ),
          ),
          Muted(l.inWeeks(weeks), align: TextAlign.end),
        ],
      ),
    );
  }
}

/// The five onboarding dots: 26 × 4, lime on the current step.
class _Dots extends StatelessWidget {
  const _Dots({required this.step, required this.of});
  final int step;
  final int of;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= of; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 26,
            height: 4,
            decoration: BoxDecoration(
              color: i == step ? Volt.brand : (i < step ? Volt.line2 : Volt.line),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ],
    ),
  );
}

/// `.fld`: label over field.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => GapCol(
    gap: 6,
    cross: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: Volt.t2),
      ),
      child,
    ],
  );
}

/// `.inp`: 44 high, radius 16, line-2 border; lime ring on focus.
class _Input extends StatefulWidget {
  const _Input({required this.controller, required this.unit, required this.onChanged, this.decimal = false});
  final TextEditingController controller;
  final String unit;
  final VoidCallback onChanged;
  final bool decimal;

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final on = _focus.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Volt.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on ? Volt.brand : Volt.line2),
        boxShadow: on
            ? const [BoxShadow(color: Color(0x2EC6F432), spreadRadius: 4)]
            : const [BoxShadow(color: Color(0x0D0A0D12), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: (_) => widget.onChanged(),
              keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]'))],
              cursorColor: Volt.brand,
              style: const TextStyle(fontSize: 16, height: 1.5, color: Volt.t1),
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(widget.unit, style: const TextStyle(fontSize: 16, color: Volt.t3)),
        ],
      ),
    );
  }
}

/// `.vseg`: a pill segmented control, lime when picked.
class _Seg extends StatelessWidget {
  const _Seg({required this.options, required this.selected, required this.onPick});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(999)),
    child: Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              selected: i == selected,
              child: Pressable(
                onTap: () => onPick(i),
                label: options[i],
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected ? Volt.brand : null,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    options[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == selected ? Volt.ink : Volt.t3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// The prototype's rate slider: a track, a green zone where muscle holds,
/// an amber zone where it costs, a lime fill and a ringed knob.
class _RateSlider extends StatelessWidget {
  const _RateSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.zone,
    required this.onChanged,
    this.hotFrom,
  });
  final double value;
  final double min;
  final double max;
  final (double, double) zone;
  final double? hotFrom;
  final ValueChanged<double> onChanged;

  double _f(double v) => ((v - min) / (max - min)).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) {
      final w = c.maxWidth;
      void set(Offset p) => onChanged(min + (p.dx / w).clamp(0, 1) * (max - min));
      return Semantics(
        slider: true,
        value: '${value.toStringAsFixed(2)}%',
        increasedValue: '${(value + 0.05).clamp(min, max).toStringAsFixed(2)}%',
        decreasedValue: '${(value - 0.05).clamp(min, max).toStringAsFixed(2)}%',
        onIncrease: () => onChanged((value + 0.05).clamp(min, max)),
        onDecrease: () => onChanged((value - 0.05).clamp(min, max)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => set(d.localPosition),
          onHorizontalDragUpdate: (d) => set(d.localPosition),
          child: SizedBox(
            height: 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 10,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Volt.line, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Positioned(
                  left: w * _f(zone.$1),
                  width: w * (_f(zone.$2) - _f(zone.$1)),
                  top: 10,
                  height: 6,
                  child: const ColoredBox(color: Volt.okWash),
                ),
                if (hotFrom != null)
                  Positioned(
                    left: w * _f(hotFrom!),
                    right: 0,
                    top: 10,
                    height: 6,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Volt.warnWash,
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(999)),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  width: w * _f(value),
                  top: 10,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Volt.brand, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Positioned(
                  left: w * _f(value) - 13,
                  top: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Volt.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: Volt.brand, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.warn, required this.text});
  final bool warn;
  final String text;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: warn ? Volt.warnWash : Volt.okWash,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: warn ? Volt.warnEdge : Colors.transparent),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: VIcon(warn ? 'warn' : 'check', size: 18, color: warn ? Volt.warn : Volt.ok),
        ),
        const SizedBox(width: 10),
        Expanded(child: Muted(text, color: Volt.t2)),
      ],
    ),
  );
}

/// The consent rows: a lime checkbox and wrapped text in a tight card.
class _Check extends StatelessWidget {
  const _Check({required this.on, required this.onTap, required this.text});
  final bool on;
  final VoidCallback onTap;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: on,
    child: VCard(
      tight: true,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: on ? Volt.brand : Volt.t1, borderRadius: BorderRadius.circular(5)),
            child: on ? const Center(child: VIcon('check', size: 14, color: Volt.ink, strokeWidth: 2.4)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.45, color: Volt.t2)),
          ),
        ],
      ),
    ),
  );
}

/// Welcome: the kettlebell swing, the promise, and the swipe to start.
class _Welcome extends StatefulWidget {
  const _Welcome({required this.onStart});
  final VoidCallback onStart;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  double _drag = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final safe = MediaQuery.paddingOf(context);
    return Scaffold(
      backgroundColor: Volt.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.4, -0.64),
                  radius: 0.9,
                  colors: [Volt.brand.withValues(alpha: 0.30), Volt.brand.withValues(alpha: 0)],
                  stops: const [0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: safe.top,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.black, Colors.transparent],
                stops: [0, 0.8, 1],
              ).createShader(r),
              child: Image.asset(
                'assets/brand/welcome.webp',
                height: MediaQuery.sizeOf(context).height * 0.61,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                semanticLabel: l.welcomeArtAlt,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 30 + safe.bottom),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VLogo(size: 44),
                  const SizedBox(height: 16),
                  EmTitle(l.welcomeTitleEm, size: 40, letterSpacing: -0.03, emScale: 1.12),
                  const SizedBox(height: 16),
                  Text(l.welcomeBody, style: const TextStyle(fontSize: 14, height: 1.5, color: Volt.t2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(color: Volt.brand, borderRadius: BorderRadius.circular(999)),
                      ),
                      const SizedBox(width: 6),
                      for (var i = 0; i < 2; i++) ...[
                        Container(
                          width: 22,
                          height: 4,
                          decoration: BoxDecoration(color: Volt.line2, borderRadius: BorderRadius.circular(999)),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (_, c) => Semantics(
                      button: true,
                      label: l.swipeToStart,
                      onTap: widget.onStart,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: widget.onStart,
                        onHorizontalDragUpdate: (d) =>
                            setState(() => _drag = (_drag + d.delta.dx).clamp(0, c.maxWidth - 64)),
                        onHorizontalDragEnd: (_) {
                          if (_drag > c.maxWidth * 0.45) widget.onStart();
                          setState(() => _drag = 0);
                        },
                        child: Container(
                          height: 64,
                          padding: const EdgeInsetsDirectional.fromSTEB(22, 0, 8, 0),
                          decoration: BoxDecoration(
                            gradient: Volt.glow,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0xD9B6F02A),
                                blurRadius: 34,
                                offset: Offset(0, 18),
                                spreadRadius: -16,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Opacity(
                                opacity: 0.55,
                                child: Text(
                                  '›››',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -2,
                                    color: Volt.ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l.swipeToStart,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Volt.ink),
                                ),
                              ),
                              Container(
                                width: 46,
                                height: 46,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Volt.ink),
                                child: const VIcon('fwd', size: 20, color: Volt.brand),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
