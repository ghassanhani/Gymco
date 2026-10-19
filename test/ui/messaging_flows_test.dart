import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/state/messaging_providers.dart';
import 'package:gymco/ui/kit/kit.dart';

import '../helpers.dart';

ProviderContainer containerOf(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(GymcoApp)));

Future<void> go(WidgetTester t, String path) async {
  containerOf(t).read(routerProvider).go(path);
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls the screen's list until [what] is built and on screen.
Future<void> scrollTo(WidgetTester t, Finder what) async {
  final list = find.descendant(of: find.byType(Pad), matching: find.byType(Scrollable)).first;
  await t.scrollUntilVisible(what, 200, scrollable: list);
  await settle(t);
}

/// An app-config response carrying [announcements] and, when given, a release note.
Map<String, Object?> published({List<Map<String, Object?>> announcements = const [], Map<String, Object?>? whatsNew}) =>
    {
      'config_version': 4,
      'config': <String, Object?>{},
      'packs': <String, Object?>{},
      'announcements': announcements,
      'whats_new': whatsNew,
    };

/// A published announcement live from [from] to [to] (testNow is 26 Sep 2026, 13:00).
/// The server sends [id] as a number (announcements.id is a bigint).
Map<String, Object?> ann(
  Object id,
  String title, {
  required DateTime from,
  required DateTime to,
  Map<String, Object?>? cta,
}) => {
  'id': id,
  'title': t3(title, '$title بالعربية'),
  'body': t3('$title body'),
  'cta': cta,
  'starts_at': from.toUtc().toIso8601String(),
  'ends_at': to.toUtc().toIso8601String(),
  'targeting': <String, Object?>{},
  'status': 'published',
};

final live = ann(1, 'Welcome week', from: DateTime(2026, 9, 20), to: DateTime(2026, 10, 1));
final newer = ann(
  2,
  'New food packs',
  from: DateTime(2026, 9, 25),
  to: DateTime(2026, 10, 5),
  cta: {'label': t3('See them'), 'url': 'https://gymco.app/packs/'},
);

void main() {
  testWidgets('the newest live announcement shows on Today; dismissing it hides it for good', (tester) async {
    final cloud = FakeCloud()..config = published(announcements: [live, newer]);
    final (_, prefs) = await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('New food packs'));
    expect(find.text('New food packs body'), findsOneWidget);
    expect(find.text('See them'), findsOneWidget);
    expect(find.text('Welcome week'), findsNothing);

    await tester.tap(find.byTooltip('Dismiss'));
    await settle(tester);
    expect(find.text('New food packs'), findsNothing);
    // The next one down takes its place.
    expect(find.text('Welcome week'), findsOneWidget);
    expect(jsonDecode(prefs.getString('rc.dismissed_ann')!), ['2']);

    // A later launch with the same phone and the same config: still dismissed.
    await pumpApp(
      tester,
      cloud: cloud,
      prefs: {
        'profile': savedProfile,
        'rc.announcements': prefs.getString('rc.announcements')!,
        'rc.dismissed_ann': prefs.getString('rc.dismissed_ann')!,
      },
    );
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Welcome week'));
    expect(find.text('New food packs'), findsNothing);
    expect(containerOf(tester).read(liveAnnouncementProvider)?.id, '1');
  });

  testWidgets('an announcement that has ended or not yet started stays off Today', (tester) async {
    final cloud = FakeCloud()
      ..config = published(
        announcements: [
          ann('old', 'Summer plans', from: DateTime(2026, 8, 1), to: DateTime(2026, 9, 1)),
          ann('soon', 'Winter plans', from: DateTime(2026, 11, 1), to: DateTime(2026, 12, 1)),
        ],
      );
    await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    expect(find.text('Summer plans'), findsNothing);
    expect(find.text('Winter plans'), findsNothing);
    expect(containerOf(tester).read(liveAnnouncementProvider), isNull);
  });

  testWidgets('an announcement with a string id shows too', (tester) async {
    final cloud = FakeCloud()
      ..config = published(
        announcements: [ann('s1', 'Spring sale', from: DateTime(2026, 9, 20), to: DateTime(2026, 10, 1))],
      );
    await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(liveAnnouncementProvider)?.id, 's1');
  });

  testWidgets('in Arabic the announcement reads in Arabic', (tester) async {
    final cloud = FakeCloud()..config = published(announcements: [live]);
    await pumpApp(tester, cloud: cloud, locale: const Locale('ar'), prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Welcome week بالعربية'));
    expect(find.text('Welcome week'), findsNothing);
  });

  testWidgets('the help form sends a ticket with the device details; the switch asks for deletion', (tester) async {
    final cloud = FakeCloud(signedIn: 'pat@example.com')..config = published();
    await pumpApp(tester, cloud: cloud, appVersion: '1.0.2 (102)', prefs: {'profile': savedProfile});
    await go(tester, '/me');
    await scrollTo(tester, find.text('Help & support'));
    await tester.tap(find.text('Help & support'));
    await settle(tester);
    expect(find.text('Help on the website'), findsNothing);
    expect(find.widgetWithText(TextField, 'pat@example.com'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('help-subject')), 'Scan stuck');
    await tester.enterText(find.byKey(const Key('help-message')), 'The photo scan spins forever.');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await settle(tester);

    expect(cloud.supportTickets.single, {
      'email': 'pat@example.com',
      'subject': 'Scan stuck',
      'body': 'The photo scan spins forever.',
      'locale': 'en',
      'app_version': '1.0.2 (102)',
      'platform': 'android',
      'kind': 'general',
    });
    expect(find.text('Sent. We reply by email.'), findsOneWidget);
    // Back on Me, with the website link still there.
    await scrollTo(tester, find.text('Help on the website'));

    await tester.tap(find.text('Help & support'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('help-subject')), 'Please delete');
    await tester.enterText(find.byKey(const Key('help-message')), 'Delete everything, thanks.');
    await tester.tap(find.text('Delete my account and data'));
    await settle(tester);
    expect(find.textContaining('30 days'), findsOneWidget);
    await tester.pump();
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(cloud.supportTickets.last['kind'], 'deletion');
    expect(cloud.supportTickets.last['subject'], 'Please delete');
  });

  testWidgets('after five tickets in a day the form says to try tomorrow', (tester) async {
    final cloud = FakeCloud()
      ..config = published()
      ..tooMany = true;
    await pumpApp(tester, cloud: cloud, prefs: {'profile': savedProfile});
    await go(tester, '/help');
    await tester.enterText(find.byKey(const Key('help-email')), 'sam@example.com');
    await tester.enterText(find.byKey(const Key('help-subject')), 'Hi');
    await tester.enterText(find.byKey(const Key('help-message')), 'Again.');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(cloud.supportTickets, isEmpty);
    expect(find.text('Too many messages today. Try again tomorrow.'), findsOneWidget);
    // Still on the form.
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets("what's new shows once for its build", (tester) async {
    final cloud = FakeCloud()
      ..config = published(
        whatsNew: {'build': 102, 'version': '1.0.2', 'body': t3('Faster photo scans\nNew food packs')},
      );
    final (_, prefs) = await pumpApp(tester, cloud: cloud, appVersion: '1.0.2 (102)', prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    expect(find.text("What's new in 1.0.2"), findsOneWidget);
    expect(find.textContaining('Faster photo scans'), findsOneWidget);
    expect(find.textContaining('New food packs'), findsOneWidget);
    expect(prefs.getInt('rc.whats_new_shown'), 102);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text("What's new in 1.0.2"), findsNothing);

    await pumpApp(
      tester,
      cloud: cloud,
      appVersion: '1.0.2 (102)',
      prefs: {'profile': savedProfile, 'rc.whats_new_shown': 102},
    );
    await tester.pumpAndSettle();
    expect(find.text("What's new in 1.0.2"), findsNothing);
  });
}
