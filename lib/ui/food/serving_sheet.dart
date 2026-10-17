import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../common/widgets.dart';

/// Pick an amount and log it. Kcal and macros track every digit typed.
/// Returns true when something was logged.
Future<bool> showServingSheet(BuildContext context, {required Food food, required Meal meal}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (_) => _ServingSheet(food: food, meal: meal),
  );
  return r ?? false;
}

class _ServingSheet extends ConsumerStatefulWidget {
  const _ServingSheet({required this.food, required this.meal});
  final Food food;
  final Meal meal;

  @override
  ConsumerState<_ServingSheet> createState() => _ServingSheetState();
}

class _ServingSheetState extends ConsumerState<_ServingSheet> {
  late final TextEditingController _g = TextEditingController(
    text: (widget.food.servingGrams ?? 100).round().toString(),
  );

  double get _grams => double.tryParse(_g.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _g.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    final day = ref.read(todayKeyProvider);
    await ref.read(logActionsProvider).add(LogEntry.of(widget.food, day: day, meal: widget.meal, grams: _grams));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final f = widget.food;
    final k = _grams / 100;
    final noNumbers = ref.watch(settingsProvider.select((s) => s.noNumbers));

    Widget stat(String label, String value, Color c) => Expanded(
      child: Column(
        children: [
          Text(value, style: t.titleMedium?.copyWith(color: c)),
          const SizedBox(height: 2),
          Text(label, style: t.bodySmall),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.name, style: t.titleLarge),
              if (f.brand != null) Text(f.brand!, style: t.bodySmall),
              const SizedBox(height: 20),
              TextField(
                controller: _g,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                onChanged: (_) => setState(() {}),
                style: t.headlineMedium,
                decoration: InputDecoration(labelText: l.amount, suffixText: l.grams),
              ),
              if (f.servingGrams != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final g in {f.servingGrams!.roundToDouble(), 100.0})
                      ActionChip(
                        label: Text('${fmtInt(context, g)} ${l.grams}'),
                        onPressed: () => setState(() => _g.text = g.round().toString()),
                      ),
                  ],
                ),
              ],
              if (!noNumbers) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    stat(l.kcal, fmtInt(context, f.kcal * k), Volt.t1),
                    stat(l.protein, '${fmtInt(context, f.protein * k)} ${l.grams}', Volt.protein),
                    stat(l.carbs, '${fmtInt(context, f.carbs * k)} ${l.grams}', Volt.carbs),
                    stat(l.fat, '${fmtInt(context, f.fat * k)} ${l.grams}', Volt.fat),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GlowButton(label: l.log, onPressed: _grams > 0 ? _log : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
