// Iron's choices, the home card and the feature request, with real fonts:
//
//   SHOTS=1 flutter test test/shots/options_shots_test.dart --update-goldens
//
// writes test/shots/out/options-<look>-<screen>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/ui/today/iron_card.dart';
import 'package:flutter/widgets.dart';

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

const _tips = {
  'tips': [
    {'title': 'Protein first at lunch', 'tip': 'You are 120 g under on protein. Make lunch 40 g of it.', 'action': 'log_food'},
    {'title': 'Water before noon', 'tip': 'You are at 0 of 3,500 ml. Start with a glass now.', 'action': 'drink_water'},
    {'title': 'Lights out by eleven', 'tip': 'You slept 6 h 10 m. Seven hours helps you recover.', 'action': 'none'},
  ],
};

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final look in ['light', 'dark']) {
    for (final screen in ['iron', 'home', 'feature']) {
      testWidgets('options $look $screen', skip: !run, (tester) async {
        await pumpApp(
          tester,
          prefs: {
            'profile': savedProfile,
            'appearance': look,
            'ironOn': true,
            'ironTips': jsonEncode({..._tips, 'day': dayKey(testNow)}),
          },
          cloud: FakeCloud(signedIn: 'me@example.com'),
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        await tester.pumpAndSettle();
        final router = ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider);
        if (screen == 'iron') {
          router.push('/iron');
          await tester.pumpAndSettle();
          await tester.tap(find.text('4'));
          await tester.tap(find.text('Gym'));
          await tester.tap(find.text('Build muscle'));
        } else if (screen == 'feature') {
          router.push('/feature');
        } else {
          await tester.scrollUntilVisible(find.byType(IronCard), 300, scrollable: pageScroll);
          await tester.pumpAndSettle();
          await Scrollable.ensureVisible(tester.element(find.byType(IronCard)), alignment: 0.3);
        }
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/options-$look-$screen.png'));
      });
    }
  }
}
