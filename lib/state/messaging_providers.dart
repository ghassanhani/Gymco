import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

// Phone-only keys (never backed up): what app-config last served and what
// this phone has already seen.
const _announcementsKey = 'rc.announcements';
const _dismissedKey = 'rc.dismissed_ann';
const _whatsNewKey = 'rc.whats_new';
const _whatsNewShownKey = 'rc.whats_new_shown';

/// Picks the [lang] text out of a `{ en, ar, es }` map, falling back to
/// English; empty when there is none.
String pickLang(Object? t3, String lang) {
  if (t3 is! Map) return '';
  String? pick(String l) => t3[l] is String && (t3[l] as String).trim().isNotEmpty ? (t3[l] as String).trim() : null;
  return pick(lang) ?? pick('en') ?? '';
}

/// A call to action under an announcement: an https link.
class AnnouncementCta {
  const AnnouncementCta({required this.label, required this.url});
  final Map<String, Object?> label;
  final Uri url;

  String labelIn(String lang) => pickLang(label, lang);
}

/// One published announcement as `app-config` lists it.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.startsAt,
    required this.endsAt,
    this.cta,
    required this.raw,
  });

  final String id;
  final Map<String, Object?> title;
  final Map<String, Object?> body;
  final DateTime startsAt;
  final DateTime endsAt;
  final AnnouncementCta? cta;

  /// As served, for the cache.
  final Map<String, Object?> raw;

  String titleIn(String lang) => pickLang(title, lang);
  String bodyIn(String lang) => pickLang(body, lang);

  bool liveAt(DateTime now) => !now.isBefore(startsAt) && now.isBefore(endsAt);

  /// Null when the entry is not a usable announcement.
  static Announcement? fromJson(Object? j) {
    if (j is! Map) return null;
    final m = j.cast<String, Object?>();
    // The server's ids are numbers (a bigint column); accept a string too.
    final id = switch (m['id']) {
      final String s when s.isNotEmpty => s,
      final num n => n.toInt().toString(),
      _ => null,
    };
    final starts = m['starts_at'] is String ? DateTime.tryParse(m['starts_at'] as String) : null;
    final ends = m['ends_at'] is String ? DateTime.tryParse(m['ends_at'] as String) : null;
    if (id == null || starts == null || ends == null || m['title'] is! Map) return null;
    AnnouncementCta? cta;
    if (m['cta'] case {'label': final Map label, 'url': final String url}) {
      final u = Uri.tryParse(url);
      if (u != null && u.scheme == 'https') cta = AnnouncementCta(label: label.cast<String, Object?>(), url: u);
    }
    return Announcement(
      id: id,
      title: (m['title'] as Map).cast<String, Object?>(),
      body: m['body'] is Map ? (m['body'] as Map).cast<String, Object?>() : const {},
      startsAt: starts.toLocal(),
      endsAt: ends.toLocal(),
      cta: cta,
      raw: m,
    );
  }
}

/// The release note for the installed build, shown once.
class WhatsNew {
  const WhatsNew({required this.build, required this.version, required this.body});
  final int build;
  final String version;
  final Map<String, Object?> body;

  /// One bullet per line.
  List<String> bulletsIn(String lang) =>
      pickLang(body, lang).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Map<String, Object?> toJson() => {'build': build, 'version': version, 'body': body};

  static WhatsNew? fromJson(Object? j) => switch (j) {
    {'build': final num build, 'version': final String version, 'body': final Map body} => WhatsNew(
      build: build.toInt(),
      version: version,
      body: body.cast<String, Object?>(),
    ),
    _ => null,
  };
}

/// What the server has to say to this phone, and what the phone has
/// already dealt with.
class Messaging {
  const Messaging({this.announcements = const [], this.dismissed = const {}, this.whatsNew, this.whatsNewShown});

  final List<Announcement> announcements;
  final Set<String> dismissed;
  final WhatsNew? whatsNew;

  /// The build whose note was shown.
  final int? whatsNewShown;

  Messaging copyWith({
    List<Announcement>? announcements,
    Set<String>? dismissed,
    WhatsNew? Function()? whatsNew,
    int? whatsNewShown,
  }) => Messaging(
    announcements: announcements ?? this.announcements,
    dismissed: dismissed ?? this.dismissed,
    whatsNew: whatsNew == null ? this.whatsNew : whatsNew(),
    whatsNewShown: whatsNewShown ?? this.whatsNewShown,
  );

  /// The newest live announcement not yet dismissed: the one that started
  /// last, with the server's order breaking ties.
  Announcement? liveAt(DateTime now) {
    Announcement? best;
    for (final a in announcements) {
      if (dismissed.contains(a.id) || !a.liveAt(now)) continue;
      if (best == null || a.startsAt.isAfter(best.startsAt)) best = a;
    }
    return best;
  }

  /// The note to show now, or null when there is none or it was shown.
  WhatsNew? get pendingWhatsNew => whatsNew != null && whatsNew!.build != whatsNewShown ? whatsNew : null;
}

/// Announcements and the release note: what the last config fetch cached,
/// at once on launch; updated with every fetch.
class MessagingNotifier extends Notifier<Messaging> {
  @override
  Messaging build() {
    final prefs = ref.watch(prefsProvider);
    var m = const Messaging();
    try {
      final raw = prefs.getString(_announcementsKey);
      if (raw != null) m = m.copyWith(announcements: _parse(jsonDecode(raw)));
      final dismissed = prefs.getString(_dismissedKey);
      if (dismissed != null) {
        m = m.copyWith(dismissed: (jsonDecode(dismissed) as List).whereType<String>().toSet());
      }
      final wn = prefs.getString(_whatsNewKey);
      if (wn != null) m = m.copyWith(whatsNew: () => WhatsNew.fromJson(jsonDecode(wn)));
    } catch (_) {
      // A damaged cache is the same as none.
    }
    return m.copyWith(whatsNewShown: prefs.getInt(_whatsNewShownKey));
  }

  static List<Announcement> _parse(Object? list) => [
    if (list is List)
      for (final e in list) ?Announcement.fromJson(e),
  ];

  /// Keeps what an app-config response carried: its `announcements` and
  /// `whats_new`.
  Future<void> store(Map<String, Object?> data) async {
    final prefs = ref.read(prefsProvider);
    var next = state;
    if (data['announcements'] case final List list) {
      final anns = _parse(list);
      await prefs.setString(_announcementsKey, jsonEncode([for (final a in anns) a.raw]));
      // Ids that are gone need no remembering.
      final ids = {for (final a in anns) a.id};
      final kept = next.dismissed.where(ids.contains).toSet();
      if (kept.length != next.dismissed.length) await prefs.setString(_dismissedKey, jsonEncode(kept.toList()));
      next = next.copyWith(announcements: anns, dismissed: kept);
    }
    final wn = WhatsNew.fromJson(data['whats_new']);
    if (wn == null) {
      await prefs.remove(_whatsNewKey);
    } else {
      await prefs.setString(_whatsNewKey, jsonEncode(wn.toJson()));
    }
    next = next.copyWith(whatsNew: () => wn);
    state = next;
  }

  Future<void> dismiss(String id) async {
    final dismissed = {...state.dismissed, id};
    state = state.copyWith(dismissed: dismissed);
    await ref.read(prefsProvider).setString(_dismissedKey, jsonEncode(dismissed.toList()));
  }

  /// Records that the note for [build] was shown, before it is.
  void markWhatsNewShown(int build) {
    state = state.copyWith(whatsNewShown: build);
    unawaited(ref.read(prefsProvider).setInt(_whatsNewShownKey, build));
  }
}

final messagingProvider = NotifierProvider<MessagingNotifier, Messaging>(MessagingNotifier.new);

/// The announcement Today shows, if any.
final liveAnnouncementProvider = Provider<Announcement?>(
  (ref) => ref.watch(messagingProvider).liveAt(ref.watch(clockProvider)()),
);

/// The release note to show once, if any.
final pendingWhatsNewProvider = Provider<WhatsNew?>((ref) => ref.watch(messagingProvider).pendingWhatsNew);
