import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

class MealScreen extends ConsumerWidget {
  const MealScreen({super.key, required this.meal});
  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final day = ref.watch(todayKeyProvider);
    final noNumbers = ref.watch(settingsProvider.select((s) => s.noNumbers));
    final entries = ref.watch(dayEntriesProvider(day)).value?.where((e) => e.meal == meal).toList() ?? const [];
    final kcal = entries.fold<double>(0, (s, e) => s + e.kcal);

    return Scaffold(
      body: VoltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              Row(
                children: [
                  const BackButton(),
                  Expanded(child: Text(mealName(l, meal), style: t.titleLarge)),
                  if (!noNumbers && entries.isNotEmpty)
                    Text('${fmtInt(context, kcal)} ${l.kcal}', style: t.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              if (entries.isEmpty) ...[
                VoltCard(child: Text(l.nothingLogged, style: t.bodyMedium)),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GhostButton(
                    label: l.repeatYesterday,
                    icon: Icons.replay_rounded,
                    onPressed: () async {
                      final n = await ref.read(logActionsProvider).repeatYesterday(meal);
                      if (n == 0 && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.nothingYesterday)));
                      }
                    },
                  ),
                ),
              ],
              for (final e in entries) ...[
                Dismissible(
                  key: ValueKey(e.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsetsDirectional.only(end: 24),
                    decoration: BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(Volt.rCard)),
                    child: Text(l.delete, style: t.titleMedium),
                  ),
                  onDismissed: (_) => ref.read(logActionsProvider).remove(e),
                  child: VoltCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.foodName, style: t.titleMedium?.copyWith(fontSize: 15)),
                              Text('${fmtInt(context, e.grams)} ${l.grams}', style: t.bodySmall),
                            ],
                          ),
                        ),
                        if (!noNumbers) Text(fmtInt(context, e.kcal), style: t.titleMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              GlowButton(
                label: l.addTo(mealName(l, meal)),
                icon: Icons.add_rounded,
                onPressed: () => context.push('/add/${meal.name}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
