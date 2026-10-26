import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gymco/app.dart';
import 'package:gymco/domain/recovery.dart';
import 'package:gymco/domain/session.dart';
import 'package:gymco/state/awards_providers.dart';
import 'package:gymco/state/training_providers.dart';
import 'package:gymco/ui/today/recovery_card.dart';

import '../fake_watch.dart';
import '../helpers.dart';

void main() {
  const on = {'profile': savedProfile, 'healthOn': true, 'healthWatchReads': true};

  testWidgets('Today shows last night against the usual, and the morning run', (tester) async {
    await pumpApp(tester, prefs: on, health: FakeWatch());
    await tester.scrollUntilVisible(find.byType(RecoveryCard), 300, scrollable: pageScroll);
    await tester.pumpAndSettle();
    expect(find.text('READY'), findsOneWidget);
    expect(find.textContaining('7h 22m', findRichText: true), findsOneWidget);
    expect(find.text('Push it today'), findsOneWidget);
    expect(find.text('Sleep and heart are both on your side. Go for a personal best.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Run · 34 min · Apple Watch'), 300, scrollable: pageScroll);
    expect(find.text('Active energy'), findsOneWidget);
    expect(find.textContaining('486', findRichText: true), findsOneWidget);
  });

  testWidgets('a short night and a tired heart say go easy', (tester) async {
    await pumpApp(tester, prefs: on, health: FakeWatch(lastNight: 300, restingToday: 63, hrvToday: 44));
    await tester.scrollUntilVisible(find.byType(RecoveryCard), 300, scrollable: pageScroll);
    await tester.pumpAndSettle();
    expect(find.text('GO EASY'), findsOneWidget);
    expect(find.textContaining('5h 0m', findRichText: true), findsOneWidget);
  });

  testWidgets('a watch workout keeps the streak day', (tester) async {
    await pumpApp(tester, prefs: on, health: FakeWatch());
    final c = ProviderScope.containerOf(tester.element(find.byType(GymcoApp)));
    expect((await c.read(streakProvider.future))!.trainedToday, isTrue);
  });

  testWidgets('without health, no watch day counts', (tester) async {
    await pumpApp(tester, prefs: {'profile': savedProfile}, health: FakeWatch());
    final c = ProviderScope.containerOf(tester.element(find.byType(GymcoApp)));
    expect((await c.read(streakProvider.future))!.trainedToday, isFalse);
  });

  testWidgets('someone connected before asks once for the watch reads', (tester) async {
    final watch = FakeWatch();
    final (_, prefs) = await pumpApp(tester, prefs: {'profile': savedProfile, 'healthOn': true}, health: watch);
    await tester.scrollUntilVisible(find.text('Bring in your watch'), 300, scrollable: pageScroll);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(watch.connects, 1);
    expect(prefs.getBool('healthWatchReads'), isTrue);
    expect(find.text('Bring in your watch'), findsNothing);
    expect(find.text('Push it today'), findsOneWidget);
  });

  testWidgets('the workout summary shows heart rate from the watch', (tester) async {
    await pumpApp(tester, prefs: on, health: FakeWatch());
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push(
      '/summary',
      extra: FinishedWorkout(
        session: WorkoutSession(
          name: 'Push A',
          startedAt: testNow.subtract(const Duration(minutes: 52)),
          exercises: const [],
        ),
        endedAt: testNow,
        bests: const {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Heart rate'), findsOneWidget);
    expect(find.text('AVERAGE'), findsOneWidget);
    expect(find.text('PEAK'), findsOneWidget);
  });

  testWidgets('the Health screen shows what each kind of data brought in, and what is missing', (tester) async {
    await pumpApp(tester, prefs: on, health: _SleepOnlyBand());
    ProviderScope.containerOf(tester.element(find.byType(GymcoApp))).read(routerProvider).push('/health');
    await tester.pumpAndSettle();
    final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;
    await tester.scrollUntilVisible(find.textContaining('readings from Zepp'), 200, scrollable: list);
    expect(find.textContaining('readings from Zepp'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Check again'), 200, scrollable: list);
    expect(find.text('Nothing yet'), findsWidgets);
  });
}

/// A band whose app only shares sleep.
class _SleepOnlyBand extends FakeWatch {
  @override
  Future<List<Sample>> samples(Metric metric, DateTime from, DateTime to) async => metric == Metric.sleep
      ? [for (final s in await super.samples(metric, from, to)) Sample(s.from, s.to, s.value, source: 'Zepp')]
      : const [];

  @override
  Future<List<WatchWorkout>> workouts(DateTime from, DateTime to) async => const [];
}
