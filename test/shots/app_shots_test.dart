// Screenshots of the main screens with the real fonts, for looking at a
// design change. Not part of the normal run:
//
//   SHOTS=1 flutter test test/shots --update-goldens
//
// writes test/shots/out/<look>-<screen>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/data/local_db.dart';
import 'package:gymco/data/models.dart';

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

Future<void> _seed(LocalDb db) async {
  final oats = (await db.searchFoods('oats')).first;
  final day = dayKey(testNow);
  await db.addEntry(LogEntry.of(oats, day: day, meal: Meal.breakfast, grams: 80));
  final rice = (await db.searchFoods('rice')).first;
  await db.addEntry(LogEntry.of(rice, day: day, meal: Meal.lunch, grams: 200));
}

Future<void> go(WidgetTester t, String path) async {
  ProviderScope.containerOf(t.element(find.byType(GymcoApp))).read(routerProvider).go(path);
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  setUpAll(_loadFonts);
  for (final look in ['light', 'dark']) {
    for (final (name, route) in [
      ('today', '/today'),
      ('food', '/food'),
      ('train', '/train'),
      ('progress', '/progress'),
      ('me', '/me'),
      ('awards', '/progress/awards'),
      ('account', '/account'),
      ('pro', '/pro'),
      ('workout', '/workout'),
      ('checkin', '/checkin'),
      ('onboarding', '/onboarding'),
      ('body', '/onboarding#body'),
    ]) {
      testWidgets('$look $name', skip: !run, (tester) async {
        await pumpApp(tester, prefs: {'profile': savedProfile, 'appearance': look}, seed: _seed);
        if (route != '/today') await go(tester, route.split('#').first);
        // The body step: pick a goal, then Continue.
        if (route.endsWith('#body')) {
          await tester.tap(find.text('Cut'));
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.text('Continue'));
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        // Let asset images decode before the picture is taken.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(seconds: 2));
        await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/$look-$name.png'));
      });
    }
  }
}
