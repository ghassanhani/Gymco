// The voice note while it records, with the real fonts:
//
//   SHOTS=1 flutter test test/shots/voice_shots_test.dart --update-goldens
//
// writes test/shots/out/voice-<look>-<screen>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/voice.dart';

import '../helpers.dart';

Future<void> _fonts() async {
  for (final MapEntry(key: fam, value: faces) in {
    'Urbanist': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
    'InstrumentSerif': ['Italic'],
  }.entries) {
    final l = FontLoader(fam);
    for (final f in faces) {
      l.addFont(Future.value(ByteData.view(File('assets/fonts/$fam-$f.ttf').readAsBytesSync().buffer)));
    }
    await l.load();
  }
}

/// Talks like a person: loud and quiet in waves.
class _Talking implements Voice {
  @override
  Stream<double> get level => Stream.fromIterable([
    for (var i = 0; i < 40; i++) (0.5 + 0.45 * math.sin(i * 0.9) * math.cos(i * 0.37)).abs().clamp(0, 1).toDouble(),
  ]);
  @override
  Future<bool> start({required String languageCode}) async => true;
  @override
  Future<String> finish() async => '';
  @override
  Future<void> cancel() async {}
}

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final look in ['dark', 'light']) {
    for (final screen in ['iron', 'food']) {
      testWidgets('voice $look $screen', skip: !run, (tester) async {
        await pumpApp(
          tester,
          prefs: {'profile': savedProfile, 'appearance': look, 'ironOn': true},
          cloud: FakeCloud(signedIn: 'me@example.com'),
          voice: _Talking(),
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        await tester.pumpAndSettle();
        final router = ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider);
        router.push(screen == 'iron' ? '/iron' : '/add/lunch');
        await tester.pumpAndSettle();
        if (screen == 'iron') {
          await tester.tap(find.byTooltip('Say it'));
        } else {
          await tester.tap(find.text('Voice'));
          await tester.pumpAndSettle();
          await tester.tap(find.bySemanticsLabel('Dictate the meal'));
        }
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/voice-$look-$screen.png'));
      });
    }
  }
}
