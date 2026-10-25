// Today without a watch, with the real fonts:
//
//   SHOTS=1 flutter test test/shots/nodevice_shots_test.dart --update-goldens
//
// writes test/shots/out/nodevice-<case>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/health_sync.dart';
import 'package:gymco/domain/recovery.dart';
import 'package:gymco/ui/today/recovery_card.dart';

import '../helpers.dart';

/// A phone with a health store and no watch: it counts steps, nothing else.
class _PhoneOnly extends NoHealth {
  @override
  Future<bool> available() async => true;
  @override
  Future<bool> connect() async => true;
  @override
  Future<int?> stepsToday(DateTime now) async => 6230;
  @override
  Future<List<Sample>> samples(Metric metric, DateTime from, DateTime to) async => [
    if (metric == Metric.steps)
      for (var b = 1; b < 7; b++)
        Sample(to.subtract(Duration(days: b)), to.subtract(Duration(days: b)), 5000.0 + b * 400),
  ];
}

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

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  // never: health never connected. phone: connected, a phone and no watch.
  for (final c in ['never', 'phone']) {
    testWidgets('nodevice $c', skip: !run, (tester) async {
      await pumpApp(
        tester,
        prefs: {
          'profile': savedProfile.replaceFirst('2026-09-20', '2026-09-01'),
          'appearance': 'dark',
          if (c == 'phone') 'healthOn': true,
          if (c == 'phone') 'healthWatchReads': true,
        },
        seed: (db) => db.saveRoutineFixture('Push A', weekday: 5),
        health: c == 'phone' ? _PhoneOnly() : const NoHealth(),
      );
      tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      if (c == 'phone') {
        await tester.scrollUntilVisible(find.byType(ActivityTiles), 200, scrollable: pageScroll);
        await tester.drag(pageScroll, const Offset(0, 500));
        await tester.drag(pageScroll, const Offset(0, -560));
      }
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/nodevice-$c.png'));
    });
  }
}
