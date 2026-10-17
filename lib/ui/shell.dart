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
