import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/site.dart';
import '../../l10n/app_localizations.dart';
import '../../state/pack_providers.dart';
import '../../theme/volt.dart';
import '../kit/kit.dart';

/// `.procard`: the lime Gymco Pro card at the top of Me. While Gymco is in
/// testing there is nothing to buy, so it says Pro is on and opens what Pro
/// covers; a manual grant says it is on for this account.
class ProCard extends ConsumerWidget {
  const ProCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final access = ref.watch(proAccessProvider);
    final until = ref.watch(entitlementProvider).value?.expiresAt;
    final (badge, cta, ctaSub, label) = switch (access) {
      ProAccess.testing => (l.proFreeTesting, l.proCta, l.proCtaSub, l.proCardLabel),
      ProAccess.granted => (
        l.proGrantedBadge,
        l.proCta,
        until == null
            ? l.proGrantedSub
            : l.proGrantedUntil(DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(until)),
        l.proGrantedLabel,
      ),
      ProAccess.locked => (l.proLockedBadge, l.proLockedCta, l.proLockedSub, l.proLockedLabel),
    };
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
      label: label,
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
                        // Long in Spanish: wraps instead of running off the card.
                        Expanded(
                          child: Text(
                            badge,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xA60A0B09)),
                          ),
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
                                  cta,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Volt.t1),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  ctaSub,
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

/// One plan card's look: its colour, its glyph, and what it includes.
typedef _Plan = ({String name, String sub, String icon, List<Color> glow, Set<int> has, bool pro});

/// Free vs Pro as plan cards to swipe through: what each one includes,
/// with the price for monthly or yearly. Nothing is sold while Gymco is in
/// testing, so every card says Pro is on.
class ProScreen extends ConsumerStatefulWidget {
  const ProScreen({super.key});

  @override
  ConsumerState<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends ConsumerState<ProScreen> {
  final _pages = PageController(viewportFraction: 0.84, initialPage: 1);
  int _page = 1;
  bool _yearly = true;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final features = [
      l.featLogging,
      l.freeRoutines,
      l.freeTrendWeight,
      l.featAi,
      l.proPoint1,
      l.proPoint2,
      l.proPoint3,
      l.featOnce,
    ];
    final plans = <_Plan>[
      (
        name: l.planFree,
        sub: l.planFreeSub,
        icon: 'user',
        glow: const [Color(0xFF3A3F46), Color(0xFF22262B)],
        has: {0, 1, 2},
        pro: false,
      ),
      (
        name: l.planPro,
        sub: l.planProSub,
        icon: 'star',
        glow: const [Color(0xFFE4FF6A), Color(0xFF5EE4A0)],
        has: {0, 1, 2, 3, 4, 5, 6},
        pro: true,
      ),
      (
        name: l.planLifetime,
        sub: l.planLifetimeSub,
        icon: 'medal',
        glow: const [Color(0xFF4CC9F0), Color(0xFF8B7CF6)],
        has: {0, 1, 2, 3, 4, 5, 6, 7},
        pro: true,
      ),
    ];
    final prices = [(l.priceFree, ''), _yearly ? ('€39.99', l.perYear) : ('€4.99', l.perMonth), ('€89', l.once)];

    return Scaffold(
      body: VScreen(
        child: Column(
          children: [
            BackBar(title: '', icon: 'close'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: 24 + MediaQuery.paddingOf(context).bottom),
                children: [
                  Center(child: _Pill(l.plansPill)),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: EmTitle(l.plansTitleEm, size: 32, align: TextAlign.center),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          for (final (i, (icon, label)) in [
                            ('camera', l.featIconAi),
                            ('chart', l.featIconCoach),
                            ('dumb', l.featIconStrength),
                          ].indexed) ...[
                            if (i > 0) const VerticalDivider(width: 1, color: Volt.line2, indent: 6, endIndent: 6),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Volt.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Volt.line2),
                                    ),
                                    child: VIcon(icon, size: 22, color: Volt.brandInk),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12.5, color: Volt.t2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: _Period(yearly: _yearly, onChanged: (v) => setState(() => _yearly = v)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 700,
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: plans.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) => AnimatedScale(
                        scale: i == _page ? 1 : 0.94,
                        duration: const Duration(milliseconds: 260),
                        curve: voltEase,
                        child: _PlanCard(plan: plans[i], price: prices[i], features: features, popular: i == 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < plans.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _page ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page ? Volt.brand : Volt.line2,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Muted(switch (ref.watch(proAccessProvider)) {
                      ProAccess.testing => l.proTestingNote,
                      ProAccess.granted => l.proGrantedNote,
                      ProAccess.locked => l.proLockedNote,
                    }, align: TextAlign.center),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Link(l.termsOfUse, () => openSite('terms')),
                      const Muted('  ·  '),
                      _Link(l.privacyPolicy, () => openSite('privacy')),
                    ],
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

/// `( Plans )`: the small pill above the headline.
class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: Volt.card,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Volt.line2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VIcon('star', size: 13, color: Volt.brandInk),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Volt.t1),
        ),
      ],
    ),
  );
}

/// Monthly or yearly, with what yearly saves.
class _Period extends StatelessWidget {
  const _Period({required this.yearly, required this.onChanged});
  final bool yearly;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget seg(String label, bool v, {String? tag}) => Pressable(
      onTap: () => onChanged(v),
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: yearly == v ? Volt.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: yearly == v ? Volt.ink : Volt.t2),
            ),
            if (tag != null) ...[
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: yearly == v ? const Color(0xB30A0B09) : Volt.brandInk,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Volt.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Volt.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(l.planMonthly, false),
          seg(l.planYearly, true, tag: l.save33),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.price, required this.features, required this.popular});
  final _Plan plan;
  final (String, String) price;
  final List<String> features;
  final bool popular;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tint = plan.glow.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Volt.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: popular ? Volt.brandEdge : Volt.line2),
      ),
      child: Stack(
        children: [
          // The plan's colour rising from the bottom of the card.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, tint.withValues(alpha: 0.22)],
                  stops: const [0, 0.55, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: plan.glow),
                    boxShadow: [BoxShadow(color: tint.withValues(alpha: 0.45), blurRadius: 26, spreadRadius: -6)],
                  ),
                  child: VIcon(plan.icon, size: 28, color: plan.pro ? Volt.ink : Volt.t1),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(fontFamily: 'InstrumentSerif', fontSize: 32, height: 1.05, color: Volt.t1),
                    ),
                    if (popular) ...[const SizedBox(width: 8), VTag(l.mostPopular)],
                  ],
                ),
                const SizedBox(height: 4),
                Muted(plan.sub, align: TextAlign.center),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price.$1, style: numStyle(30, weight: FontWeight.w800)),
                    if (price.$2.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(price.$2, style: const TextStyle(fontSize: 13, color: Volt.t3)),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // The divider with the plan's mark in the middle.
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: tint.withValues(alpha: 0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Transform.rotate(angle: 0.785, child: Container(width: 8, height: 8, color: tint)),
                    ),
                    Expanded(child: Container(height: 1, color: tint.withValues(alpha: 0.5))),
                  ],
                ),
                const SizedBox(height: 12),
                for (final (i, f) in features.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: plan.has.contains(i) ? Volt.brand : Volt.line,
                          ),
                          child: VIcon(
                            plan.has.contains(i) ? 'check' : 'close',
                            size: 12,
                            strokeWidth: 2.4,
                            color: plan.has.contains(i) ? Volt.ink : Volt.t4,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: TextStyle(fontSize: 13.5, color: plan.has.contains(i) ? Volt.t1 : Volt.t4),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                VBtn(
                  label: plan.pro ? l.proIsOnTesting : l.freeAlwaysBtn,
                  kind: plan.pro ? BtnKind.primary : BtnKind.ghost,
                  expand: true,
                  onTap: () => context.pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Volt.t2,
            decoration: TextDecoration.underline,
            decorationColor: Volt.t3,
          ),
        ),
      ),
    ),
  );
}
