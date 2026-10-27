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
enum CloudFailure { notSetUp, signedOut, offline, dailyCap, refused, busy, paused, badCode, unknown }

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

/// One published content pack as `app-config?pack=<kind>` serves it.
/// [bodyJson] is the server's canonical JSON string and [checksum] the
/// lowercase hex SHA-256 of its UTF-8 bytes; the phone hashes exactly these
/// bytes before it trusts them.
class PackDownload {
  const PackDownload({required this.kind, required this.version, required this.checksum, required this.bodyJson});
  final String kind;
  final int version;
  final String checksum;
  final String bodyJson;

  /// Null when the response is not a pack.
  static PackDownload? fromJson(Object? j) => switch (j) {
    {
      'kind': final String kind,
      'version': final num version,
      'checksum': final String checksum,
      'body_json': final String body,
    } =>
      PackDownload(kind: kind, version: version.toInt(), checksum: checksum, bodyJson: body),
    _ => null,
  };
}

/// The signed-in user's own row in `entitlements`: Pro or Lifetime, granted
/// by hand or bought, with its end (none for Lifetime or an open grant).
class Entitlement {
  const Entitlement({required this.plan, this.expiresAt});

  /// 'pro' or 'lifetime'.
  final String plan;
  final DateTime? expiresAt;

  bool activeAt(DateTime now) => expiresAt == null || expiresAt!.isAfter(now);
}

/// Accounts, backup and the AI photo scan. Everything else works without it.
abstract class Cloud {
  /// False when this build has no project to talk to.
  bool get available;
  String? get email;
  Stream<String?> get emailChanges;

  /// Emails a sign-in link and a six-digit code; there are no passwords.
  /// [locale] picks the email's language for a new account.
  Future<void> sendCode(String email, {String locale = 'en'});

  /// Keeps the account's language in step with the app, so the next sign-in
  /// email (supabase/templates) comes in it. Best effort: never throws.
  Future<void> rememberLocale(String locale);
  Future<void> verifyCode(String email, String code);
  Future<void> signOut();
  Future<void> deleteAccount();

  Future<void> upload(Map<String, Object?> payload, {required int schemaVersion, BackupMeta? meta});
  Future<CloudBackup?> download();

  /// Names the foods in a JPEG, a written description, or both, with
  /// estimated portions. Returns them with the scans left today.
  /// [feature] 'eating_out' marks an eating-out estimate; [bucket] is this
  /// install's fixed 0–99 slot for model rollouts.
  Future<(List<PhotoFood>, int)> scanPhoto(
    Uint8List? jpeg, {
    required String languageCode,
    String note = '',
    String? feature,
    int? bucket,
  });

  /// What a voice note says, written down in the language it was spoken in
  /// (Arabic and English may mix). Takes one of the day's AI requests.
  Future<String> transcribe(Uint8List audio, {required String languageCode, required double seconds, int? bucket});

  /// Training routines built from the user's own words, picked from
  /// [exercises] (the names the phone's library has). Returns the raw answer
  /// for [planFrom] with the AI credits left today.
  Future<(Map<String, Object?>, int)> planRoutines(
    String text, {
    required List<String> exercises,
    required String languageCode,
    int? bucket,
  });

  /// Iron, the coach: [mode] 'tip' for today's tip, 'program' for a full
  /// program. [numbers] is the summary of the user's numbers (no diary text,
  /// photos or notes); [exercises] and [ask] are for a program.
  Future<(Map<String, Object?>, int)> askIron({
    required String mode,
    required Map<String, Object?> numbers,
    required String languageCode,
    List<String> exercises = const [],
    String ask = '',
    int? bucket,
  });

  /// The published remote config for this device, or null when there is
  /// none to fetch. Works signed out.
  Future<Map<String, Object?>?> fetchConfig(Map<String, String> device);

  /// One published content pack, or null when there is none. Works signed out.
  Future<PackDownload?> fetchPack(String kind);

  /// The signed-in user's entitlement, or null when signed out or there is none.
  Future<Entitlement?> fetchEntitlement();

  /// Sends a message to support through the public `support-ticket`
  /// function; works signed out. [kind] is 'general' or 'deletion'. At most
  /// five a day per email: the sixth fails with [CloudFailure.dailyCap].
  Future<void> sendSupportTicket({
    required String email,
    required String subject,
    required String body,
    required String locale,
    String? appVersion,
    String? platform,
    String kind = 'general',
  });
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
  Future<void> sendCode(String email, {String locale = 'en'}) async => _no();
  @override
  Future<void> rememberLocale(String locale) async {}
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
  Future<(List<PhotoFood>, int)> scanPhoto(
    Uint8List? jpeg, {
    required String languageCode,
    String note = '',
    String? feature,
    int? bucket,
  }) async => _no();
  @override
  Future<String> transcribe(
    Uint8List audio, {
    required String languageCode,
    required double seconds,
    int? bucket,
  }) async => _no();
  @override
  Future<(Map<String, Object?>, int)> planRoutines(
    String text, {
    required List<String> exercises,
    required String languageCode,
    int? bucket,
  }) async => _no();
  @override
  Future<(Map<String, Object?>, int)> askIron({
    required String mode,
    required Map<String, Object?> numbers,
    required String languageCode,
    List<String> exercises = const [],
    String ask = '',
    int? bucket,
  }) async => _no();
  @override
  Future<Map<String, Object?>?> fetchConfig(Map<String, String> device) async => null;
  @override
  Future<PackDownload?> fetchPack(String kind) async => null;
  @override
  Future<Entitlement?> fetchEntitlement() async => null;
  @override
  Future<void> sendSupportTicket({
    required String email,
    required String subject,
    required String body,
    required String locale,
    String? appVersion,
    String? platform,
    String kind = 'general',
  }) async => _no();
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
        503 when _isPaused(e.details) => CloudFailure.paused,
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
  Future<void> sendCode(String email, {String locale = 'en'}) => _guard(
    () => _sb.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
      emailRedirectTo: signInRedirect,
      data: {'locale': locale},
    ),
  );

  @override
  Future<void> rememberLocale(String locale) async {
    if (_sb.auth.currentUser == null || _sb.auth.currentUser!.userMetadata?['locale'] == locale) return;
    try {
      await _sb.auth.updateUser(UserAttributes(data: {'locale': locale}));
    } catch (_) {
      // Only the email's language rides on this; the next sign-in tries again.
    }
  }

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

  static bool _isPaused(Object? details) {
    final d = details is String
        ? (() {
            try {
              return jsonDecode(details);
            } catch (_) {
              return null;
            }
          })()
        : details;
    return d is Map && d['error'] == 'paused';
  }

  @override
  Future<Map<String, Object?>?> fetchConfig(Map<String, String> device) => _guard(() async {
    final r = await _sb.functions.invoke('app-config', method: HttpMethod.get, queryParameters: device);
    final data = r.data is String ? jsonDecode(r.data as String) : r.data;
    return data is Map ? data.cast<String, Object?>() : null;
  });

  @override
  Future<PackDownload?> fetchPack(String kind) => _guard(() async {
    final r = await _sb.functions.invoke('app-config', method: HttpMethod.get, queryParameters: {'pack': kind});
    return PackDownload.fromJson(r.data is String ? jsonDecode(r.data as String) : r.data);
  });

  @override
  Future<Entitlement?> fetchEntitlement() => _guard(() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;
    // Row level security lets a user read only their own row.
    final row = await _sb.from('entitlements').select('plan, expires_at').eq('user_id', uid).maybeSingle();
    if (row == null || row['plan'] is! String) return null;
    final ends = row['expires_at'];
    return Entitlement(
      plan: row['plan'] as String,
      expiresAt: ends is String ? DateTime.tryParse(ends)?.toLocal() : null,
    );
  });

  @override
  Future<void> sendSupportTicket({
    required String email,
    required String subject,
    required String body,
    required String locale,
    String? appVersion,
    String? platform,
    String kind = 'general',
  }) => _guard(
    // Public: no sign-in needed. The client sends the session's JWT when
    // there is one, which the function ignores.
    () => _sb.functions.invoke(
      'support-ticket',
      body: {
        'email': email.trim(),
        'subject': subject.trim(),
        'body': body.trim(),
        'locale': locale,
        'app_version': ?appVersion,
        'platform': ?platform,
        'kind': kind,
      },
    ),
  );

  @override
  Future<(List<PhotoFood>, int)> scanPhoto(
    Uint8List? jpeg, {
    required String languageCode,
    String note = '',
    String? feature,
    int? bucket,
  }) => _guard(() async {
    _uid;
    final r = await _sb.functions.invoke(
      'food-photo',
      body: {
        'image': ?(jpeg == null ? null : base64Encode(jpeg)),
        'note': ?(note.trim().isEmpty ? null : note.trim()),
        'lang': languageCode,
        'feature': ?feature,
        'bucket': ?bucket,
      },
    );
    final data = (r.data is String ? jsonDecode(r.data as String) : r.data) as Map<String, Object?>;
    final foods = [
      for (final f in (data['foods'] as List? ?? const []))
        if (f is Map) PhotoFood.fromJson(f.cast<String, Object?>()),
    ].where((f) => f.name.isNotEmpty).toList();
    return (foods, (data['left'] as num?)?.toInt() ?? 0);
  });

  @override
  Future<String> transcribe(Uint8List audio, {required String languageCode, required double seconds, int? bucket}) =>
      _guard(() async {
        _uid;
        final r = await _sb.functions.invoke(
          'transcribe',
          body: {
            'audio': base64Encode(audio),
            'lang': languageCode,
            'seconds': double.parse(seconds.toStringAsFixed(1)),
            'bucket': ?bucket,
          },
        );
        final data = (r.data is String ? jsonDecode(r.data as String) : r.data) as Map<String, Object?>;
        return '${data['text'] ?? ''}'.trim();
      });

  @override
  Future<(Map<String, Object?>, int)> planRoutines(
    String text, {
    required List<String> exercises,
    required String languageCode,
    int? bucket,
  }) => _guard(() async {
    _uid;
    final r = await _sb.functions.invoke(
      'routine-ai',
      body: {'text': text.trim(), 'exercises': exercises, 'lang': languageCode, 'bucket': ?bucket},
    );
    final data = (r.data is String ? jsonDecode(r.data as String) : r.data) as Map<String, Object?>;
    return (data, (data['left'] as num?)?.toInt() ?? 0);
  });

  @override
  Future<(Map<String, Object?>, int)> askIron({
    required String mode,
    required Map<String, Object?> numbers,
    required String languageCode,
    List<String> exercises = const [],
    String ask = '',
    int? bucket,
  }) => _guard(() async {
    _uid;
    final r = await _sb.functions.invoke(
      'iron',
      body: {
        'mode': mode,
        'numbers': numbers,
        'lang': languageCode,
        if (exercises.isNotEmpty) 'exercises': exercises,
        if (ask.trim().isNotEmpty) 'ask': ask.trim(),
        'bucket': ?bucket,
      },
    );
    final data = (r.data is String ? jsonDecode(r.data as String) : r.data) as Map<String, Object?>;
    return (data, (data['left'] as num?)?.toInt() ?? 0);
  });
}
