import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/cheat_meal.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  static const languages = {'en': 'English', 'ar': 'العربية', 'es': 'Español'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final profile = ref.watch(profileProvider);

    Future<void> toggleNoNumbers(bool on) async {
      if (on) return notifier.setNoNumbers(true);
      // Leaving needs a deliberate step, not a tap.
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Volt.card,
          title: Text(l.leaveNoNumbersTitle),
          content: Text(l.leaveNoNumbersBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.leaveNoNumbersConfirm)),
          ],
        ),
      );
      if (ok ?? false) await notifier.setNoNumbers(false);
    }

    return VoltBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 140),
          children: [
            Text(l.meTitle, style: t.headlineMedium),
            if (profile != null && !s.noNumbers) ...[
              SectionHeader(l.targets),
              VoltCard(
                onTap: () => context.push('/onboarding'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${fmtInt(context, profile.targetKcal)} ${l.kcal}', style: t.titleLarge),
                          Text(
                            '${l.protein} ${fmtInt(context, profile.targets.protein)} · '
                            '${l.carbs} ${fmtInt(context, profile.targets.carbs)} · '
                            '${l.fat} ${fmtInt(context, profile.targets.fat)} ${l.grams}',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Volt.t3),
                  ],
                ),
              ),
            ],
            if (profile != null && s.noNumbers) ...[
              const SizedBox(height: 16),
              VoltCard(
                onTap: () => context.push('/onboarding'),
                child: Text(l.redoOnboarding, style: t.titleMedium),
              ),
            ],
            SectionHeader(l.language),
            VoltCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: RadioGroup<String?>(
                groupValue: s.languageCode,
                onChanged: notifier.setLanguage,
                child: Column(
                  children: [
                    RadioListTile<String?>(value: null, title: Text(l.systemLanguage)),
                    for (final e in languages.entries) RadioListTile<String?>(value: e.key, title: Text(e.value)),
                  ],
                ),
              ),
            ),
            SectionHeader(l.noNumbersMode),
            VoltCard(
              padding: const EdgeInsets.fromLTRB(18, 4, 8, 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: s.noNumbers,
                onChanged: toggleNoNumbers,
                title: Text(l.noNumbersMode, style: t.titleMedium),
                subtitle: Text(l.noNumbersModeSub, style: t.bodySmall),
              ),
            ),
            SectionHeader(l.cheatAllowance),
            SegmentedButton<CheatAllowance>(
              segments: [
                ButtonSegment(value: CheatAllowance.off, label: Text(l.cheatOff)),
                ButtonSegment(value: CheatAllowance.oncePerWeek, label: Text(l.cheatOnce)),
                ButtonSegment(value: CheatAllowance.twicePerWeek, label: Text(l.cheatTwice)),
              ],
              selected: {s.cheatAllowance},
              showSelectedIcon: false,
              onSelectionChanged: (v) => notifier.setCheatAllowance(v.first),
            ),
          ],
        ),
      ),
    );
  }
}
