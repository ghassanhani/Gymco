import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/packs.dart';
import '../../state/pack_providers.dart';

/// Puts the content packs where [copyText] can read them, so a screen that
/// shows overridden copy rebuilds when the copy pack changes.
class PacksScope extends ConsumerWidget {
  const PacksScope({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _Packs(packs: ref.watch(packsProvider), child: child);
}

class _Packs extends InheritedWidget {
  const _Packs({required this.packs, required super.child});
  final Packs packs;

  @override
  bool updateShouldNotify(_Packs old) => old.packs.copyOverrides != packs.copyOverrides;
}

/// [builtIn], or the copy pack's override of [key] in the app's language
/// when it has one. Only the keys in [copyKeys] can be overridden.
String copyText(BuildContext context, String key, String builtIn) {
  final packs = context.dependOnInheritedWidgetOfExactType<_Packs>()?.packs ?? Packs.current;
  return packs.copy(key, Localizations.localeOf(context).languageCode, builtIn);
}
