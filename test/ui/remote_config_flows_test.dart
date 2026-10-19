import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/remote_config.dart';

import '../helpers.dart';

Map<String, Object?> published(Map<String, Object?> config, {int version = 4}) => {
  'config_version': version,
  'config': config,
  'packs': <String, Object?>{},
  'announcements': <Object?>[],
};

void main() {
  testWidgets('on launch the phone fetches its config with its platform, language, build and slot', (tester) async {
    final cloud = FakeCloud()
      ..config = published({
        'water': {'ml_per_kg': 33},
      });
    final (_, prefs) = await pumpApp(tester, cloud: cloud, appVersion: '1.0.2 (102)', prefs: {'rc.bucket': 42});
    await tester.pumpAndSettle();
    expect(cloud.lastDevice, {'platform': 'android', 'locale': 'en', 'build': '102', 'bucket': '42'});
    expect(RemoteConfig.current.waterMlPerKg, 33);
    expect(jsonDecode(prefs.getString('rc.config')!), containsPair('water', {'ml_per_kg': 33}));
  });

  testWidgets('the last config is used at once, before any fetch', (tester) async {
    await pumpApp(
      tester,
      prefs: {
        'rc.config': jsonEncode({
          'streak': {'freeze_max': 5},
        }),
      },
    );
    expect(RemoteConfig.current.freezeMax, 5);
  });

  testWidgets('maintenance shows the resting screen with the published message', (tester) async {
    final cloud = FakeCloud()
      ..config = published({
        'app_gate': {
          'maintenance_mode': true,
          'maintenance_message': {'en': 'Upgrading the servers.', 'ar': 'نحدّث', 'es': 'Actualizando'},
        },
      });
    await pumpApp(tester, cloud: cloud);
    await tester.pumpAndSettle();
    expect(find.text('Gymco is resting'), findsOneWidget);
    expect(find.text('Upgrading the servers.'), findsOneWidget);
  });

  testWidgets('a build below the minimum is blocked until it updates', (tester) async {
    final cloud = FakeCloud()
      ..config = published({
        'app_gate': {'min_build_android': 103},
      });
    await pumpApp(tester, cloud: cloud, appVersion: '1.0.2 (102)');
    await tester.pumpAndSettle();
    expect(find.text('Time to update Gymco'), findsOneWidget);
  });

  testWidgets('a build below the recommended one gets a nudge that can wait', (tester) async {
    final cloud = FakeCloud()
      ..config = published({
        'app_gate': {'recommended_build': 104},
      });
    await pumpApp(tester, cloud: cloud, appVersion: '1.0.2 (102)');
    await tester.pumpAndSettle();
    expect(find.text('A newer Gymco is ready.'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('A newer Gymco is ready.'), findsNothing);
  });

  testWidgets('offline, the phone keeps what it has', (tester) async {
    await pumpApp(
      tester,
      appVersion: '1.0.2 (102)',
      prefs: {
        'rc.config': jsonEncode({
          'limits': {'photo_note_max_chars': 99},
        }),
      },
    );
    await tester.pumpAndSettle();
    expect(RemoteConfig.current.photoNoteMaxChars, 99);
  });
}
