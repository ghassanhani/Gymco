import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud.dart';
import '../domain/remote_config.dart';
import 'cloud_providers.dart';
import 'messaging_providers.dart';
import 'pack_providers.dart';
import 'providers.dart';

// Phone-only keys (never backed up): the last config and this install's slot.
const _configKey = 'rc.config';
const _versionKey = 'rc.version';
const _bucketKey = 'rc.bucket';

/// A fixed 0–99 slot for this install, chosen at random once. Targeting by
/// percent and model rollouts use it; it never identifies anyone.
final installBucketProvider = Provider<int>((ref) {
  final prefs = ref.watch(prefsProvider);
  final saved = prefs.getInt(_bucketKey);
  if (saved != null && saved >= 0 && saved < 100) return saved;
  final b = Random().nextInt(100);
  unawaited(prefs.setInt(_bucketKey, b));
  return b;
});

/// The installed build number, from "1.0.2 (102)"; null when unknown.
final appBuildProvider = Provider<int?>((ref) {
  final m = RegExp(r'\((\d+)\)').firstMatch(ref.watch(appVersionProvider) ?? '');
  return m == null ? null : int.parse(m.group(1)!);
});

/// The remote config: the last one fetched (or the built-in defaults) at
/// once, then a fresh copy on launch and every 6 h. A failed fetch keeps
/// what the phone has; nothing the user does waits on it.
class RemoteConfigNotifier extends Notifier<RemoteConfig> {
  Timer? _timer;

  @override
  RemoteConfig build() {
    ref.onDispose(() => _timer?.cancel());
    final prefs = ref.watch(prefsProvider);
    var c = RemoteConfig.defaults;
    try {
      final raw = prefs.getString(_configKey);
      if (raw != null) {
        c = RemoteConfig.fromJson(jsonDecode(raw) as Map<String, Object?>, version: prefs.getInt(_versionKey) ?? 0);
      }
    } catch (_) {
      // A damaged cache is the same as none.
    }
    RemoteConfig.current = c;
    return c;
  }

  /// Starts the launch fetch and the 6-hourly one.
  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(hours: 6), (_) => refresh());
    unawaited(refresh());
  }

  Future<void> refresh() async {
    final meta = deviceMeta(ref);
    final build = ref.read(appBuildProvider);
    Map<String, Object?>? data;
    try {
      data = await ref.read(cloudProvider).fetchConfig({
        'platform': ?meta.platform,
        'locale': meta.locale,
        'build': ?build?.toString(),
        'bucket': '${ref.read(installBucketProvider)}',
      });
    } on CloudException {
      return;
    }
    if (data == null) return;
    final body = data['config'];
    if (body is Map) {
      final version = (data['config_version'] as num?)?.toInt() ?? 0;
      final c = RemoteConfig.fromJson(body.cast<String, Object?>(), version: version);
      final prefs = ref.read(prefsProvider);
      await prefs.setString(_configKey, jsonEncode(c.toJson()));
      await prefs.setInt(_versionKey, version);
      RemoteConfig.current = c;
      state = c;
    }
    // What the server has to say: announcements and the release note.
    await ref.read(messagingProvider.notifier).store(data);
    // The content packs listed beside it: download what changed.
    if (data['packs'] case final Map packs) await ref.read(packsProvider.notifier).sync(packs.cast<String, Object?>());
  }
}

final remoteConfigProvider = NotifierProvider<RemoteConfigNotifier, RemoteConfig>(RemoteConfigNotifier.new);

/// What stands between the user and the app right now.
enum AppGate { open, updateSuggested, updateRequired, maintenance }

final appGateProvider = Provider<AppGate>((ref) {
  final c = ref.watch(remoteConfigProvider);
  if (c.maintenance) return AppGate.maintenance;
  final build = ref.watch(appBuildProvider);
  if (build == null) return AppGate.open;
  final platform = deviceMeta(ref).platform;
  if (platform != null && build < c.minBuild(platform)) return AppGate.updateRequired;
  if (build < c.recommendedBuild) return AppGate.updateSuggested;
  return AppGate.open;
});
