import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/cloud.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/state/cloud_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

Future<void> _openAccount(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Me').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Account'));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, {String code = '123456'}) async {
  await tester.enterText(find.byType(TextField), 'sam@example.com');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Send sign-in link'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), code);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

Future<void> _openPhoto(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Food').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Photo'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a build without a project says the phone is enough', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile});
    await _openAccount(tester);
    expect(find.textContaining('not switched on in this build'), findsOneWidget);
  });

  testWidgets('signing in with an empty account backs this phone up', (tester) async {
    final cloud = FakeCloud();
    await pumpApp(
      tester,
      prefs: {'profile': savedProfile},
      cloud: cloud,
      seed: (db) async {
        final oats = (await db.searchFoods('oats')).first;
        await db.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
      },
    );
    await _openAccount(tester);
    await _signIn(tester);
    expect(find.text('sam@example.com'), findsOneWidget);
    expect(cloud.uploads, 1);
    final db = cloud.backup!.payload['db']! as Map;
    expect((db['log_entries']! as List).single['grams'], 80);
    expect(((cloud.backup!.payload['prefs']! as Map)['profile']! as String), contains('"kcal":2319.0'));
  });

  testWidgets('the email link signs in too, and backs up once', (tester) async {
    final cloud = FakeCloud();
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openAccount(tester);
    await tester.enterText(find.byType(TextField), 'sam@example.com');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send sign-in link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Open it on this phone'), findsOneWidget);

    cloud.openLink('sam@example.com');
    await tester.pumpAndSettle();
    expect(find.text('sam@example.com'), findsOneWidget);
    expect(cloud.uploads, 1);
  });

  testWidgets('a wrong code says so and stays signed out', (tester) async {
    final cloud = FakeCloud();
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openAccount(tester);
    await _signIn(tester, code: '000000');
    expect(find.textContaining('That code did not work'), findsOneWidget);
    expect(cloud.signedIn, isNull);
  });

  testWidgets('a new phone restores the backup it finds', (tester) async {
    // What another phone backed up.
    final other = await openTestDb();
    final oats = (await other.searchFoods('oats')).first;
    await other.addEntry(LogEntry.of(oats, day: dayKey(testNow), meal: Meal.breakfast, grams: 80));
    await other.setWeight('2026-09-25', 79.4);
    await other.setFavourite(oats.id, true);
    SharedPreferences.setMockInitialValues({'profile': savedProfile, 'streakGoal': 30});
    final otherPrefs = await SharedPreferences.getInstance();
    final payload = jsonDecode(jsonEncode(await backupPayload(other, otherPrefs))) as Map<String, Object?>;
    await other.close();

    final cloud = FakeCloud(
      backup: CloudBackup(payload: payload, at: testNow),
    );
    final (db, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openAccount(tester);
    await _signIn(tester);
    expect(find.text('A backup is in your account'), findsOneWidget);
    await tester.tap(find.text('Restore it'));
    await tester.pumpAndSettle();

    expect((await db.entriesFor(dayKey(testNow))).single.grams, 80);
    expect((await db.weighIns()).map((w) => w.$2), contains(79.4));
    expect(await db.favouriteIds(), [oats.id]);
    expect(prefs.getInt('streakGoal'), 30);
    expect(cloud.uploads, 0);
  });

  testWidgets('keeping this phone backs it up over the old backup', (tester) async {
    final cloud = FakeCloud(
      backup: CloudBackup(payload: const {'db': {}, 'prefs': {}}, at: testNow),
    );
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openAccount(tester);
    await _signIn(tester);
    await tester.tap(find.text('Keep this phone’s data'));
    await tester.pumpAndSettle();
    expect(cloud.uploads, 1);
    expect((cloud.backup!.payload['prefs']! as Map)['profile'], savedProfile);
  });

  testWidgets('photo logging asks for an account first', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: FakeCloud());
    await _openPhoto(tester);
    expect(find.textContaining('Photo logging uses an account'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Back up to an account'), findsOneWidget);
  });

  testWidgets('a photo suggests foods; tapping one opens it to set the amount', (tester) async {
    final cloud = FakeCloud(
      signedIn: 'sam@example.com',
      photoFoods: const [
        PhotoFood(name: 'Chicken breast', local: 'Chicken breast', sure: true),
        PhotoFood(name: 'Quinoa, cooked', local: 'Quinoa', sure: false),
      ],
    );
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openPhoto(tester);
    await tester.tap(find.bySemanticsLabel('Take a photo'));
    await tester.pumpAndSettle();

    expect(find.text('2 THINGS ON THE PLATE'), findsOneWidget);
    expect(find.text('fairly confident'), findsOneWidget);
    expect(find.text('not sure — check this one'), findsOneWidget);
    expect(find.textContaining('A photo cannot tell how much'), findsOneWidget);
    expect(find.text('8 photo scans left today'), findsOneWidget);

    await tester.tap(find.text('Chicken breast'));
    await tester.pumpAndSettle();
    expect(find.text('Chicken breast, raw'), findsWidgets);
  });

  testWidgets('a food the phone lacks goes to search', (tester) async {
    final cloud = FakeCloud(
      signedIn: 'sam@example.com',
      photoFoods: const [PhotoFood(name: 'Quinoa, cooked', local: 'Quinoa', sure: true)],
    );
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openPhoto(tester);
    await tester.tap(find.bySemanticsLabel('Take a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quinoa'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Quinoa, cooked'), findsOneWidget);
  });

  testWidgets('the daily cap is explained', (tester) async {
    final cloud = FakeCloud(signedIn: 'sam@example.com', scansLeft: 0);
    await pumpApp(tester, prefs: {'profile': savedProfile}, cloud: cloud);
    await _openPhoto(tester);
    await tester.tap(find.bySemanticsLabel('Take a photo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('today’s 10 photo scans'), findsOneWidget);
    expect(find.text('No photo scans left today'), findsOneWidget);
  });
}
