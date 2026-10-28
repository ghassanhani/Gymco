// The Measure view's body map with the real fonts:
//
//   SHOTS=1 flutter test test/shots/measure_shots_test.dart --update-goldens
//
// writes test/shots/out/measure-<look>-<lang>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/models.dart';

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

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final (look, lang) in [('light', 'en'), ('dark', 'en'), ('light', 'ar')]) {
    testWidgets('measure $look $lang', skip: !run, (tester) async {
      await pumpApp(
        tester,
        prefs: {'profile': savedProfile, 'appearance': look, 'lang': lang},
        seed: (db) async {
          await db.setMeasurement(dayKey(testNow.subtract(const Duration(days: 21))), 'waist', 88.5);
          await db.setMeasurement(dayKey(testNow), 'waist', 85.5);
          await db.setMeasurement(dayKey(testNow), 'neck', 38);
          await db.setMeasurement(dayKey(testNow), 'arm', 36.5);
          await db.setMeasurement(dayKey(testNow), 'chest', 102);
        },
      );
      tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(lang == 'ar' ? 'التقدّم' : 'Progress').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(lang == 'ar' ? 'القياسات' : 'Measure'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/measure-$look-$lang.png'));
    });
  }
}
