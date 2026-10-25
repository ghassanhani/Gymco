import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/cloud.dart';
import '../../domain/session.dart' show PainArea;
import '../../domain/energy.dart';
import '../../domain/iron_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../state/coach_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/iron_avatar.dart';
import '../kit/kit.dart';
import '../me/account_screen.dart' show cloudMessage;
import 'swap_pain.dart' show painAreaName;

/// "Iron reads: your numbers, food details, health profile", from the
/// user's choices, so every privacy line says the same true thing.
String ironReadsLine(AppLocalizations l, WidgetRef ref) => l.ironReadsLine(
  [
    l.ironReadsNumbers,
    if (ref.watch(ironShareFoodProvider)) l.ironReadsFood,
    if (ref.watch(ironShareHealthProvider)) l.ironReadsHealth,
  ].map((s) => s.toLowerCase()).join(', '),
);

/// What Iron may read, the health profile, the weekly review, and the way
/// to turn Iron off.
class IronSettingsScreen extends ConsumerWidget {
  const IronSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final food = ref.watch(ironShareFoodProvider);
    final health = ref.watch(ironShareHealthProvider);
    final profile = ref.watch(healthProfileProvider);

    Widget toggle(String icon, String name, String sub, bool on, VoidCallback? onTap) => VItem(
      onTap: onTap,
      semantics: name,
      children: [
        VIcon(icon, size: 19, color: Volt.t3),
        ItemText(name, sub: sub),
        if (onTap == null) VIcon('check', size: 16, color: Volt.ok) else VToggle(on: on),
      ],
    );

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.ironSettings, onBack: () => context.canPop() ? context.pop() : context.go('/today')),
            Expanded(
              child: Pad(
                children: [
                  Eyebrow(l.ironReads, padding: const EdgeInsetsDirectional.only(start: 4)),
                  VList(
                    children: [
                      toggle('pulse', l.ironReadsNumbers, l.ironReadsNumbersSub, true, null),
                      toggle(
                        'meal',
                        l.ironReadsFood,
                        l.ironReadsFoodSub,
                        food,
                        () => ref.read(ironShareFoodProvider.notifier).set(!food),
                      ),
                      toggle(
                        'shield',
                        l.ironReadsHealth,
                        l.ironReadsHealthSub,
                        health,
                        () => ref.read(ironShareHealthProvider.notifier).set(!health),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Muted('${l.ironPhotosNever} ${l.ironNotDoctor}', size: 12),
                  ),
                  VList(
                    children: [
                      VItem(
                        onTap: () => context.push('/iron/health'),
                        children: [
                          VIcon('shield', size: 19, color: ironGradient[1]),
                          ItemText(profile == null ? l.ironEditHealth : l.healthProfileTitle, sub: l.ironEditHealthSub),
                          VIcon('fwd', size: 14, color: Volt.t4),
                        ],
                      ),
                      VItem(
                        onTap: () => context.push('/iron/review'),
                        children: [
                          VIcon('chart', size: 19, color: ironGradient[1]),
                          ItemText(l.ironWeekReview, sub: l.ironWeekReviewSub),
                          VIcon('fwd', size: 14, color: Volt.t4),
                        ],
                      ),
                    ],
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await ref.read(ironOnProvider.notifier).set(false);
                        if (context.mounted) context.go('/today');
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

const _conditions = ['blood_pressure', 'heart', 'diabetes', 'asthma', 'joints', 'other'];

String _conditionName(AppLocalizations l, String c) => switch (c) {
  'blood_pressure' => l.condBloodPressure,
  'heart' => l.condHeart,
  'diabetes' => l.condDiabetes,
  'asthma' => l.condAsthma,
  'joints' => l.condJoints,
  _ => l.condOther,
};

String _parq(AppLocalizations l, int i) => [l.parq1, l.parq2, l.parq3, l.parq4, l.parq5, l.parq6, l.parq7][i];

/// The health profile: injuries, conditions, medication, pregnancy and the
/// PAR-Q+. Kept on the phone; the warning signs read it without the AI.
class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  ConsumerState<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  late var _h = ref.read(healthProfileProvider) ?? HealthProfile(parq: List.filled(parqQuestions, false));
  late final _note = TextEditingController(text: _h.note);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Set<String> _flip(Set<String> s, String v) => s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final parq = _h.parq.length == parqQuestions ? _h.parq : List.filled(parqQuestions, false);
    await ref
        .read(healthProfileProvider.notifier)
        .save(_h.copyWith(parq: parq, note: _note.text, cleared: parq.any((a) => a) && _h.cleared));
    if (!mounted) return;
    showVToast(context, l.healthSaved);
    context.canPop() ? context.pop() : context.go('/iron/settings');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final female = ref.watch(profileProvider)?.sex == Sex.female;
    final parq = _h.parq.length == parqQuestions ? _h.parq : List.filled(parqQuestions, false);

    Widget check(String label, bool on, VoidCallback onTap) => VItem(
      onTap: onTap,
      semantics: label,
      children: [
        ItemText(label),
        VToggle(on: on),
      ],
    );

    return Scaffold(
      body: VScreen(
        overlays: [
          LogBar(
            aboveTabs: false,
            padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 8),
            children: [
              Expanded(
                child: VBtn(label: l.save, expand: true, onTap: _save),
              ),
            ],
          ),
        ],
        child: Column(
          children: [
            BackBar(
              title: l.healthProfileTitle,
              sub: l.healthProfileSub,
              onBack: () => context.canPop() ? context.pop() : context.go('/iron/settings'),
            ),
            Expanded(
              child: Pad(
                bottom: 130,
                children: [
                  Eyebrow(l.healthInjuries, padding: const EdgeInsetsDirectional.only(start: 4)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in PainArea.values)
                        VChip(
                          label: painAreaName(l, a),
                          on: _h.injuries.contains(a.name),
                          onTap: () => setState(() => _h = _h.copyWith(injuries: _flip(_h.injuries, a.name))),
                        ),
                    ],
                  ),
                  Eyebrow(l.healthConditions, padding: const EdgeInsetsDirectional.only(start: 4)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _conditions)
                        VChip(
                          label: _conditionName(l, c),
                          on: _h.conditions.contains(c),
                          onTap: () => setState(() => _h = _h.copyWith(conditions: _flip(_h.conditions, c))),
                        ),
                    ],
                  ),
                  VList(
                    children: [
                      check(
                        l.healthMeds,
                        _h.medication,
                        () => setState(() => _h = _h.copyWith(medication: !_h.medication)),
                      ),
                      if (female)
                        check(
                          l.healthPregnant,
                          _h.pregnant,
                          () => setState(() => _h = _h.copyWith(pregnant: !_h.pregnant)),
                        ),
                    ],
                  ),
                  Eyebrow(l.healthParqTitle, padding: const EdgeInsetsDirectional.only(start: 4)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Muted(l.healthParqSub, size: 12.5),
                  ),
                  for (var i = 0; i < parqQuestions; i++)
                    VCard(
                      child: GapCol(
                        gap: 10,
                        cross: CrossAxisAlignment.stretch,
                        children: [
                          Text(_parq(l, i), style: TextStyle(fontSize: 14, height: 1.35, color: Volt.t1)),
                          Row(
                            children: [
                              for (final (label, yes) in [(l.noLbl, false), (l.yesLbl, true)]) ...[
                                Expanded(
                                  child: VChip(
                                    label: label,
                                    on: parq[i] == yes,
                                    color: yes && parq[i] ? ironGradient[1] : null,
                                    textColor: yes && parq[i] ? Colors.white : null,
                                    onTap: () => setState(() => _h = _h.copyWith(parq: [...parq]..[i] = yes)),
                                  ),
                                ),
                                if (!yes) const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (parq.any((a) => a))
                    VList(
                      children: [
                        check(
                          l.healthCleared,
                          _h.cleared,
                          () => setState(() => _h = _h.copyWith(cleared: !_h.cleared)),
                        ),
                      ],
                    ),
                  Eyebrow(l.ironHealthNote, padding: const EdgeInsetsDirectional.only(start: 4)),
                  TextField(
                    controller: _note,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 15, height: 1.4, color: Volt.t1),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: l.ironHealthNoteHint,
                      hintStyle: TextStyle(color: Volt.t4),
                      filled: true,
                      fillColor: Volt.field,
                      contentPadding: const EdgeInsets.all(14),
                      border: SmoothInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Muted('${l.ironEditHealthSub} ${l.ironNotDoctor}', size: 12),
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

/// Iron looks back at the week: what went well, what slipped, what changes.
class IronReviewScreen extends ConsumerWidget {
  const IronReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final review = ref.watch(ironReviewProvider);

    Widget section(String head, List<String> items, String icon, Color color) => GapCol(
      gap: 8,
      cross: CrossAxisAlignment.stretch,
      children: [
        Eyebrow(head, color: color, padding: const EdgeInsetsDirectional.only(start: 4)),
        VList(
          children: [
            for (final s in items)
              VItem(
                children: [
                  VIcon(icon, size: 16, color: color),
                  ItemText(s),
                ],
              ),
          ],
        ),
      ],
    );

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(
              title: l.ironWeekReview,
              sub: l.ironWeekReviewSub,
              onBack: () => context.canPop() ? context.pop() : context.go('/today'),
            ),
            Expanded(
              child: Pad(
                children: [
                  Row(
                    children: [
                      IronAvatar(
                        mood: review.isLoading
                            ? IronMood.thinking
                            : review.value == null
                            ? IronMood.idle
                            : IronMood.happy,
                        size: 60,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: switch (review) {
                          AsyncData(value: final r?) => Text(
                            r.headline,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.25, color: Volt.t1),
                          ),
                          AsyncError(:final error) => Muted(
                            error is CloudException ? cloudMessage(l, error.failure) : l.ironNoTip,
                            size: 13,
                          ),
                          AsyncData() => Muted(l.ironNoTip, size: 13),
                          _ => Muted(l.reviewLoading, size: 13),
                        },
                      ),
                    ],
                  ),
                  if (review.value case final r?) ...[
                    if (r.wins.isNotEmpty) section(l.reviewWins, r.wins, 'check', Volt.ok),
                    if (r.slips.isNotEmpty) section(l.reviewSlips, r.slips, 'info', Volt.warn),
                    if (r.next.isNotEmpty) section(l.reviewNext, r.next, 'bolt', ironGradient[1]),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Muted(ironReadsLine(l, ref), size: 11.5, align: TextAlign.center),
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
