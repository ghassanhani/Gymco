// The Me tab's reminders, and one reminder's sheet, with the real fonts:
//
//   SHOTS=1 flutter test test/shots/reminders_shots_test.dart --update-goldens
//
// writes test/shots/out/reminders-<look>-<lang>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';

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
  for (final look in ['dark', 'light']) {
    testWidgets('reminders $look', skip: !run, (tester) async {
      await pumpApp(
        tester,
        prefs: {'profile': savedProfile, 'appearance': look, 'remindMeals': true, 'remindWater': true},
        reminders: FakeReminders(),
      );
      tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
      await tester.tap(find.bySemanticsLabel('Me').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Weigh-in'), 300, scrollable: pageScroll);
      await tester.drag(pageScroll, const Offset(0, 520));
      await tester.pumpAndSettle();
      await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/reminders-$look.png'));
    });
  }
}
