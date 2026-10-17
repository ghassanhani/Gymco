import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/volt.dart';
import 'kit/kit.dart';

/// The five tabs under the Volt tab bar; Train is the raised lime centre.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Volt.bg,
      body: Stack(
        children: [
          Positioned.fill(child: shell),
          VTabBar(
            current: shell.currentIndex,
            labels: [l.tabToday, l.tabFood, l.tabTrain, l.tabProgress, l.tabMe],
            onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          ),
        ],
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
    return VScreen(
      child: Column(
        children: [
          VAppBar(title: title),
          Expanded(
            child: Pad(
              children: [VCard(child: Muted(l.nextBuild, color: Volt.t2))],
            ),
          ),
        ],
      ),
    );
  }
}
