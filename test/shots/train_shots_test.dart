// The Train tab and a routine, with a three-day plan, in both looks:
//
//   SHOTS=1 flutter test test/shots/train_shots_test.dart --update-goldens
//
// writes test/shots/out/train-<look>-<screen>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/training.dart';

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

RoutineItem _i(String id, int sets, int lo, int hi) =>
    RoutineItem(exerciseId: id, sets: sets, repLow: lo, repHigh: hi, restSeconds: 120);

/// Push, pull and legs on Monday, Wednesday and Friday, and one of my own.
Future<int> _plan(LocalDb db) async {
  final push = await db.saveRoutine(
    Routine(
      id: null,
      name: 'Push A',
      weekday: 0,
      folder: RoutineFolder.plan,
      items: [
        _i('Barbell_Bench_Press_-_Medium_Grip', 4, 5, 8),
        _i('Barbell_Incline_Bench_Press_-_Medium_Grip', 3, 8, 10),
        _i('Barbell_Shoulder_Press', 3, 6, 8),
        _i('Side_Lateral_Raise', 3, 12, 15),
        _i('Triceps_Pushdown', 3, 10, 12),
      ],
    ),
  );
  await db.saveRoutine(
    Routine(
      id: null,
      name: 'Pull A',
      weekday: 2,
      folder: RoutineFolder.plan,
      items: [
        _i('Pullups', 4, 6, 10),
        _i('Bent_Over_Barbell_Row', 3, 6, 8),
        _i('Seated_Cable_Rows', 3, 10, 12),
        _i('Barbell_Curl', 3, 8, 12),
      ],
    ),
  );
  await db.saveRoutine(
    Routine(
      id: null,
      name: 'Legs',
      weekday: 4,
      folder: RoutineFolder.plan,
      items: [
        _i('Barbell_Full_Squat', 4, 5, 8),
        _i('Leg_Press', 3, 10, 12),
        _i('Lying_Leg_Curls', 3, 10, 12),
        _i('Standing_Calf_Raises', 4, 12, 15),
      ],
    ),
  );
  await db.saveRoutine(
    Routine(
      id: null,
      name: 'Arms finisher',
      folder: RoutineFolder.mine,
      items: [_i('Barbell_Curl', 3, 10, 12), _i('Dips_-_Triceps_Version', 3, 8, 12)],
    ),
  );
  return push;
}

Map<String, Object?> _item(String name, int sets, int lo, int hi, int rest) => {
  'exercise': name,
  'sets': sets,
  'rep_low': lo,
  'rep_high': hi,
  'rest_seconds': rest,
};

/// What the routine builder might answer for "Upper and lower, 4 days, 60 min".
final _aiPlan = <String, Object?>{
  'summary': 'Four days a week: upper and lower twice each, heavy early in the week and lighter later.',
  'routines': [
    {
      'name': 'Upper A',
      'days': [0],
      'items': [
        _item('Barbell Bench Press - Medium Grip', 4, 5, 8, 150),
        _item('Bent Over Barbell Row', 4, 6, 8, 150),
        _item('Barbell Shoulder Press', 3, 6, 10, 120),
        _item('Wide-Grip Lat Pulldown', 3, 8, 12, 90),
        _item('Barbell Curl', 2, 10, 12, 60),
      ],
    },
    {
      'name': 'Lower A',
      'days': [1],
      'items': [
        _item('Barbell Full Squat', 4, 5, 8, 180),
        _item('Romanian Deadlift', 3, 6, 10, 150),
        _item('Leg Press', 3, 10, 12, 120),
        _item('Standing Calf Raises', 4, 10, 15, 60),
      ],
    },
    {
      'name': 'Upper B',
      'days': [3],
      'items': [
        _item('Barbell Incline Bench Press - Medium Grip', 3, 8, 10, 120),
        _item('Seated Cable Rows', 3, 10, 12, 90),
        _item('Side Lateral Raise', 3, 12, 15, 60),
        _item('Triceps Pushdown', 3, 10, 12, 60),
      ],
    },
    {
      'name': 'Lower B',
      'days': [4],
      'items': [
        _item('Barbell Deadlift', 3, 3, 5, 180),
        _item('Lying Leg Curls', 3, 10, 12, 90),
        _item('Barbell Lunge', 3, 8, 12, 90),
      ],
    },
  ],
};

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final look in ['dark', 'light']) {
    for (final screen in ['train', 'view', 'edit', 'ai', 'ai-result']) {
      testWidgets('train $look $screen', skip: !run, (tester) async {
        late int push;
        await pumpApp(
          tester,
          prefs: {'profile': savedProfile, 'appearance': look},
          library: realLibrary(),
          cloud: FakeCloud(signedIn: 'me@example.com', plan: _aiPlan),
          seed: (db) async => push = await _plan(db),
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        tester.view.physicalSize = const Size(1170, 4200);
        await tester.binding.setSurfaceSize(const Size(390, 1400));
        final router = ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider);
        router.go(switch (screen) {
          'train' => '/train',
          'view' => '/routine/$push/view',
          'edit' => '/routine/$push',
          _ => '/routine/ai',
        });
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (screen == 'ai-result') {
          await tester.tap(find.text('Upper and lower, 4 days, 60 min'));
          await tester.pump();
          await tester.tap(find.byTooltip('Build my routine'));
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
        await tester.pump(const Duration(seconds: 1));
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/train-$look-$screen.png'));
      });
    }
  }
}
