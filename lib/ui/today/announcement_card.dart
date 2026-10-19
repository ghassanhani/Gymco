import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../state/messaging_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// On Today: the newest live announcement, in the app's language, until it
/// is dismissed or ends. Today lists it only while there is one.
class AnnouncementCard extends ConsumerWidget {
  const AnnouncementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final a = ref.watch(liveAnnouncementProvider);
    if (a == null) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    final body = a.bodyIn(lang);
    final cta = a.cta;
    return VCard(
      tight: true,
      color: Volt.brandWash,
      border: Border.all(color: Volt.brandEdge),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GapCol(
              gap: 6,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    a.titleIn(lang),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Volt.t1),
                  ),
                ),
                if (body.isNotEmpty) Muted(body, color: Volt.t2),
                if (cta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: VBtn(
                      label: cta.labelIn(lang),
                      kind: BtnKind.start,
                      trailingIcon: 'fwd',
                      onTap: () => launchUrl(cta.url, mode: LaunchMode.externalApplication),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconBtn(
            'close',
            small: true,
            iconSize: 16,
            background: Colors.transparent,
            color: Volt.brandInk,
            label: l.announcementDismiss,
            onTap: () => ref.read(messagingProvider.notifier).dismiss(a.id),
          ),
        ],
      ),
    );
  }
}

/// Shows the release note for this build once, the first time Today is
/// built with one pending, and records the build before the sheet opens so
/// it never shows twice.
class WhatsNewGate extends ConsumerWidget {
  const WhatsNewGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(pendingWhatsNewProvider) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final wn = ref.read(pendingWhatsNewProvider);
        if (wn == null) return;
        ref.read(messagingProvider.notifier).markWhatsNewShown(wn.build);
        _show(context, wn);
      });
    }
    return child;
  }

  Future<void> _show(BuildContext context, WhatsNew wn) {
    final l = AppLocalizations.of(context);
    final bullets = wn.bulletsIn(Localizations.localeOf(context).languageCode);
    return showVSheet<void>(
      context,
      title: l.whatsNewTitle(wn.version),
      body: (ctx) => [
        VCard(
          child: GapCol(
            gap: 10,
            cross: CrossAxisAlignment.stretch,
            children: [
              for (final b in bullets)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: VIcon('check', size: 14, color: Volt.brandInk),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(b, style: const TextStyle(fontSize: 15, color: Volt.t1, height: 1.35)),
                    ),
                  ],
                ),
            ],
          ),
        ),
        VBtn(label: l.whatsNewOk, expand: true, onTap: () => Navigator.pop(ctx)),
      ],
    );
  }
}
