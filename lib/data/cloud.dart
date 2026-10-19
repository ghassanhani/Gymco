import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// The project this build talks to. The publishable key is meant to ship in
/// the app; row level security and the server functions decide what it can
/// do. Override for another project with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`,
/// or pass empty values for a phone-only build.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://vncadogzpeoawikgafaj.supabase.co');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_8ZM7KKxLHCzpUpfygmyFcA_5kK_PY2P',
);

/// A food the model saw or read about, named in English for the database and
/// in the user's language for the screen, with its estimated portion and
/// typical nutrition per 100 g. All of it is an estimate.
class PhotoFood {
  const PhotoFood({
    required this.name,
    required this.local,
    required this.sure,
    this.grams,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
  });
  final String name;
  final String local;
  final bool sure;

  /// The portion as eaten.
  final double? grams;

  /// Per 100 g.
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;

  /// Enough to log it without a database match.
  bool get hasNutrition => kcal != null && protein != null && carbs != null && fat != null;

  factory PhotoFood.fromJson(Map<String, Object?> j) {
    double? n(String k) => switch (j[k]) {
      final num v when v >= 0 && v.isFinite => v.toDouble(),
      _ => null,
    };
    return PhotoFood(
      name: j['name'] as String? ?? '',
      local: j['local'] as String? ?? (j['name'] as String? ?? ''),
      sure: j['sure'] as bool? ?? false,
      grams: n('grams'),
      kcal: n('kcal'),
      protein: n('protein'),
      carbs: n('carbs'),
      fat: n('fat'),
    );
  }
}

/// Why a cloud call did not go through, in terms the screen can say.
enum CloudFailure { notSetUp, signedOut, offline, dailyCap, refused, busy, badCode, unknown }

class CloudException implements Exception {
  const CloudException(this.failure);
  final CloudFailure failure;

  @override
  String toString() => 'CloudException(${failure.name})';
}

/// The one backup an account keeps.
class CloudBackup {
  const CloudBackup({required this.payload, required this.at});
  final Map<String, Object?> payload;
  final DateTime at;
}

/// Sent beside a backup so the admin dashboard can show the platform and
/// language mix without opening the backup itself.
class BackupMeta {
  const BackupMeta({this.platform, required this.locale, this.appVersion});

  /// 'ios' or 'android'; null elsewhere.
  final String? platform;

  /// 'en', 'ar' or 'es'.
  final String locale;
  final String? appVersion;
}

/// Accounts, backup and the AI photo scan. Everything else works without it.
abstract class Cloud {
  /// False when this build has no project to talk to.
  bool get available;
  String? get email;
  Stream<String?> get emailChanges;

  /// Emails a sign-in link (and a six-digit code, when the email template
  /// shows one); there are no passwords.
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> signOut();
  Future<void> deleteAccount();

  Future<void> upload(Map<String, Object?> payload, {required int schemaVersion, BackupMeta? meta});
  Future<CloudBackup?> download();

  /// Names the foods in a JPEG, a written description, or both, with
  /// estimated portions. Returns them with the scans left today.
  Future<(List<PhotoFood>, int)> scanPhoto(Uint8List? jpeg, {required String languageCode, String note = ''});
}

/// A build with no project: phone-only.
class NoCloud implements Cloud {
  const NoCloud();
  @override
  bool get available => false;
  @override
  String? get email => null;
  @override
  Stream<String?> get emailChanges => const Stream.empty();
  Never _no() => throw const CloudException(CloudFailure.notSetUp);
  @override
  Future<void> sendCode(String email) async => _no();
  @override
  Future<void> verifyCode(String email, String code) async => _no();
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async => _no();
  @override
  Future<void> upload(Map<String, Object?> payload, {required int schemaVersion, BackupMeta? meta}) async => _no();
  @override
  Future<CloudBackup?> download() async => _no();
  @override
  Future<(List<PhotoFood>, int)> scanPhoto(Uint8List? jpeg, {required String languageCode, String note = ''}) async =>
      _no();
}

class SupabaseCloud implements Cloud {
  SupabaseCloud(this._sb);
  final SupabaseClient _sb;

  @override
  bool get available => true;
  @override
  String? get email => _sb.auth.currentUser?.email;
  @override
  Stream<String?> get emailChanges => _sb.auth.onAuthStateChange.map((s) => s.session?.user.email);

  String get _uid => _sb.auth.currentUser?.id ?? (throw const CloudException(CloudFailure.signedOut));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on CloudException {
      rethrow;
    } on AuthException catch (e) {
      final code = e.code ?? '';
      throw CloudException(
        code.contains('otp') || code.contains('token') || e.statusCode == '403'
            ? CloudFailure.badCode
            : code.contains('rate')
            ? CloudFailure.busy
            : CloudFailure.unknown,
      );
    } on FunctionException catch (e) {
      throw CloudException(switch (e.status) {
        401 => CloudFailure.signedOut,
        429 => CloudFailure.dailyCap,
        422 => CloudFailure.refused,
        502 || 503 => CloudFailure.busy,
        _ => CloudFailure.unknown,
      });
    } on PostgrestException {
      throw const CloudException(CloudFailure.unknown);
    } on Exception {
      throw const CloudException(CloudFailure.offline);
    }
  }

  /// Where the email's sign-in link sends the phone. Registered in the app's
  /// Android manifest and iOS Info.plist, and allowed in Supabase's redirect URLs.
  static const signInRedirect = 'app.gymco.gymco://login-callback';

  @override
  Future<void> sendCode(String email) => _guard(
    () => _sb.auth.signInWithOtp(email: email.trim(), shouldCreateUser: true, emailRedirectTo: signInRedirect),
  );

  @override
  Future<void> verifyCode(String email, String code) =>
      _guard(() => _sb.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email));

  @override
  Future<void> signOut() => _guard(() => _sb.auth.signOut());

  @override
  Future<void> deleteAccount() => _guard(() async {
    await _sb.functions.invoke('delete-account');
    await _sb.auth.signOut(scope: SignOutScope.local);
  });

  @override
  Future<void> upload(Map<String, Object?> payload, {required int schemaVersion, BackupMeta? meta}) => _guard(
    () => _sb.from('backups').upsert({
      'user_id': _uid,
      'payload': payload,
      'schema_version': schemaVersion,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'platform': ?meta?.platform,
      'locale': ?meta?.locale,
      'app_version': ?meta?.appVersion,
    }),
  );

  @override
  Future<CloudBackup?> download() => _guard(() async {
    final row = await _sb.from('backups').select('payload, updated_at').eq('user_id', _uid).maybeSingle();
    if (row == null) return null;
    final payload = row['payload'];
    return CloudBackup(
      payload: (payload is String ? jsonDecode(payload) : payload) as Map<String, Object?>,
      at: DateTime.parse(row['updated_at'] as String).toLocal(),
    );
  });

  @override
  Future<(List<PhotoFood>, int)> scanPhoto(Uint8List? jpeg, {required String languageCode, String note = ''}) =>
      _guard(() async {
        _uid;
        final r = await _sb.functions.invoke(
          'food-photo',
          body: {
            'image': ?(jpeg == null ? null : base64Encode(jpeg)),
            'note': ?(note.trim().isEmpty ? null : note.trim()),
            'lang': languageCode,
          },
        );
        final data = (r.data is String ? jsonDecode(r.data as String) : r.data) as Map<String, Object?>;
        final foods = [
          for (final f in (data['foods'] as List? ?? const []))
            if (f is Map) PhotoFood.fromJson(f.cast<String, Object?>()),
        ].where((f) => f.name.isNotEmpty).toList();
        return (foods, (data['left'] as num?)?.toInt() ?? 0);
      });
}
