// The muscles an exercise works, on its screen, with the real fonts:
//
//   SHOTS=1 flutter test test/shots/muscle_shots_test.dart --update-goldens
//
// writes test/shots/out/muscles-<look>-<exercise>.png (git-ignored).
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final lib = realLibrary();
  for (final (look, id) in [
    ('light', 'Barbell_Bench_Press_-_Medium_Grip'),
    ('dark', 'Wide-Grip_Lat_Pulldown'),
    ('light', 'Barbell_Squat'),
  ]) {
    testWidgets('muscles $look $id', skip: !run, (tester) async {
      await pumpApp(tester, prefs: {'profile': savedProfile, 'appearance': look}, library: lib);
      tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push('/exercise/$id');
      for (
        var i = 0;
        i < 40 &&
            find.byKey(const Key('muscles-front')).evaluate().isEmpty &&
            find.byKey(const Key('muscles-side')).evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
      }
      final map = find.byKey(const Key('muscles-front')).evaluate().isEmpty
          ? const Key('muscles-side')
          : const Key('muscles-front');
      await tester.scrollUntilVisible(find.byKey(map), 200, scrollable: find.byType(Scrollable).last);
      await Scrollable.ensureVisible(tester.element(find.byKey(map)), alignment: 0.35);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
      }
      await expectLater(find.byType(GymcoApp), matchesGoldenFile('out/muscles-$look-$id.png'));
    });
  }
}
