/// What the Control Center can change without a new build: feature
/// switches, limits, the safety numbers, the update gate and maintenance.
///
/// Every value has today's default and the same hard bounds as the server's
/// schema, so a bad or missing config can never take the app outside them.
/// Phones fetch it on launch and every 6 h, and keep the last copy.
library;

class RemoteConfig {
  const RemoteConfig._(this._raw, {this.version = 0});

  factory RemoteConfig.fromJson(Map<String, Object?> json, {int version = 0}) => RemoteConfig._(json, version: version);

  static const defaults = RemoteConfig._({});

  /// The config the domain rules read. Set when the app loads or fetches one.
  static RemoteConfig current = defaults;

  final Map<String, Object?> _raw;

  /// The published version this came from; 0 for the built-in defaults.
  final int version;

  Map<String, Object?> toJson() => _raw;

  Object? _v(String group, String key) => switch (_raw[group]) {
    final Map<Object?, Object?> g => g[key],
    _ => null,
  };
  bool _b(String g, String k, bool d) => switch (_v(g, k)) {
    final bool b => b,
    _ => d,
  };
  num _n(String g, String k, num d, num lo, num hi) => switch (_v(g, k)) {
    final num n when n.isFinite => n.clamp(lo, hi),
    _ => d,
  };
  int _i(String g, String k, int d, int lo, int hi) => _n(g, k, d, lo, hi).round();
  double _d(String g, String k, double d, double lo, double hi) => _n(g, k, d, lo, hi).toDouble();

  // Features
  bool get photoLog => _b('features', 'photo_log', true) && _b('ai', 'photo', true);
  bool get eatingOut => _b('features', 'eating_out', true);
  bool get eatingOutAi => eatingOut && _b('ai', 'eating_out', true);
  bool get routineAi => _b('ai', 'routine', true);
  bool get coachAi => _b('ai', 'coach', true);
  bool get voiceAi => _b('ai', 'voice', true);
  bool get dictate => _b('features', 'dictate', true);
  bool get barcodeContribute => _b('features', 'barcode_contribute', true);
  bool get cheatMeals => _b('features', 'cheat_meals', true);
  bool get catchUp => _b('features', 'catch_up', true);
  bool get monthlyChallenge => _b('features', 'monthly_challenge', true);

  // Notifications
  /// A notification the Control Center has not switched off, by the
  /// app's name for it.
  bool noteOn(String kind) => _b('notifications', kind, true);
  int get noteDailyCap => _i('notifications', 'daily_cap', 3, 1, 5);
  int get quietFromHour => _i('notifications', 'quiet_from', 23, 0, 23);
  int get quietToHour => _i('notifications', 'quiet_to', 7, 0, 23);

  /// Words set in the Control Center for a notification's [part] (title or
  /// body) in [lang], the feminine Arabic first for a woman; null keeps the
  /// app's own.
  String? noteText(String kind, String part, String lang, {bool female = false}) {
    final text = _v('notifications', 'text');
    if (text is! Map || text[kind] is! Map || (text[kind] as Map)[part] is! Map) return null;
    final by = (text[kind] as Map)[part] as Map;
    for (final l in [if (female && lang == 'ar') 'ar_f', lang]) {
      if (by[l] case final String s when s.trim().isNotEmpty) return s.trim();
    }
    return null;
  }

  // Limits
  int get aiScansPerDay => _i('limits', 'ai_scans_per_day', 10, 1, 100);
  int get photoNoteMaxChars => _i('limits', 'photo_note_max_chars', 500, 20, 500);
  int get backupIntervalMin => _i('limits', 'backup_interval_min', 0, 0, 1440);

  // Safety
  double get calorieFloor => _d('safety', 'calorie_floor', 1700, 1200, 2500);
  double get maxRatePctWeek => _d('safety', 'max_rate_pct_week', 1, 0.1, 1);
  double get maxWeeklyChange => _d('safety', 'max_weekly_target_change_kcal', 120, 20, 120);
  double get bankedSliceWarnKcal => _d('safety', 'banked_slice_warn_kcal', 300, 100, 500);

  // Water
  int get waterMlPerKg => _i('water', 'ml_per_kg', 35, 25, 45);
  int get waterTrainingBonusMl => (_d('water', 'training_day_bonus_l', 0.5, 0, 1.5) * 1000).round();
  int get waterMinMl => (_d('water', 'min_l', 1.5, 1, 3) * 1000).round();
  int get waterMaxMl => (_d('water', 'max_l', 5, 3, 8) * 1000).round();

  // Streak
  int get freezeEveryDays => _i('streak', 'freeze_every_days', 7, 3, 30);
  int get freezeMax => _i('streak', 'freeze_max', 3, 0, 10);
  bool get repairNextDay => _b('streak', 'repair_next_day', true);

  // Plans
  /// While Gymco is in testing every Pro feature is on for everyone.
  bool get testingUnlockAll => _b('plans', 'testing_unlock_all', true);

  // App gate
  int minBuild(String platform) =>
      _i('app_gate', platform == 'android' ? 'min_build_android' : 'min_build_ios', 0, 0, 100000);
  int get recommendedBuild => _i('app_gate', 'recommended_build', 0, 0, 100000);
  bool get maintenance => _b('app_gate', 'maintenance_mode', false);

  static const _resting = {
    'en': 'Back shortly. Your diary is safe on your phone.',
    'ar': 'سنعود قريبًا. مذكراتك آمنة على هاتفك.',
    'es': 'Volvemos pronto. Tu diario está a salvo en tu teléfono.',
  };

  String maintenanceMessage(String lang) {
    final m = _v('app_gate', 'maintenance_message');
    String? pick(String l) => m is Map && m[l] is String && (m[l] as String).trim().isNotEmpty ? m[l] as String : null;
    return pick(lang) ?? pick('en') ?? _resting[lang] ?? _resting['en']!;
  }
}
