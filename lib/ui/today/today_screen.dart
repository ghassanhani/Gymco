import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final day = ref.watch(todayKeyProvider);
    final now = ref.watch(clockProvider)();
    final profile = ref.watch(profileProvider);
    final noNumbers = ref.watch(settingsProvider.select((s) => s.noNumbers));
    final entries = ref.watch(dayEntriesProvider(day));

    return VoltBackground(
      child: SafeArea(
        bottom: false,
        child: entries.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            final totals = DayTotals(list);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 140),
              children: [
                Row(
                  children: [
                    const GymcoLogo(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccentTitle(template: l.todayTitle('{accent}'), accent: l.todayAccent),
                          const SizedBox(height: 3),
                          Text(fmtDay(context, now), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (list.isEmpty) _EmptyDay(onAdd: () => context.push('/add/${Meal.breakfast.name}')),
                if (profile != null && list.isNotEmpty)
                  noNumbers
                      ? _HabitsCard(totals: totals)
                      : _BudgetCard(totals: totals, target: profile.targetKcal, profile: profile),
                SectionHeader(l.meals),
                for (final m in Meal.values) ...[
                  _MealRow(meal: m, entries: totals.inMeal(m), noNumbers: noNumbers),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return VoltCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.emptyDayTitle, style: t.titleLarge),
          const SizedBox(height: 6),
          Text(l.emptyDayBody, style: t.bodyMedium),
          const SizedBox(height: 16),
          GlowButton(label: l.addFood, icon: Icons.add_rounded, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.totals, required this.target, required this.profile});
  final DayTotals totals;
  final double target;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final left = target - totals.kcal;
    final m = totals.macros;
    final g = profile.targets;
    String grams(double a, double b) => l.ofGrams(fmtInt(context, a), fmtInt(context, b));

    return VoltCard(
      child: Column(
        children: [
          KcalRing(
            fraction: totals.kcal / target,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(fmtInt(context, totals.kcal), style: t.headlineMedium?.copyWith(fontSize: 34)),
                Text('/ ${fmtInt(context, target)} ${l.kcal}', style: t.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            left >= 0 ? l.kcalLeft(fmtInt(context, left)) : l.kcalOver(fmtInt(context, -left)),
            style: t.titleMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: MacroBar(
                  label: l.protein,
                  value: grams(m.protein, g.protein),
                  color: Volt.protein,
                  fraction: m.protein / g.protein,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MacroBar(
                  label: l.carbs,
                  value: grams(m.carbs, g.carbs),
                  color: Volt.carbs,
                  fraction: g.carbs == 0 ? 0 : m.carbs / g.carbs,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: MacroBar(label: l.fat, value: grams(m.fat, g.fat), color: Volt.fat, fraction: m.fat / g.fat),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HabitsCard extends StatelessWidget {
  const _HabitsCard({required this.totals});
  final DayTotals totals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final proteinEveryMeal = Meal.values
        .map(totals.inMeal)
        .where((e) => e.isNotEmpty)
        .every((e) => e.fold<double>(0, (s, x) => s + x.protein) >= 20);
    Widget row(bool on, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: on ? Volt.brand : Volt.t4,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: t.bodyMedium?.copyWith(color: Volt.t1)),
          ),
        ],
      ),
    );
    return VoltCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.habitsTitle, style: t.titleMedium),
          const SizedBox(height: 8),
          row(totals.mealsLogged > 0, l.habitMealsLogged(totals.mealsLogged)),
          row(proteinEveryMeal && totals.mealsLogged > 0, l.habitProtein),
        ],
      ),
    );
  }
}

class _MealRow extends ConsumerWidget {
  const _MealRow({required this.meal, required this.entries, required this.noNumbers});
  final Meal meal;
  final List<LogEntry> entries;
  final bool noNumbers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final kcal = entries.fold<double>(0, (s, e) => s + e.kcal);
    final sub = entries.isEmpty
        ? l.nothingLogged
        : '${entries.take(3).map((e) => e.foodName).join(', ')} · ${l.itemsCount(entries.length)}';

    return VoltCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      onTap: () => context.push('/meal/${meal.name}'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Volt.card2, shape: BoxShape.circle),
            child: Icon(_icon(meal), size: 20, color: Volt.t2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mealName(l, meal), style: t.titleMedium),
                const SizedBox(height: 2),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall),
              ],
            ),
          ),
          if (entries.isNotEmpty && !noNumbers) Text(fmtInt(context, kcal), style: t.titleMedium),
          IconButton(
            tooltip: l.addTo(mealName(l, meal)),
            onPressed: () => context.push('/add/${meal.name}'),
            icon: const Icon(Icons.add_circle_rounded, color: Volt.brand),
          ),
        ],
      ),
    );
  }

  static IconData _icon(Meal m) => switch (m) {
    Meal.breakfast => Icons.free_breakfast_outlined,
    Meal.lunch => Icons.lunch_dining_outlined,
    Meal.dinner => Icons.dinner_dining_outlined,
    Meal.snack => Icons.apple_outlined,
  };
}
