import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../theme/volt.dart';
import 'kit/kit.dart';

/// The five tabs under the Volt tab bar; Train is the raised lime centre.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with SingleTickerProviderStateMixin {
  // Switching tabs fades the new one through, with a slight rise.
  late final _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  late final _t = CurvedAnimation(parent: _fade, curve: voltEase);

  @override
  void didUpdateWidget(AppShell old) {
    super.didUpdateWidget(old);
    if (old.shell.currentIndex != widget.shell.currentIndex) _fade.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final shell = widget.shell;
    return Scaffold(
      backgroundColor: Volt.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _t,
              builder: (_, child) => Opacity(
                opacity: 0.35 + 0.65 * _t.value,
                child: Transform.translate(offset: Offset(0, (1 - _t.value) * 10), child: child),
              ),
              child: shell,
            ),
          ),
          // Behind the keyboard, not riding on top of it.
          if (View.of(context).viewInsets.bottom == 0)
            VTabBar(
              current: shell.currentIndex,
              labels: [l.tabToday, l.tabFood, l.tabTrain, l.tabProgress, l.tabMe],
              onTap: (i) {
                // A tab switch keeps the old tab alive, focus and all: let go of it.
                FocusManager.instance.primaryFocus?.unfocus();
                shell.goBranch(i, initialLocation: i == shell.currentIndex);
              },
            ),
        ],
      ),
    );
  }
}
