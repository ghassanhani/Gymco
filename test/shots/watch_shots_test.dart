// The watch features with the real fonts, in both looks:
//
//   SHOTS=1 flutter test test/shots/watch_shots_test.dart --update-goldens
//
// writes test/shots/out/watch-<look>-<screen>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/domain/session.dart';
import 'package:gymco/state/training_providers.dart';
import 'package:gymco/ui/today/recovery_card.dart';

import 'package:gymco/domain/recovery.dart';

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

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final look in ['dark', 'light']) {
    for (final screen in ['full', 'top', 'today', 'easy', 'ask', 'activity', 'summary', 'health', 'stale']) {
      testWidgets('watch $look $screen', skip: !run, (tester) async {
        await pumpApp(
          tester,
          prefs: {
            'profile': savedProfile.replaceFirst('2026-09-20', '2026-09-01'),
            'appearance': look,
            'healthOn': true,
            'healthWatchReads': screen != 'ask',
          },
          seed: switch (screen) {
            'full' => (db) async {
              await db.saveRoutineFixture('Push A', weekday: 5);
              final oats = (await db.searchFoods('oats')).first;
              await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
            },
            'top' || 'today' => (db) => db.saveRoutineFixture('Push A', weekday: 5),
            _ => null,
          },
          health: switch (screen) {
            'easy' => FakeWatch(lastNight: 318, restingToday: 63, hrvToday: 47),
            'stale' => _QuietZepp(),
            _ => FakeWatch(),
          },
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        // The whole of Today in one tall frame.
        if (screen == 'full') {
          tester.view.physicalSize = const Size(1170, 5250);
          await tester.binding.setSurfaceSize(const Size(390, 1750));
        }
        await _frames(tester);
        final ctx = tester.element(find.byType(Scaffold).first);
        switch (screen) {
          case 'today' || 'easy' || 'ask' || 'stale':
            await tester.drag(pageScroll, const Offset(0, -190));
          case 'activity':
            await tester.scrollUntilVisible(find.byType(ActivityTiles), 200, scrollable: pageScroll);
            await tester.drag(pageScroll, const Offset(0, -60));
          case 'summary':
            GoRouter.of(ctx).push(
              '/summary',
              extra: FinishedWorkout(
                session: WorkoutSession(
                  name: 'Push A',
                  startedAt: testNow.subtract(const Duration(minutes: 52)),
                  exercises: const [],
                ),
                endedAt: testNow,
                bests: const {},
              ),
            );
          case 'health':
            GoRouter.of(ctx).push('/health');
        }
        await _frames(tester);
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/watch-$look-$screen.png'));
      });
    }
  }
}

/// Zepp, last synced five hours ago.
class _QuietZepp extends FakeWatch {
  @override
  Future<List<Sample>> samples(Metric metric, DateTime from, DateTime to) async {
    final cut = testNow.subtract(const Duration(hours: 5));
    return [
      for (final s in await super.samples(metric, from, to))
        if (!s.to.isAfter(cut)) Sample(s.from, s.to, s.value, source: 'Zepp'),
    ];
  }
}
