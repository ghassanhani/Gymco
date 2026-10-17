import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../domain/energy.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Step { welcome, goal, body, activity, rate, targets }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  Goal _goal = Goal.cut;
  Sex _sex = Sex.male;
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  ActivityLevel _activity = ActivityLevel.light;
  double _rate = 0.5;
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

  double get _signedRate => clampRate(_goal, _rate);

  ({double kcal, Macros macros}) _targets() {
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

  void _next() {
    setState(() {
      _step = switch (_step) {
        _Step.welcome => _Step.goal,
        _Step.goal => _Step.body,
        _Step.body => _Step.activity,
        _Step.activity => _goal == Goal.maintain ? _Step.targets : _Step.rate,
        _Step.rate => _Step.targets,
        _Step.targets => _Step.targets,
      };
    });
  }

  void _back() {
    setState(() {
      _step = switch (_step) {
        _Step.targets => _goal == Goal.maintain ? _Step.activity : _Step.rate,
        _Step.rate => _Step.activity,
        _Step.activity => _Step.body,
        _Step.body => _Step.goal,
        _Step.goal || _Step.welcome => _Step.welcome,
      };
    });
  }

  Future<void> _finish() async {
    final tg = _targets();
    final now = ref.read(clockProvider)();
    final p = ref.read(profileProvider);
    await ref.read(settingsProvider.notifier).setNoNumbers(_noNumbers);
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
    // Opened again from Me: go back there. First run: on to Today.
    context.canPop() ? context.pop() : context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (Widget content, String cta, VoidCallback? onCta) = switch (_step) {
      _Step.welcome => (_welcome(l), l.getStarted, _next),
      _Step.goal => (_goalStep(l), l.continueBtn, _next),
      _Step.body => (_bodyStep(l), l.continueBtn, _bodyValid ? _next : null),
      _Step.activity => (_activityStep(l), l.continueBtn, _next),
      _Step.rate => (_rateStep(l), l.continueBtn, _next),
      _Step.targets => (_targetsStep(l), l.startBtn, _finish),
    };

    return Scaffold(
      body: VoltBackground(
        child: SafeArea(
          child: Column(
            children: [
              if (_step != _Step.welcome)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: BackButton(onPressed: _back),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: content,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: GlowButton(label: cta, onPressed: onCta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? get _h => Theme.of(context).textTheme.headlineMedium;
  TextStyle? get _body => Theme.of(context).textTheme.bodyMedium;

  Widget _welcome(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 60),
      const GymcoLogo(size: 64),
      const SizedBox(height: 28),
      AccentTitle(template: l.obWelcomeTitle('{accent}'), accent: l.obWelcomeAccent, size: 36),
      const SizedBox(height: 14),
      Text(l.obWelcomeBody, style: _body?.copyWith(fontSize: 16)),
    ],
  );

  Widget _option({required bool on, required String title, String? sub, required VoidCallback onTap}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: on ? Volt.brandWash : Volt.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Volt.rRow),
          side: BorderSide(color: on ? Volt.brand : Colors.transparent, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Volt.rRow),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.titleMedium),
                      if (sub != null) ...[const SizedBox(height: 2), Text(sub, style: t.bodySmall)],
                    ],
                  ),
                ),
                Icon(
                  on ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: on ? Volt.brand : Volt.t4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalStep(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l.obGoalTitle, style: _h),
      const SizedBox(height: 20),
      for (final (g, title, sub) in [
        (Goal.cut, l.goalCut, l.goalCutSub),
        (Goal.maintain, l.goalMaintain, l.goalMaintainSub),
        (Goal.bulk, l.goalBulk, l.goalBulkSub),
      ])
        _option(
          on: _goal == g,
          title: title,
          sub: sub,
          onTap: () => setState(() {
            _goal = g;
            _rate = g == Goal.bulk ? 0.25 : 0.5;
          }),
        ),
    ],
  );

  Widget _field(TextEditingController c, String label, {bool decimal = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))],
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _bodyStep(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l.obBodyTitle, style: _h),
      const SizedBox(height: 8),
      Text(l.obBodyBody, style: _body),
      const SizedBox(height: 20),
      SegmentedButton<Sex>(
        segments: [
          ButtonSegment(value: Sex.male, label: Text(l.sexMale)),
          ButtonSegment(value: Sex.female, label: Text(l.sexFemale)),
        ],
        selected: {_sex},
        onSelectionChanged: (s) => setState(() => _sex = s.first),
        showSelectedIcon: false,
      ),
      const SizedBox(height: 16),
      _field(_age, l.age),
      _field(_height, l.heightCm),
      _field(_weight, l.weightKg, decimal: true),
    ],
  );

  Widget _activityStep(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l.obActivityTitle, style: _h),
      const SizedBox(height: 20),
      for (final (a, title) in [
        (ActivityLevel.sedentary, l.actSedentary),
        (ActivityLevel.light, l.actLight),
        (ActivityLevel.moderate, l.actModerate),
        (ActivityLevel.high, l.actHigh),
        (ActivityLevel.athlete, l.actAthlete),
      ])
        _option(on: _activity == a, title: title, onTap: () => setState(() => _activity = a)),
    ],
  );

  Widget _rateStep(AppLocalizations l) {
    final t = Theme.of(context).textTheme;
    final w = _num(_weight) ?? 0;
    final max = _goal == Goal.bulk ? maxRatePctPerWeek / 2 : maxRatePctPerWeek;
    final warn = rateNeedsWarning(_signedRate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.obRateTitle, style: _h),
        const SizedBox(height: 24),
        Text(l.ratePerWeek(fmtDec(context, _rate, digits: 2)), style: t.titleLarge),
        const SizedBox(height: 4),
        Text(l.rateKgPerWeek(fmtDec(context, w * _rate / 100, digits: 2)), style: t.bodyMedium),
        Slider(
          value: _rate.clamp(0.1, max),
          min: 0.1,
          max: max,
          divisions: ((max - 0.1) / 0.05).round(),
          onChanged: (v) => setState(() => _rate = (v * 20).round() / 20),
        ),
        Text(l.rateCapNote, style: t.bodySmall),
        if (warn) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Volt.warnWash,
              borderRadius: BorderRadius.circular(Volt.rRow),
              border: Border.all(color: Volt.warnEdge),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Volt.warn),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.rateWarning, style: t.bodyMedium?.copyWith(color: Volt.t1)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _targetsStep(AppLocalizations l) {
    final t = Theme.of(context).textTheme;
    final tg = _targets();
    Widget macro(String label, double g, Color c) => Expanded(
      child: Column(
        children: [
          Text('${fmtInt(context, g)} ${l.grams}', style: t.titleLarge?.copyWith(color: c)),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.obTargetsTitle, style: _h),
        const SizedBox(height: 8),
        Text(l.obTargetsBody, style: _body),
        const SizedBox(height: 20),
        VoltCard(
          child: Column(
            children: [
              Text(l.dailyTarget, style: t.bodySmall),
              const SizedBox(height: 4),
              Text('${fmtInt(context, tg.kcal)} ${l.kcal}', style: t.headlineMedium?.copyWith(fontSize: 36)),
              const SizedBox(height: 16),
              Row(
                children: [
                  macro(l.protein, tg.macros.protein, Volt.protein),
                  macro(l.carbs, tg.macros.carbs, Volt.carbs),
                  macro(l.fat, tg.macros.fat, Volt.fat),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        VoltCard(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _noNumbers,
            onChanged: (v) => setState(() => _noNumbers = v),
            title: Text(l.noNumbersOffer, style: t.titleMedium),
            subtitle: Text(l.noNumbersOfferBody, style: t.bodySmall),
          ),
        ),
      ],
    );
  }
}
