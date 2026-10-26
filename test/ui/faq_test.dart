import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/app.dart';
import 'package:gymco/ui/kit/kit.dart';
import 'package:gymco/ui/me/faq_screen.dart';

import '../helpers.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push('/faq');
    // The questions load from the app's files, which takes real time.
    for (
      var i = 0;
      i < 20 && find.descendant(of: find.byType(FaqScreen), matching: find.byType(VList)).evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('questions open to their answer, and search finds the Siri ones', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await tester.pumpAndSettle();
    await open(tester);
    expect(find.text('Do I need an account?'), findsOneWidget);
    expect(find.textContaining('Your diary, workouts'), findsNothing);
    await tester.tap(find.text('Do I need an account?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your diary, workouts'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'siri');
    await tester.pumpAndSettle();
    expect(find.text('What can I ask Siri?'), findsOneWidget);
    expect(find.text('Do I need an account?'), findsNothing);
    // A match shows its answer straight away.
    expect(find.textContaining('Log water in Gymco'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('Nothing matches that. Try other words, or message us.'), findsOneWidget);
    await tester.tap(find.text('Message us'));
    await tester.pumpAndSettle();
    expect(find.text('Help & support'), findsOneWidget);
  });

  testWidgets('the questions come in the app\'s language', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile, 'lang': 'es'});
    await tester.pumpAndSettle();
    await open(tester);
    expect(find.text('Preguntas y respuestas'), findsOneWidget);
    expect(find.text('Do I need an account?'), findsNothing);
    expect(find.text('¿Necesito una cuenta?'), findsOneWidget);
  });

  testWidgets('and in Arabic', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile, 'lang': 'ar'});
    await tester.pumpAndSettle();
    await open(tester);
    expect(find.text('هل أحتاج إلى حساب؟'), findsOneWidget);
  });
}
