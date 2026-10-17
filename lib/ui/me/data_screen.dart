import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/training_providers.dart';
import '../../theme/volt.dart';
import '../common/format.dart';
import '../kit/kit.dart';

/// Your data: take it with you, see what you agreed to, or delete it all.
class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    try {
      final all = await ref.read(dbProvider).exportAll();
      final dir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd-HHmm').format(ref.read(clockProvider)());
      final json = File(p.join(dir.path, 'gymco-$stamp.json'));
      await json.writeAsString(const JsonEncoder.withIndent('  ').convert(all));
      final files = [XFile(json.path)];
      for (final MapEntry(key: table, value: rows) in all.entries) {
        if (rows.isEmpty) continue;
        final cols = rows.first.keys.toList();
        final csv = File(p.join(dir.path, 'gymco-$stamp-$table.csv'));
        await csv.writeAsString(
          [cols.join(','), for (final r in rows) cols.map((c) => _cell(r[c])).join(',')].join('\n'),
        );
        files.add(XFile(csv.path));
      }
      await SharePlus.instance.share(ShareParams(files: files));
    } catch (_) {
      if (context.mounted) showVToast(context, l.exportFailed, info: true);
    }
  }

  static String _cell(Object? v) {
    final s = v?.toString() ?? '';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) => showVSheet<void>(
    context,
    title: AppLocalizations.of(context).deleteConfirmTitle,
    body: (ctx) {
      final l = AppLocalizations.of(ctx);
      return [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.deleteEverythingBody)),
        SRow(label: l.keepMyData, onTap: () => Navigator.pop(ctx)),
        SRow(
          label: l.deleteConfirm,
          tint: Volt.warn,
          onTap: () async {
            Navigator.pop(ctx);
            ref.read(activeWorkoutProvider.notifier).discard();
            await deleteEverything(ref);
            ref.invalidate(routinesProvider);
            ref.invalidate(recentWorkoutsProvider);
            if (context.mounted) context.go('/onboarding');
          },
        ),
      ];
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = ref.watch(dataCountsProvider).value;
    final consent = consentedAt(ref.watch(prefsProvider));
    final date = DateFormat('d MMM', Localizations.localeOf(context).toString());

    Widget badge(String icon, {bool lime = false}) => Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: lime ? Volt.brandWash : Volt.card2, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: VIcon(icon, size: 19, color: lime ? Volt.brandInk : Volt.t1),
    );

    Widget head(String icon, String title, String sub, {bool lime = false}) => Row(
      children: [
        badge(icon, lime: lime),
        const SizedBox(width: 12),
        Expanded(
          child: GapCol(
            gap: 2,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
              ),
              Muted(sub),
            ],
          ),
        ),
      ],
    );

    Widget consentRow(String text, bool on, DateTime? at) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Volt.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Volt.line),
      ),
      child: Row(
        children: [
          VIcon(on ? 'check' : 'close', size: 16, color: on ? Volt.ok : Volt.t4),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: on ? Volt.t2 : Volt.t3)),
          ),
          if (at != null) Muted(date.format(at)),
        ],
      ),
    );

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.yourData, titleSize: 20),
            Expanded(
              child: Pad(
                bottom: 24,
                children: [
                  VCard(
                    child: GapCol(
                      gap: 12,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        head('dl', l.takeEverything, l.takeEverythingSub),
                        if (c != null)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              VTag(l.foodLogRows(fmtInt(context, c.entries))),
                              VTag(l.dataSetsCount(fmtInt(context, c.sets))),
                              VTag(l.weighInsCount(fmtInt(context, c.weighIns))),
                            ],
                          ),
                        VBtn(label: l.exportNow, kind: BtnKind.ghost, expand: true, onTap: () => _export(context, ref)),
                      ],
                    ),
                  ),
                  VCard(
                    child: GapCol(
                      gap: 12,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.whatYouAgreed,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Volt.t1),
                        ),
                        consentRow(l.consentHealthRow, consent != null, consent),
                        consentRow(l.consentAnalyticsRow, false, null),
                        Muted(l.onPhoneNote),
                      ],
                    ),
                  ),
                  VCard(
                    border: Border.all(color: Volt.line2),
                    child: GapCol(
                      gap: 12,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        head('trash', l.deleteEverything, l.deleteEverythingSub, lime: true),
                        Muted(l.deleteEverythingBody, color: Volt.t2),
                        Pressable(
                          onTap: () => _delete(context, ref),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Volt.brandEdge, width: 1.5),
                            ),
                            child: Text(
                              l.deleteAllData,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.brandInk),
                            ),
                          ),
                        ),
                      ],
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
