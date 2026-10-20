import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../state/config_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// Sits over the whole app: the maintenance screen, the hard update block, or
/// a dismissible nudge when a newer build is recommended. The diary on the
/// phone is never touched by any of them.
class AppGateView extends ConsumerStatefulWidget {
  const AppGateView({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppGateView> createState() => _AppGateViewState();
}

class _AppGateViewState extends ConsumerState<AppGateView> {
  bool _nudgeDismissed = false;

  @override
  void initState() {
    super.initState();
    ref.read(remoteConfigProvider.notifier).start();
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(appGateProvider);
    final l = AppLocalizations.of(context);
    return switch (gate) {
      AppGate.maintenance => _Blocker(
        title: l.gateRestingTitle,
        body: ref.watch(remoteConfigProvider).maintenanceMessage(Localizations.localeOf(context).languageCode),
      ),
      AppGate.updateRequired => _Blocker(title: l.gateUpdateTitle, body: l.gateUpdateBody, update: l.gateUpdateCta),
      AppGate.updateSuggested when !_nudgeDismissed => Stack(
        children: [
          widget.child,
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: SafeArea(
              child: Material(
                color: Volt.card2,
                borderRadius: BorderRadius.circular(Volt.rRow),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.gateSuggest, style: TextStyle(color: Volt.t1, fontSize: 14)),
                      ),
                      VBtn(
                        label: l.gateLater,
                        small: true,
                        kind: BtnKind.ghost,
                        onTap: () => setState(() => _nudgeDismissed = true),
                      ),
                      VBtn(label: l.gateUpdateCta, small: true, onTap: _openStore),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      _ => widget.child,
    };
  }
}

Future<void> _openStore() => launchUrl(
  Uri.parse(Platform.isAndroid ? 'market://details?id=app.gymco.gymco' : 'itms-apps://apps.apple.com/'),
  mode: LaunchMode.externalApplication,
);

class _Blocker extends StatelessWidget {
  const _Blocker({required this.title, required this.body, this.update});
  final String title;
  final String body;
  final String? update;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Volt.bg,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VIcon('shield', size: 32, color: Volt.accentInk),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(color: Volt.t1, fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Muted(body, size: 15, color: Volt.t2),
            if (update != null) ...[const SizedBox(height: 28), VBtn(label: update!, expand: true, onTap: _openStore)],
          ],
        ),
      ),
    ),
  );
}
