import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../state/catchup_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

enum _Fill { usual, rough, leave }

/// Days with nothing logged: fill them roughly from the usual week, or
/// leave them out so they do not skew the expenditure average.
class CatchupScreen extends ConsumerStatefulWidget {
  const CatchupScreen({super.key});

  @override
  ConsumerState<CatchupScreen> createState() => _CatchupScreenState();
}

class _CatchupScreenState extends ConsumerState<CatchupScreen> {
  final _fill = <String, _Fill>{};
  final _rough = <String, double>{};
  bool _saving = false;

  Future<void> _save(List<OpenDay> days, UsualDay usual) async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    final fills = <String, UsualDay>{};
    final leave = <String>[];
    for (final d in days) {
      switch (_fill[d.day] ?? _Fill.usual) {
        case _Fill.usual:
          fills[d.day] = usual;
        case _Fill.rough:
          final kcal = _rough[d.day] ?? usual.kcal.roundToDouble();
          fills[d.day] = (kcal: kcal, protein: usual.protein * kcal / usual.kcal);
        case _Fill.leave:
          leave.add(d.day);
      }
    }
    await ref.read(catchupActionsProvider).save(fills, leave);
    if (!mounted) return;
    showVToast(context, l.catchupSaved(days.length));
    context.canPop() ? context.pop() : context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final days = ref.watch(openDaysProvider).value ?? const <OpenDay>[];
    final usual = ref.watch(usualDayProvider).value ?? (kcal: 2000.0, protein: 120.0);
    final locale = Localizations.localeOf(context).toString();

    Widget day(OpenDay d) {
      final fill = _fill[d.day] ?? _Fill.usual;
      final rough = _rough[d.day] ?? usual.kcal.roundToDouble();
      final what = d.trained != null
          ? l.catchupTrained(d.trained!)
          : d.planned != null
          ? l.catchupPlanned(d.planned!)
          : l.catchupRest;
      return VCard(
        child: GapCol(
          gap: 12,
          cross: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: GapCol(
                    gap: 2,
                    children: [
                      Text(
                        DateFormat('EEEE d MMM', locale).format(d.date),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Volt.t1),
                      ),
                      Muted(what),
                    ],
                  ),
                ),
                if (d.trained != null) const VIcon('dumb', size: 18, color: Volt.brandInk),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (f, label) in [
                  (_Fill.usual, l.catchupUsual),
                  (_Fill.rough, l.catchupRough),
                  (_Fill.leave, l.catchupLeave),
                ])
                  VChip(label: label, on: fill == f, onTap: () => setState(() => _fill[d.day] = f)),
              ],
            ),
            if (fill == _Fill.rough)
              Row(
                children: [
                  Expanded(child: Muted(l.catchupRoughLabel)),
                  VStepper(
                    label: '${fmtInt(context, rough)} ${l.kcal}',
                    onMinus: rough > 600 ? () => setState(() => _rough[d.day] = rough - 100) : null,
                    onPlus: rough < 6000 ? () => setState(() => _rough[d.day] = rough + 100) : null,
                  ),
                ],
              ),
            Muted(switch (fill) {
              _Fill.usual => l.catchupUsualNote(fmtInt(context, usual.kcal), fmtInt(context, usual.protein)),
              _Fill.rough => l.catchupRoughNote,
              _Fill.leave => l.catchupLeaveNote,
            }),
          ],
        ),
      );
    }

    return Scaffold(
      body: VScreen(
        overlays: [
          LogBar(
            aboveTabs: false,
            children: [
              Expanded(child: Muted(l.catchupFooter)),
              VBtn(
                label: l.catchupSave(days.length),
                small: true,
                onTap: days.isEmpty || _saving ? null : () => _save(days, usual),
              ),
            ],
          ),
        ],
        child: Column(
          children: [
            BackBar(title: l.catchupTitle, titleSize: 20),
            Expanded(
              child: Pad(
                bottom: 120,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GapCol(
                      gap: 4,
                      children: [EmTitle(l.catchupHeadEm, size: 24), Muted(l.catchupSub(days.length))],
                    ),
                  ),
                  for (final d in days) day(d),
                  if (days.isEmpty) VCard(child: Muted(l.catchupNone)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// On Today: a quiet nudge when recent days have no food.
class CatchupCard extends ConsumerWidget {
  const CatchupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final days = ref.watch(openDaysProvider).value ?? const <OpenDay>[];
    if (days.isEmpty) return const SizedBox.shrink();
    return VCard(
      tight: true,
      color: Volt.brandWash,
      border: Border.all(color: Volt.brandEdge),
      onTap: () => context.push('/catchup'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: Volt.brand, shape: BoxShape.circle),
            child: const VIcon('clock', size: 20, color: Volt.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GapCol(
              gap: 2,
              children: [
                Text(
                  l.catchupCard(days.length),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                ),
                Muted(l.catchupCardSub),
              ],
            ),
          ),
          const VIcon('fwd', size: 18, color: Volt.brandInk),
        ],
      ),
    );
  }
}
