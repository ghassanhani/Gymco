// Iron, the coach, with the real fonts, in both looks:
//
//   SHOTS=1 flutter test test/shots/iron_shots_test.dart --update-goldens
//
// writes test/shots/out/iron-<look>-<screen>.png (git-ignored).
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

import '../fake_watch.dart';
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

Map<String, Object?> _item(String name, int sets, int lo, int hi, int rest) => {
  'exercise': name,
  'sets': sets,
  'rep_low': lo,
  'rep_high': hi,
  'rest_seconds': rest,
};

const _tip = {
  'title': 'Protein first at lunch',
  'tip': 'You are 120 g under on protein with two meals to go. Make lunch 40 g of it and you are back on track.',
  'action': 'log_food',
};

const _tips = {
  'tips': [
    _tip,
    {'title': 'Water before noon', 'tip': 'You are at 0 of 3,500 ml. Start with a glass now.', 'action': 'drink_water'},
    {'title': 'Lights out by eleven', 'tip': 'You slept 6 h 10 m. Seven hours helps you recover.', 'action': 'none'},
  ],
};

final _program = <String, Object?>{
  'summary': 'Your weight is down 0.6% a week, right on target. Keep the cut, and train four days so you hold muscle while it comes off.',
  'kcal': 2250,
  'protein': 180,
  'carbs': 220,
  'fat': 70,
  'why': 'About 450 kcal under what your trend says you burn, with protein at 2.2 g per kg.',
  'routines': [
    {
      'name': 'Upper A',
      'days': [0],
      'items': [
        _item('Barbell Bench Press - Medium Grip', 4, 5, 8, 150),
        _item('Bent Over Barbell Row', 4, 6, 8, 150),
        _item('Barbell Shoulder Press', 3, 6, 10, 120),
        _item('Wide-Grip Lat Pulldown', 3, 8, 12, 90),
      ],
    },
    {
      'name': 'Lower A',
      'days': [1],
      'items': [
        _item('Barbell Full Squat', 4, 5, 8, 180),
        _item('Romanian Deadlift', 3, 6, 10, 150),
        _item('Standing Calf Raises', 4, 10, 15, 60),
      ],
    },
  ],
  'habits': ['Protein in every meal, about 45 g', 'Walk 8,000 steps', 'Lights out by 11'],
};

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final look in ['dark', 'light']) {
    for (final screen in ['meet', 'tip', 'program']) {
      testWidgets('iron $look $screen', skip: !run, (tester) async {
        await pumpApp(
          tester,
          prefs: {
            'profile': savedProfile.replaceFirst('2026-09-20', '2026-09-01'),
            'appearance': look,
            'healthOn': true,
            'healthWatchReads': true,
            if (screen != 'meet') 'ironOn': true,
            if (screen != 'meet') 'ironTips': jsonEncode({..._tips, 'day': dayKey(testNow)}),
            if (screen != 'meet') 'ironTipsDone': jsonEncode({'day': dayKey(testNow), 'done': [1]}),
          },
          library: realLibrary(),
          health: FakeWatch(),
          cloud: FakeCloud(signedIn: 'me@example.com')
            ..ironTip = _tips
            ..ironProgram = _program,
          seed: (db) async {
            final oats = (await db.searchFoods('oats')).first;
            await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
          },
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        if (screen == 'program') {
          tester.view.physicalSize = const Size(1170, 4400);
          await tester.binding.setSurfaceSize(const Size(390, 4400 / 3));
        }
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (screen == 'program') {
          ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push('/iron');
          for (var i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await tester.tap(find.byTooltip('Build my program'));
        } else {
          await Scrollable.ensureVisible(tester.element(find.byType(IronCard)), alignment: 0.45);
        }
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(seconds: 1));
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/iron-$look-$screen.png'));
      });
    }
  }
}
