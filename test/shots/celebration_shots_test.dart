// The celebrations with the real fonts, in both looks:
//
//   SHOTS=1 flutter test test/shots/celebration_shots_test.dart --update-goldens
//
// writes test/shots/out/celebrate-<look>-<state>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/state/providers.dart';

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

const _all = ['s7', 's14', 's30', 's66', 's90', 'back', 'f1', 'f100', 'fp', 't1', 't25', 'tpr', 'month'];

Future<void> _days(LocalDb db, int n) async {
  final oats = (await db.searchFoods('oats')).first;
  for (var d = 1; d <= n; d++) {
    for (final m in [Meal.breakfast, Meal.lunch, Meal.dinner]) {
      await db.addEntry(
        LogEntry.of(
          oats,
          day: dayKey(testNow.subtract(Duration(days: d))),
          meal: m,
          grams: 80,
        ),
      );
    }
  }
}

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_fonts);
  for (final look in ['dark', 'light']) {
    for (final state in ['progress', 'kept', 'award']) {
      testWidgets('celebrate $look $state', skip: !run, (tester) async {
        final before = state == 'award' ? 13 : 11;
        final (db, _) = await pumpApp(
          tester,
          prefs: {
            'profile': savedProfile.replaceFirst('2026-09-20', '2026-09-01'),
            'appearance': look,
            'awardsSeen': [
              for (final a in _all)
                if (state != 'award' || a != 's14') a,
            ],
          },
          celebrations: true,
          seed: (db) async {
            await _days(db, before);
            final oats = (await db.searchFoods('oats')).first;
            await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
            if (state != 'progress') {
              await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.lunch, grams: 80));
            }
          },
        );
        tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final c = ProviderScope.containerOf(tester.element(find.byType(GymcoApp)));
        final rice = (await db.searchFoods('rice')).first;
        await c
            .read(logActionsProvider)
            .add(
              LogEntry.of(rice, day: dayKey(testNow), meal: state == 'progress' ? Meal.lunch : Meal.dinner, grams: 200),
            );
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(milliseconds: 300));
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/celebrate-$look-$state.png'));
      });
    }
  }
}
