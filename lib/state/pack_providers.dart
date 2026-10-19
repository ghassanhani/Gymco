import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud.dart';
import '../data/food_names.dart';
import '../data/packs.dart';
import 'cloud_providers.dart';
import 'config_providers.dart';
import 'providers.dart';

// Phone-only keys (never backed up): each pack's verified body and version.
String _bodyKey(String kind) => 'rc.pack.$kind';
String _versionKey(String kind) => 'rc.pack.$kind.version';

/// The content packs: the ones this phone holds at once on launch, then
/// whatever changed each time the config is fetched. A download is kept
/// only when it hashes to both the served and the listed checksum;
/// otherwise the phone keeps the pack it had.
class PacksNotifier extends Notifier<Packs> {
  bool _dbSynced = false;

  @override
  Packs build() {
    final prefs = ref.watch(prefsProvider);
    var p = Packs.empty;
    for (final kind in packKinds) {
      if (prefs.getString(_bodyKey(kind)) case final body?) p = p.withKind(kind, body);
    }
    _apply(p);
    return p;
  }

  void _apply(Packs p) {
    Packs.current = p;
    setPackFoodNames(p.foodNames);
  }

  /// Brings the packs in line with app-config's `packs` [listing]:
  /// `{ <kind>: { version, checksum } }`. Only kinds whose version changed
  /// are downloaded; a kind that is no longer listed is dropped.
  Future<void> sync(Map<String, Object?> listing) async {
    final prefs = ref.read(prefsProvider);
    final cloud = ref.read(cloudProvider);
    var next = state;
    final bodies = <String, String?>{};
    final versions = <String, int>{};
    for (final kind in packKinds) {
      final held = prefs.getString(_bodyKey(kind));
      final entry = listing[kind];
      if (entry is! Map) {
        if (held != null || prefs.containsKey(_versionKey(kind))) bodies[kind] = null;
        continue;
      }
      final (version, listed) = (entry['version'], entry['checksum']);
      if (version is! num || listed is! String) continue;
      if (held != null && prefs.getInt(_versionKey(kind)) == version.toInt()) continue;
      PackDownload? d;
      try {
        d = await cloud.fetchPack(kind);
      } on CloudException {
        continue;
      }
      if (d == null || d.kind != kind) continue;
      final mine = packChecksum(d.bodyJson);
      if (mine != d.checksum.toLowerCase() || mine != listed.toLowerCase()) continue;
      bodies[kind] = d.bodyJson;
      versions[kind] = version.toInt();
    }
    for (final MapEntry(key: kind, value: body) in bodies.entries) {
      next = next.withKind(kind, body);
    }
    // The database first, so a phone closed halfway fetches the pack again.
    if (bodies.containsKey('foods') || !_dbSynced) {
      await ref.read(dbProvider).syncPackFoods(next.foods);
      _dbSynced = true;
    }
    for (final MapEntry(key: kind, value: body) in bodies.entries) {
      if (body == null) {
        await prefs.remove(_bodyKey(kind));
        await prefs.remove(_versionKey(kind));
      } else {
        await prefs.setString(_bodyKey(kind), body);
        await prefs.setInt(_versionKey(kind), versions[kind]!);
      }
    }
    if (bodies.isEmpty) return;
    _apply(next);
    state = next;
  }
}

final packsProvider = NotifierProvider<PacksNotifier, Packs>(PacksNotifier.new);

// ---------------- Pro ----------------

/// The signed-in user's own entitlement row; null signed out, offline or
/// when there is none.
final entitlementProvider = FutureProvider<Entitlement?>((ref) async {
  final email = ref.watch(accountProvider).value;
  final cloud = ref.watch(cloudProvider);
  if ((email ?? cloud.email) == null) return null;
  try {
    return await cloud.fetchEntitlement();
  } on CloudException {
    return null;
  }
});

/// Why Pro is on, or that it is not.
enum ProAccess {
  /// Granted to this account (by hand or bought) and not expired.
  granted,

  /// Everyone has Pro while Gymco is in testing.
  testing,

  /// Neither.
  locked,
}

final proAccessProvider = Provider<ProAccess>((ref) {
  final e = ref.watch(entitlementProvider).value;
  if (e != null && e.activeAt(ref.watch(clockProvider)())) return ProAccess.granted;
  return ref.watch(remoteConfigProvider).testingUnlockAll ? ProAccess.testing : ProAccess.locked;
});

/// Every Pro feature is unlocked.
final proUnlockedProvider = Provider<bool>((ref) => ref.watch(proAccessProvider) != ProAccess.locked);
