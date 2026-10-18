import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

/// One line of what is about to be logged.
typedef LogLine = ({String name, double grams, double kcal, double protein});

/// The last look before food goes into the diary: what, how much, the
/// total, and which meal. True when confirmed.
Future<bool> confirmLog(BuildContext context, {required String meal, required List<LogLine> lines}) async {
  final l = AppLocalizations.of(context);
  final kcal = lines.fold<double>(0, (s, x) => s + x.kcal);
  final protein = lines.fold<double>(0, (s, x) => s + x.protein);
  final ok = await showVSheet<bool>(
    context,
    title: l.confirmLogTitle(meal),
    body: (ctx) => [
      VList(
        children: [
          for (final x in lines)
            VItem(
              children: [
                ItemText(x.name, sub: '${fmtInt(ctx, x.grams)} ${l.grams}'),
                Text(fmtInt(ctx, x.kcal), style: numStyle(14, color: Volt.t2)),
              ],
            ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Muted(l.itemsCount(lines.length))),
            Text(fmtInt(ctx, kcal), style: numStyle(22)),
            const SizedBox(width: 6),
            Muted('${l.kcal} · ${fmtInt(ctx, protein)} g P'),
          ],
        ),
      ),
      VBtn(label: l.confirmLogAction, icon: 'check', expand: true, onTap: () => Navigator.pop(ctx, true)),
      VBtn(label: l.keepEditing, kind: BtnKind.ghost, expand: true, onTap: () => Navigator.pop(ctx, false)),
    ],
  );
  return ok ?? false;
}
