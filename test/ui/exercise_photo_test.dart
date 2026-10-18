import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

// A one-pixel PNG.
final _png = MemoryImage(
  base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='),
);

// The Train tab keeps animating, so step time instead of settling.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the exercise picker shows photos that open large', (tester) async {
    final asked = <String>[];
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      exerciseImages: (url) {
        asked.add(url);
        return _png;
      },
    );
    await tester.tap(find.bySemanticsLabel('Train').first);
    await _settle(tester);
    await tester.tap(find.text('Build my own routine'));
    await _settle(tester);
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await _settle(tester);
    await tester.tap(find.text('Add exercise'));
    await _settle(tester);

    expect(asked, contains(endsWith('bench/0.jpg')));
    await tester.tap(find.bySemanticsLabel('Show photos of Barbell Bench Press'));
    await _settle(tester);
    // Large, on its own screen, both photos a swipe apart.
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsWidgets);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await _settle(tester);
    expect(asked, contains(endsWith('bench/1.jpg')));

    await tester.tap(find.bySemanticsLabel('Close'));
    await _settle(tester);
    expect(find.byType(InteractiveViewer), findsNothing);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    // The photo opened without picking the exercise.
    expect(find.text('Add 1 exercise'), findsNothing);
  });
}
