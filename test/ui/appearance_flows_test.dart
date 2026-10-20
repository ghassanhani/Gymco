import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/theme/volt.dart';

import '../helpers.dart';

Color _screenColor(WidgetTester tester) =>
    tester.widgetList<Material>(find.byType(Material)).firstWhere((m) => m.color != null).color!;

void main() {
  testWidgets('the app opens dark, and Appearance switches it to light and remembers', (tester) async {
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile});
    expect(Volt.isLight, isFalse);
    expect(_screenColor(tester), VoltPalette.dark.bg);

    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(Volt.isLight, isTrue);
    expect(_screenColor(tester), VoltPalette.light.bg);
    expect(prefs.getString('appearance'), 'light');
    // Still on Me after the whole app redraws.
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('a saved light choice opens light', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile, 'appearance': 'light'});
    expect(Volt.isLight, isTrue);
    expect(_screenColor(tester), VoltPalette.light.bg);
  });

  tearDown(() => Volt.use(Brightness.dark));
}
