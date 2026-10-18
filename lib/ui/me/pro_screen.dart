import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// `.procard`: the lime Gymco Pro card at the top of Me. While Gymco is in
/// testing there is nothing to buy, so it says Pro is on and opens what Pro
/// covers.
class ProCard extends StatelessWidget {
  const ProCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const ink = Volt.ink;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final title = l.proTitle;
    final m = RegExp(r'<em>(.*?)</em>').firstMatch(title);
    const base = TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.96, height: 1, color: ink);
    final em = arabic
        ? base
        : const TextStyle(
            fontFamily: 'InstrumentSerif',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            fontSize: 32 * 1.15,
            color: ink,
          );

    return Semantics(
      button: true,
      label: l.proCardLabel,
      excludeSemantics: true,
      child: Pressable(
        onTap: () => context.push('/pro'),
        scale: 0.98,
        radius: 28,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE4FF6A), Color(0xFFB6F02A), Color(0xFF5EE4A0)],
              stops: [0, 0.48, 1],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xE6B6F02A), blurRadius: 44, offset: Offset(0, 26), spreadRadius: -26),
            ],
          ),
          child: Stack(
            children: [
              // The white sheen in the top corner.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: AlignmentDirectional.topEnd.resolve(Directionality.of(context)),
                      radius: 0.9,
                      colors: const [Color(0x73FFFFFF), Color(0x00FFFFFF)],
                      stops: const [0, 0.6],
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                end: -30,
                top: -28,
                child: Transform.rotate(
                  angle: 0.31,
                  child: const VIcon('star', size: 170, color: Color(0x1A0A0B09), strokeWidth: 1.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: GapCol(
                  gap: 10,
                  cross: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const _ProBadge(),
                        const SizedBox(width: 8),
                        Text(
                          l.proFreeTesting,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xA60A0B09)),
                        ),
                      ],
                    ),
                    Text.rich(
                      TextSpan(
                        style: base,
                        children: m == null
                            ? [TextSpan(text: title)]
                            : [
                                TextSpan(text: title.substring(0, m.start)),
                                TextSpan(text: m.group(1), style: em),
                                TextSpan(text: title.substring(m.end)),
                              ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -2),
                      child: Text(
                        l.proSub,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xB30A0B09)),
                      ),
                    ),
                    GapCol(
                      gap: 6,
                      children: [
                        for (final t in [l.proPoint1, l.proPoint2, l.proPoint3])
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(color: ink, shape: BoxShape.circle),
                                child: const VIcon('check', size: 12, color: Volt.brand, strokeWidth: 2.6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 6, 6, 6),
                      decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l.proCta,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Volt.t1),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  l.proCtaSub,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Volt.t3),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [Color(0xFFE4FF6A), Color(0xFF5EE4A0)]),
                            ),
                            child: const VIcon('fwd', size: 18, color: ink),
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
      ),
    );
  }
}

/// `.pro-badge`: ink pill, lime star and PRO.
class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: Volt.ink, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VIcon('star', size: 13, color: Volt.brand),
        const SizedBox(width: 5),
        Text(
          AppLocalizations.of(context).proBadge,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.92, color: Volt.brand),
        ),
      ],
    ),
  );
}

/// Free vs Pro: what stays free for good, what Pro adds, and the plans it
/// will have. Nothing is sold while Gymco is in testing.
class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  int _plan = 1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final plans = [
      (l.planMonthly, '€4.99', null),
      (l.planYearly, '€39.99', l.planYearlySub),
      (l.planLifetime, '€89', null),
    ];
    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: l.freeVsPro, titleSize: 20),
            Expanded(
              child: Pad(
                bottom: 16,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                    child: GapCol(
                      gap: 6,
                      children: [
                        Text(
                          l.proHeadline,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: Volt.t1,
                          ),
                        ),
                        Muted(l.proHeadlineSub),
                      ],
                    ),
                  ),
                  VCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: GapCol(
                      gap: 10,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Eyebrow(l.freeForever),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in [
                              l.freeBarcode,
                              l.freeCustomFoods,
                              l.freeRecipes,
                              l.freeCopyDay,
                              l.freeRoutines,
                              l.freeCustomExercises,
                              l.freeRestTimer,
                              l.freeTrendWeight,
                              l.freeExport,
                            ])
                              VTag(t),
                          ],
                        ),
                      ],
                    ),
                  ),
                  VCard(
                    color: Volt.brandWash,
                    border: Border.all(color: Volt.brand),
                    child: GapCol(
                      gap: 12,
                      cross: CrossAxisAlignment.stretch,
                      children: [
                        Eyebrow(l.proAdds, color: Volt.brandInk),
                        for (final (lead, rest) in [
                          (l.proAdds1Lead, l.proAdds1),
                          (l.proAdds2Lead, l.proAdds2),
                          ('', l.proAdds3),
                          ('', l.proAdds4),
                        ])
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: VIcon('check', size: 17, color: Volt.brandInk),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(fontSize: 14, height: 1.45, color: Volt.t1),
                                    children: [
                                      if (lead.isNotEmpty)
                                        TextSpan(
                                          text: '$lead ',
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      TextSpan(text: rest),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, (name, price, sub)) in plans.indexed) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          flex: i == 1 ? 115 : 100,
                          child: Pressable(
                            onTap: () => setState(() => _plan = i),
                            label: '$name $price',
                            radius: 18,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: i == _plan ? Volt.brandWash : Volt.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: i == _plan ? Volt.brand : Volt.line, width: 1.5),
                              ),
                              child: GapCol(
                                gap: 3,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(fontSize: 12, color: i == _plan ? Volt.brandInk : Volt.t3),
                                  ),
                                  Text(price, style: numStyle(17)),
                                  if (sub != null) Muted(sub),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  VCard(
                    tight: true,
                    border: Border.all(color: Volt.brandEdge),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: VIcon('info', size: 17, color: Volt.brandInk),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Muted(l.proTestingNote, color: Volt.t2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 18 + MediaQuery.paddingOf(context).bottom),
              child: GapCol(
                gap: 10,
                cross: CrossAxisAlignment.stretch,
                children: [
                  VBtn(label: l.proOnAction, expand: true, onTap: () => context.pop()),
                  Muted(l.proKeepNote, align: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
