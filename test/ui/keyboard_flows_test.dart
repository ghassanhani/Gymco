import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('switching tabs with a field focused closes the keyboard', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.tap(find.bySemanticsLabel('Food').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('Continue on the body step closes the number pad', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('GET STARTED').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cut'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '30');
    await tester.enterText(find.byType(TextField).at(1), '180');
    await tester.enterText(find.byType(TextField).at(2), '80');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('tapping outside a field closes the keyboard', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: FakeCloud());
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in with email'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.tapAt(const Offset(200, 760));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
