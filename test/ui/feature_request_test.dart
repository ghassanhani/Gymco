import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';

import '../helpers.dart';

void main() {
  testWidgets('an idea goes to the team as a feature request', (tester) async {
    final cloud = FakeCloud(signedIn: 'me@example.com');
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push('/feature');
    await tester.pumpAndSettle();
    expect(find.text('Request a feature'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('feature-idea')), 'A dark widget for the lock screen\nWith water left');
    await tester.pump();
    await tester.tap(find.text('Send request'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final t = cloud.supportTickets.single;
    expect(t['kind'], 'feature');
    expect(t['email'], 'me@example.com');
    expect(t['subject'], 'A dark widget for the lock screen');
    expect(find.text('Thanks! Your idea is with the team.'), findsOneWidget);
  });
}
