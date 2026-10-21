// The five phones in gymcoapp.com's hero, drawn from the app in both looks:
//
//   SHOTS=1 flutter test test/shots/landing_shots_test.dart --update-goldens
//
// writes test/shots/out/landing-<look>-<slot>.png; tool/landing_screens.py
// turns them into site/img/landing/screen-<slot>[-light].jpg.
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/data/training.dart';

import '../helpers.dart';

Future<void> _loadFonts() async {
  final fonts = {
    'Urbanist': ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold'],
    'InstrumentSerif': ['Italic'],
    'IBMPlexSansArabic': ['Regular', 'SemiBold', 'Bold'],
  };
  for (final MapEntry(key: family, value: faces) in fonts.entries) {
    final loader = FontLoader(family);
    for (final f in faces) {
      final bytes = File('assets/fonts/$family-$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

/// A lifter a week in: meals logged today and Upper A planned for today.
Future<void> _seed(LocalDb db) async {
  final day = dayKey(testNow);
  for (final (q, meal, g) in [
    ('oats', Meal.breakfast, 80.0),
    ('egg', Meal.breakfast, 120.0),
    ('rice', Meal.lunch, 220.0),
    ('chicken', Meal.lunch, 180.0),
  ]) {
    final f = (await db.searchFoods(q)).first;
    await db.addEntry(LogEntry.of(f, day: day, meal: meal, grams: g));
  }
  await db.saveRoutine(
    Routine(
      id: null,
      name: 'Upper A',
      weekday: testNow.weekday - 1,
      folder: RoutineFolder.plan,
      items: const [
        RoutineItem(exerciseId: 'Barbell_Bench_Press_-_Medium_Grip', sets: 4, repLow: 5, repHigh: 8, restSeconds: 180),
        RoutineItem(exerciseId: 'Bent_Over_Barbell_Row', sets: 4, repLow: 6, repHigh: 10, restSeconds: 150),
        RoutineItem(exerciseId: 'Standing_Military_Press', sets: 3, repLow: 6, repHigh: 8, restSeconds: 150),
        RoutineItem(exerciseId: 'Wide-Grip_Lat_Pulldown', sets: 3, repLow: 8, repHigh: 12),
        RoutineItem(exerciseId: 'Side_Lateral_Raise', sets: 3, repLow: 12, repHigh: 15, restSeconds: 60),
        RoutineItem(exerciseId: 'Triceps_Pushdown', sets: 3, repLow: 10, repHigh: 15, restSeconds: 60),
      ],
    ),
  );
}

Future<void> _settle(WidgetTester t, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _go(WidgetTester t, String path) async {
  ProviderScope.containerOf(t.element(find.byType(GymcoApp))).read(routerProvider).go(path);
  await _settle(t);
}

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_loadFonts);
  for (final look in ['light', 'dark']) {
    for (final slot in ['today', 'l1', 'l2', 'r1', 'r2']) {
      testWidgets('landing $look $slot', skip: !run, (tester) async {
        await pumpApp(
          tester,
          prefs: {'profile': savedProfile, 'appearance': look},
          seed: _seed,
          library: realLibrary(),
          cloud: FakeCloud(signedIn: 'ghassanhani0@gmail.com'),
        );
        // A phone's status bar and home bar, so nothing sits under them.
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        await _settle(tester);
        switch (slot) {
          case 'l1':
            await _go(tester, '/add/snack');
          case 'l2':
            await _go(tester, '/progress/award/s7');
          case 'r1':
            await _go(tester, '/train');
          case 'r2':
            await _go(tester, '/train');
            await tester.tap(find.text('Start all').first);
            await _settle(tester, 20);
        }
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(seconds: 2));
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/landing-$look-$slot.png'));
      });
    }
  }
}
