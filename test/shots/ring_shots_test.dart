// The Today calorie ring, empty and with meals, in English and Arabic:
//
//   SHOTS=1 flutter test test/shots/ring_shots_test.dart --update-goldens
//
// writes test/shots/out/ring-<lang>-<state>.png (git-ignored).
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
    'IBMPlexSansArabic': ['Regular', 'SemiBold', 'Bold'],
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
  for (final lang in ['en', 'ar']) {
    for (final logged in [false, true]) {
      testWidgets('ring $lang $logged', skip: !run, (tester) async {
        await pumpApp(
          tester,
          prefs: {'profile': savedProfile, 'appearance': 'light', 'lang': lang},
          seed: logged
              ? (db) async {
                  final oats = (await db.searchFoods('oats')).first;
                  await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
                }
              : null,
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(GymcoApp),
          matchesGoldenFile('out/ring-$lang-${logged ? 'logged' : 'empty'}.png'),
        );
      });
    }
  }
}
