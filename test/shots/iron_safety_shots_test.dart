// Iron 2.0: warning signs, settings, health profile and weekly review:
//
//   SHOTS=1 flutter test test/shots/iron_safety_shots_test.dart --update-goldens
//
// writes test/shots/out/iron2-<look>-<screen>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/ui/today/iron_card.dart';

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

const _tip = {'title': 'Protein first at lunch', 'tip': 'Make lunch 40 g of it.', 'action': 'log_food'};

const _review = {
  'headline': 'Four sessions, protein on target five of seven days, and the trend is down 0.5 kg.',
  'wins': ['Trained every planned day', 'Protein hit 180 g on five days', 'Logged every meal since Monday'],
  'slips': ['Water was under half on Saturday and Sunday', 'Two short nights before leg day'],
  'next': [
    'Add one set to rows and pulldowns',
    'Bottle on the desk: 500 ml before lunch',
    'Lights out by 11 on Sunday',
  ],
};

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final look in ['dark', 'light']) {
    for (final screen in ['warning', 'settings', 'health', 'review', 'ask', 'routine', 'food']) {
      testWidgets('iron2 $look $screen', skip: !run, (tester) async {
        await pumpApp(
          tester,
          prefs: {
            'profile': savedProfile.replaceFirst('2026-09-20', '2026-09-01'),
            'appearance': look,
            'ironOn': true,
            'ironShareFood': true,
            'ironTip': jsonEncode({..._tip, 'day': dayKey(testNow)}),
            'ironHealth': jsonEncode({
              'injuries': ['knee'],
              'conditions': ['asthma'],
              'parq': screen == 'warning' || screen == 'health'
                  ? [false, false, false, false, false, true, false]
                  : List.filled(7, false),
            }),
          },
          library: realLibrary(),
          cloud: FakeCloud(signedIn: 'me@example.com')
            ..ironTip = _tip
            ..ironReview = _review,
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        if (screen == 'health') {
          tester.view.physicalSize = const Size(1170, 6600);
          await tester.binding.setSurfaceSize(const Size(390, 2200));
        }
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (screen == 'warning') {
          await Scrollable.ensureVisible(tester.element(find.byType(IronCard)), alignment: 0.3);
        } else {
          final path = switch (screen) {
            'ask' => '/iron',
            'routine' => '/routine/ai',
            'food' => '/add/lunch',
            _ => '/iron/$screen',
          };
          ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push(path);
          if (screen == 'food') {
            for (var i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 100));
            }
            await tester.tap(find.text('Write'));
          }
        }
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(seconds: 1));
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/iron2-$look-$screen.png'));
      });
    }
  }
}
