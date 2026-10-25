import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/health_sync.dart';
import 'package:gymco/data/models.dart';

import '../helpers.dart';

/// A health store with two scale readings and a step count.
class FakeHealth extends NoHealth {
  FakeHealth({this.allow = true});
  final bool allow;
  final water = <int>[];

  @override
  Future<bool> available() async => true;
  @override
  Future<bool> connect() async => allow;
  @override
  Future<List<(DateTime, double)>> weights(DateTime since) async => [
    (testNow.subtract(const Duration(days: 2)), 80.4),
    (testNow.subtract(const Duration(days: 1)), 80.1),
  ];
  @override
  Future<int?> stepsToday(DateTime now) async => 8410;
  @override
  Future<void> writeWater(int ml, DateTime at) async => water.add(ml);
}

void main() {
  testWidgets('connecting brings in weigh-ins and steps, and water goes back out', (tester) async {
    final health = FakeHealth();
    final (db, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile}, health: health);
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Health data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect Health Connect'));
    await tester.pumpAndSettle();
    expect(prefs.getBool('healthOn'), isTrue);
    expect(find.text('Connected'), findsWidgets);

    final days = {for (final (d, kg) in await db.weighIns()) d: kg};
    expect(days[dayKey(testNow.subtract(const Duration(days: 1)))], 80.1);

    await tester.tap(find.bySemanticsLabel('Back').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Today').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('8,410', findRichText: true),
      300,
      scrollable: pageScroll,
    );
    await tester.scrollUntilVisible(find.text('+250'), 300, scrollable: pageScroll);
    await tester.ensureVisible(find.text('+250'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('+250'));
    await tester.pumpAndSettle();
    expect(health.water, [250]);
  });

  testWidgets('a refused permission leaves it off and says so', (tester) async {
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile}, health: FakeHealth(allow: false));
    await tester.tap(find.bySemanticsLabel('Me').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Health data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Health data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect Health Connect'));
    await tester.pumpAndSettle();
    expect(find.text('Health Connect did not open'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(prefs.getBool('healthOn'), isNull);
  });
}
