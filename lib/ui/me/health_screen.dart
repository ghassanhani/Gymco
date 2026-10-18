import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await setHealth(ref, on);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) showVToast(context, l.healthRefused, info: true);
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
        if (on) const VIcon('check', size: 16, color: Volt.ok),
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
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: Volt.t1,
                              ),
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
                                const VIcon('shield', size: 19, color: Volt.t3),
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
