// Questions & answers with the real fonts:
//
//   SHOTS=1 flutter test test/shots/faq_shots_test.dart --update-goldens
//
// writes test/shots/out/faq-<look>-<lang>-<screen>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/ui/kit/kit.dart';
import 'package:gymco/ui/me/faq_screen.dart';

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
  for (final (look, lang, screen) in [('light', 'en', 'list'), ('dark', 'en', 'siri'), ('light', 'ar', 'list')]) {
    testWidgets('faq $look $lang $screen', skip: !run, (tester) async {
      await pumpApp(tester, prefs: {'profile': savedProfile, 'appearance': look, 'lang': lang});
      tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push('/faq');
      for (
        var i = 0;
        i < 20 && find.descendant(of: find.byType(FaqScreen), matching: find.byType(VList)).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
      }
      if (screen == 'siri') {
        await tester.enterText(find.byType(TextField), 'siri');
        FocusManager.instance.primaryFocus?.unfocus();
      } else {
        await tester.tap(find.text(lang == 'ar' ? 'هل أحتاج إلى حساب؟' : 'Do I need an account?'));
      }
      await tester.pumpAndSettle();
      await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/faq-$look-$lang-$screen.png'));
    });
  }
}
