// Frames of the splash hand-over, for looking at it:
//   SHOTS=1 flutter test test/shots/splash_shots_test.dart --update-goldens
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/ui/common/splash.dart';

void main() {
  testWidgets('splash frames', skip: Platform.environment['SHOTS'] != '1', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(color: Colors.white, child: SplashCover()),
      ),
    );
    await tester.runAsync(
      () => precacheImage(const AssetImage('assets/brand/logo-mask.png'), tester.binding.rootElement!),
    );
    await tester.pump();
    for (final ms in [0, 400, 560, 680]) {
      if (ms > 0) await tester.pump(Duration(milliseconds: ms == 400 ? 400 : (ms == 560 ? 160 : 120)));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('out/splash-$ms.png'));
    }
    await tester.pumpAndSettle();
  });
}
