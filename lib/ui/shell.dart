import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/volt.dart';
import 'common/widgets.dart';

/// The five tabs. The centre one (Train) is the big raised lime button.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tabs = [
      (Icons.home_rounded, l.tabToday),
      (Icons.restaurant_rounded, l.tabFood),
      (Icons.fitness_center_rounded, l.tabTrain),
      (Icons.insights_rounded, l.tabProgress),
      (Icons.person_rounded, l.tabMe),
    ];
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xEB15171A),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0x0FFFFFFF)),
            boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 44, offset: Offset(0, 22), spreadRadius: -18)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < tabs.length; i++)
                i == 2
                    ? _CentreTab(icon: tabs[i].$1, label: tabs[i].$2, on: shell.currentIndex == i, onTap: () => _go(i))
                    : Expanded(
                        child: _Tab(
                          icon: tabs[i].$1,
                          label: tabs[i].$2,
                          on: shell.currentIndex == i,
                          onTap: () => _go(i),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = on ? Volt.brand : Volt.t3;
    return Semantics(
      selected: on,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 3,
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: on ? Volt.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: on ? const [BoxShadow(color: Volt.brand, blurRadius: 12)] : null,
                ),
              ),
              Icon(icon, size: 22, color: c),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CentreTab extends StatelessWidget {
  const _CentreTab({required this.icon, required this.label, required this.on, required this.onTap});
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -22),
      child: Semantics(
        selected: on,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Container(
          width: 64,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: Volt.glow,
            boxShadow: [
              BoxShadow(color: Volt.bg, spreadRadius: 6),
              BoxShadow(color: Color(0xD9B6F02A), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -8),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Icon(icon, size: 26, color: Volt.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Honest stand-in for tabs that are designed but not built yet.
class NextBuildScreen extends StatelessWidget {
  const NextBuildScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return VoltBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.headlineMedium),
              const SizedBox(height: 16),
              VoltCard(child: Text(l.nextBuild, style: t.bodyMedium)),
            ],
          ),
        ),
      ),
    );
  }
}
