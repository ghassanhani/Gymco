// Iron's moods frame by frame, for a look at the motion:
//
//   SHOTS=1 flutter test test/shots/iron_avatar_shots_test.dart --update-goldens
//
// writes test/shots/out/iron-<mood>-<frame>.png (git-ignored); join them
// into a GIF to watch.
@Tags(['shots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/ui/common/iron_avatar.dart';

void main() {
  final run = Platform.environment['SHOTS'] == '1';
  for (final mood in IronMood.values) {
    testWidgets('iron avatar ${mood.name}', skip: !run, (tester) async {
      tester.view.physicalSize = const Size(300, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (var f = 0; f < 40; f++) {
        final ms = f * 80;
        await tester.pumpWidget(
          ColoredBox(
            color: const Color(0xFF17161B),
            child: Center(child: IronFrame(ironPose(mood, ms, ms), size: 200)),
          ),
        );
        await expectLater(
          find.byType(ColoredBox),
          matchesGoldenFile('out/iron-${mood.name}-${f.toString().padLeft(2, '0')}.png'),
        );
      }
    });
  }
}
