import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

class MealScreen extends ConsumerWidget {
  const MealScreen({super.key, required this.meal});
  final Meal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final day = ref.watch(todayKeyProvider);
    final now = ref.watch(clockProvider)();
    final profile = ref.watch(profileProvider);
    final rows = (ref.watch(dayEntriesProvider(day)).value ?? const <LogEntry>[]).where((e) => e.meal == meal).toList();
    final t = DayTotals(rows);
    final share = profile == null ? 0 : (t.kcal / profile.targetKcal * 100).round();
    final date = DateFormat('EEE d MMM', Localizations.localeOf(context).toString()).format(now);

    Widget tile(String label, double v, Color c) => Expanded(
      child: MacroTile(label: label, value: '${fmtInt(context, v)} ${l.grams}', color: c),
    );

    final last = rows
        .map((e) => e.loggedAt)
        .nonNulls
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

    Future<void> saveMeal() async {
      await ref
          .read(logActionsProvider)
          .saveMeal(
            '${mealName(l, meal)} · ${rows.take(2).map((e) => foodName(context, e.foodId, e.foodName).split(',').first).join(', ')}',
            rows,
          );
      if (context.mounted) showVToast(context, l.savedToMyMeals);
    }

    Future<void> copyTomorrow() async {
      await ref.read(logActionsProvider).copyToTomorrow(meal);
      if (context.mounted) showVToast(context, l.copiedToTomorrow);
    }

    void options() => showVSheet<void>(
      context,
      title: l.mealOptions,
      body: (ctx) => [
        SRow(
          label: l.saveAsMeal,
          onTap: rows.isEmpty
              ? null
              : () {
                  Navigator.pop(ctx);
                  saveMeal();
                },
        ),
        SRow(
          label: l.copyToTomorrow,
          onTap: rows.isEmpty
              ? null
              : () {
                  Navigator.pop(ctx);
                  copyTomorrow();
                },
        ),
        SRow(
          label: l.clearMeal,
          tint: Volt.warn,
          onTap: rows.isEmpty
              ? null
              : () async {
                  Navigator.pop(ctx);
                  for (final e in rows) {
                    await ref.read(logActionsProvider).remove(e);
                  }
                },
        ),
      ],
    );

    void back() => context.canPop() ? context.pop() : context.go('/today');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VScreen(
        overlays: [
          LogBar(
            children: [
              Expanded(
                child: Muted(
                  rows.isEmpty
                      ? l.emptyMeal
                      : last == null
                      ? l.itemsCount(rows.length)
                      : l.lastLogged(DateFormat.Hm(Localizations.localeOf(context).toString()).format(last)),
                ),
              ),
              VBtn(label: l.doneBtn, small: true, onTap: back),
            ],
          ),
        ],
        child: Column(
          children: [
            BackBar(
              title: mealName(l, meal),
              sub: '$date · ${l.itemsCount(rows.length)}',
              titleSize: 19,
              onBack: back,
              lead: MealIco(meal: meal.index, on: true, size: 40),
              right: IconBtn('info', label: l.mealOptions, iconSize: 19, onTap: options),
            ),
            Expanded(
              child: Pad(
                bottom: 190,
                children: [
                  VCard(
                    child: GapCol(
                      gap: 14,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              // Big totals shrink to fit rather than spill.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(fmtInt(context, t.kcal), style: numStyle(34, height: 1.1)),
                                    const SizedBox(width: 8),
                                    Text(l.kcal, style: const TextStyle(fontSize: 14, color: Volt.t2)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Muted(l.shareOfToday(share)),
                          ],
                        ),
                        Row(
                          children: [
                            tile(l.protein, t.macros.protein, Volt.protein),
                            const SizedBox(width: 8),
                            tile(l.carbs, t.macros.carbs, Volt.carbs),
                            const SizedBox(width: 8),
                            tile(l.fat, t.macros.fat, Volt.fat),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Eyebrow(l.inThisMeal, padding: const EdgeInsets.fromLTRB(4, 4, 4, 0)),
                  VList(
                    children: [
                      if (rows.isEmpty)
                        Container(
                          constraints: const BoxConstraints(minHeight: 56),
                          alignment: Alignment.center,
                          child: Text(l.nothingInMeal, style: const TextStyle(fontSize: 13, color: Volt.t3)),
                        ),
                      for (final e in rows)
                        VItem(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => context.push(
                                  '/serving/${Uri.encodeComponent(e.foodId)}?entry=${e.id}&meal=${meal.name}',
                                ),
                                child: Row(
                                  children: [
                                    ItemText(
                                      foodName(context, e.foodId, e.foodName),
                                      sub:
                                          '${fmtInt(context, e.kcal)} ${l.kcal} · P ${fmtInt(context, e.protein)} C ${fmtInt(context, e.carbs)} F ${fmtInt(context, e.fat)}',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              '${fmtInt(context, e.grams)} ${l.grams}',
                              style: numStyle(14, weight: FontWeight.w400, color: Volt.t2),
                            ),
                            IconBtn(
                              'close',
                              label: l.removeFood(foodName(context, e.foodId, e.foodName)),
                              size: 32,
                              iconSize: 15,
                              onTap: () {
                                ref.read(logActionsProvider).remove(e);
                                showVToast(
                                  context,
                                  l.foodRemoved(foodName(context, e.foodId, e.foodName).split(',').first),
                                );
                              },
                            ),
                          ],
                        ),
                      VItem(
                        onTap: () => context.push('/add/${meal.name}'),
                        children: [
                          const Pick(color: Volt.brandInk),
                          Expanded(
                            child: Text(
                              l.addFoodToMeal,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.brandInk),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rows.isEmpty
                          ? [
                              VChip(
                                label: l.repeatYesterday,
                                icon: 'repeat',
                                onTap: () async {
                                  final n = await ref.read(logActionsProvider).repeatYesterday(meal);
                                  if (n == 0 && context.mounted) showVToast(context, l.nothingYesterday, info: true);
                                },
                              ),
                            ]
                          : [
                              VChip(label: l.saveAsMeal, icon: 'star', onTap: saveMeal),
                              VChip(label: l.copyToTomorrow, icon: 'repeat', onTap: copyTomorrow),
                            ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.mealDetailTip)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
