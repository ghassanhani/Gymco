import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cloud.dart';
import '../data/local_db.dart';
import '../data/photo_picker.dart';
import 'providers.dart';
import 'training_providers.dart';

/// Phone-only unless main() was given a project.
final cloudProvider = Provider<Cloud>((_) => const NoCloud());

final photoPickerProvider = Provider<PhotoPicker>((_) => DevicePhotoPicker());

/// The signed-in email, or null.
final accountProvider = StreamProvider<String?>((ref) async* {
  final cloud = ref.watch(cloudProvider);
  yield cloud.email;
  yield* cloud.emailChanges;
});

const _lastBackupKey = 'lastBackup';

/// When this phone last backed up, if it has.
final lastBackupProvider = Provider<DateTime?>((ref) {
  final ms = ref.watch(prefsProvider).getInt(_lastBackupKey);
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
});

/// Settings that belong to this phone or to the sign-in itself, not to the
/// person: never backed up, never overwritten by a restore.
bool _phoneOnly(String key) => key.startsWith('sb-') || key.startsWith('supabase') || key == _lastBackupKey;

/// Everything the user made, as one document.
Future<Map<String, Object?>> backupPayload(LocalDb db, SharedPreferences prefs) async => {
  'db': await db.exportAll(),
  'favourites': await db.favouriteIds(),
  'prefs': {
    for (final k in prefs.getKeys())
      if (!_phoneOnly(k)) k: prefs.get(k),
  },
};

/// The installed version, as "1.0.2 (102)"; filled in by main() from the
/// platform, null in tests.
final appVersionProvider = Provider<String?>((_) => null);

final cloudActionsProvider = Provider<CloudActions>(CloudActions.new);

class CloudActions {
  CloudActions(this.ref);
  final Ref ref;

  Future<void> backupNow() async {
    final db = ref.read(dbProvider);
    final prefs = ref.read(prefsProvider);
    await ref
        .read(cloudProvider)
        .upload(await backupPayload(db, prefs), schemaVersion: LocalDb.schemaVersion, meta: _meta());
    await prefs.setInt(_lastBackupKey, ref.read(clockProvider)().millisecondsSinceEpoch);
    ref.invalidate(lastBackupProvider);
  }

  BackupMeta _meta() {
    const supported = {'en', 'ar', 'es'};
    final lang =
        ref.read(settingsProvider).languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return BackupMeta(
      platform: switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => null,
      },
      locale: supported.contains(lang) ? lang : 'en',
      appVersion: ref.read(appVersionProvider),
    );
  }

  /// Backs up at most every six hours, quietly; a failure waits for next time.
  Future<void> backupIfDue() async {
    final cloud = ref.read(cloudProvider);
    if (!cloud.available || cloud.email == null) return;
    final last = ref.read(lastBackupProvider);
    if (last != null && ref.read(clockProvider)().difference(last) < const Duration(hours: 6)) return;
    try {
      await backupNow();
    } on CloudException {
      // Offline or signed out: the next pause tries again.
    }
  }

  /// Replaces what is on the phone with [backup].
  Future<void> restore(CloudBackup backup) async {
    final db = ref.read(dbProvider);
    final prefs = ref.read(prefsProvider);
    await db.importAll((backup.payload['db'] as Map? ?? const {}).cast<String, Object?>());
    for (final id in (backup.payload['favourites'] as List? ?? const []).whereType<String>()) {
      await db.setFavourite(id, true);
    }
    for (final k in prefs.getKeys().toList()) {
      if (!_phoneOnly(k)) await prefs.remove(k);
    }
    for (final MapEntry(:key, :value)
        in (backup.payload['prefs'] as Map? ?? const {}).cast<String, Object?>().entries) {
      if (_phoneOnly(key)) continue;
      switch (value) {
        case final bool v:
          await prefs.setBool(key, v);
        case final int v:
          await prefs.setInt(key, v);
        case final double v:
          await prefs.setDouble(key, v);
        case final String v:
          await prefs.setString(key, v);
        case final List v:
          await prefs.setStringList(key, v.whereType<String>().toList());
      }
    }
    // Everything read from the phone reads it again.
    ref.invalidate(dbProvider);
    ref.invalidate(prefsProvider);
    ref.invalidate(routinesProvider);
    ref.invalidate(recentWorkoutsProvider);
  }
}
