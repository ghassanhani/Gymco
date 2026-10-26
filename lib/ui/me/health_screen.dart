import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../state/health_providers.dart';
import '../../state/providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// What Gymco reads from Apple Health or Health Connect and what it writes.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  late final _available = ref.read(healthSyncProvider).available();
  bool _busy = false;

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    final ok = await setHealth(ref, on);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) _whyNot();
  }

  /// The phone did not show its permission screen, or said no: say what to
  /// do, with what the phone reported, so it can be fixed.
  void _whyNot() {
    final l = AppLocalizations.of(context);
    final error = ref.read(healthSyncProvider).lastError;
    showVSheet<void>(
      context,
      title: Platform.isIOS ? l.healthNotOpenIos : l.healthNotOpen,
      body: (ctx) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Muted(Platform.isIOS ? l.healthWhyIos : l.healthWhyAndroid, color: Volt.t2),
        ),
        if (error != null)
          VCard(
            tight: true,
            child: GapCol(
              gap: 4,
              children: [
                Eyebrow(l.healthPhoneSaid),
                SelectableText(error, style: TextStyle(fontSize: 12.5, color: Volt.t3, height: 1.4)),
              ],
            ),
          ),
        VBtn(
          label: l.tryAgain,
          expand: true,
          onTap: () {
            Navigator.pop(ctx);
            _toggle(true);
          },
        ),
        if (Platform.isIOS)
          VBtn(
            label: l.openHealthApp,
            kind: BtnKind.ghost,
            expand: true,
            onTap: () => launchUrl(Uri.parse('x-apple-health://')),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final on = ref.watch(healthOnProvider);
    final store = Platform.isIOS ? l.appleHealth : l.healthConnect;

    Widget line(String icon, String title, String sub) => VItem(
      children: [
        VIcon(icon, size: 19, color: on ? Volt.brandInk : Volt.t3),
        ItemText(title, sub: sub),
        if (on) VIcon('check', size: 16, color: Volt.ok),
      ],
    );

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.healthData, titleSize: 20),
            Expanded(
              child: FutureBuilder<bool>(
                future: _available,
                builder: (context, snap) {
                  final available = snap.data ?? true;
                  return Pad(
                    bottom: 24,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                        child: GapCol(
                          gap: 6,
                          children: [
                            Text(
                              l.healthHeadline,
                              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600, height: 1.3, color: Volt.t1),
                            ),
                            Muted(l.healthBody),
                          ],
                        ),
                      ),
                      if (!available)
                        VCard(
                          tight: true,
                          border: Border.all(color: Volt.warnEdge),
                          child: GapCol(
                            gap: 10,
                            cross: CrossAxisAlignment.stretch,
                            children: [
                              Muted(l.healthConnectMissing),
                              VBtn(
                                label: l.installHealthConnect,
                                kind: BtnKind.ghost,
                                small: true,
                                expand: true,
                                onTap: () => ref.read(healthSyncProvider).install(),
                              ),
                            ],
                          ),
                        )
                      else
                        VList(
                          children: [
                            VItem(
                              onTap: _busy ? null : () => _toggle(!on),
                              semantics: l.connectStore(store),
                              children: [
                                VIcon('shield', size: 19, color: Volt.t3),
                                ItemText(l.connectStore(store), sub: on ? l.healthOn : l.healthOff),
                                VToggle(on: on),
                              ],
                            ),
                          ],
                        ),
                      Eyebrow(l.readsFromHealth, padding: const EdgeInsetsDirectional.only(start: 4)),
                      VList(
                        children: [
                          line('scale', l.healthWeight, l.healthWeightSub),
                          line('bolt', l.healthSteps, l.healthStepsSub),
                          line('watch', l.healthWatchWorkouts, l.healthWatchWorkoutsSub),
                          line('moon', l.recoverySleep, l.healthSleepSub),
                          line('pulse', l.healthHeart, l.healthHeartSub),
                          line('bolt', l.healthActive, l.healthActiveSub),
                        ],
                      ),
                      Eyebrow(l.writesToHealth, padding: const EdgeInsetsDirectional.only(start: 4)),
                      VList(
                        children: [
                          line('dumb', l.healthWorkouts, l.healthWorkoutsSub),
                          line('drop', l.healthWater, l.healthWaterSub),
                          line('scale', l.healthWeighIns, l.healthWeighInsSub),
                        ],
                      ),
                      if (on) ...[
                        Eyebrow(l.healthSeenTitle, padding: const EdgeInsetsDirectional.only(start: 4)),
                        _HealthSeen(store: store),
                      ],
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.healthNote)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the health store actually shared this week, kind by kind, so a band
/// whose app isn't sending anything shows up as "nothing yet" right here.
class _HealthSeen extends ConsumerWidget {
  const _HealthSeen({required this.store});
  final String store;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final seen = ref.watch(healthCheckProvider);
    final rows = [
      ('moon', l.recoverySleep, 'sleep'),
      ('pulse', l.heartRateTitle, 'heartRate'),
      ('heart', l.recoveryRestingHr, 'restingHr'),
      ('heart', l.recoveryHrv, 'hrv'),
      ('shoe', l.healthSteps, 'steps'),
      ('bolt', l.healthActive, 'activeKcal'),
      ('watch', l.healthWatchWorkouts, 'workouts'),
    ];
    final data = seen.value;
    return GapCol(
      gap: 8,
      cross: CrossAxisAlignment.stretch,
      children: [
        VList(
          children: [
            for (final (icon, name, key) in rows)
              VItem(
                children: [
                  VIcon(icon, size: 18, color: Volt.t3),
                  ItemText(
                    name,
                    sub: data == null
                        ? l.healthSeenLooking
                        : switch (data[key]) {
                            final s? when s.count > 0 =>
                              s.sources.isEmpty
                                  ? l.healthSeenCount(s.count)
                                  : l.healthSeenFrom(s.count, s.sources.take(2).join(', ')),
                            _ => l.healthSeenNone,
                          },
                    subColor: data != null && (data[key]?.count ?? 0) == 0 ? Volt.warn : null,
                  ),
                  if (data != null && (data[key]?.count ?? 0) > 0) VIcon('check', size: 16, color: Volt.ok),
                ],
              ),
          ],
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Muted(l.healthSeenHelp(store), size: 12.5)),
        Center(
          child: TextButton(
            onPressed: () => ref.invalidate(healthCheckProvider),
            child: Text(l.healthSeenAgain, style: TextStyle(fontSize: 13, color: Volt.brandInk)),
          ),
        ),
      ],
    );
  }
}
