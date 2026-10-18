import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/photo_store.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/domain/streak.dart';

import '../helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('a progress photo is taken, stays local, and compares with an older one', (tester) async {
    final store = MemoryPhotoStore();
    await store.save(
      dayKey(testNow.subtract(const Duration(days: 21))),
      Pose.front,
      (await FakePicker().pick(camera: true))!,
    );
    await pumpApp(tester, prefs: {'profile': savedProfile}, photos: store);
    await tester.tap(find.bySemanticsLabel('Progress').first);
    await settle(tester);
    await tester.ensureVisible(find.text('Photos'));
    await settle(tester);
    await tester.tap(find.text('Photos'));
    await settle(tester);
    expect(find.text('Take the same pose on another day to compare.'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Add Front photo')));
    await settle(tester);
    await tester.tap(find.text('Take a photo'));
    await settle(tester);
    expect((await store.list()).where((p) => p.day == dayKey(testNow)), hasLength(1));
    expect(find.text('COMPARE'), findsOneWidget);
    expect(find.text('Latest · 26 Sep'), findsOneWidget);
  });

  test('paused days hold the streak without spending a freeze', () {
    final start = DateTime(2026, 9, 1);
    final s = computeStreak(
      start: start,
      now: DateTime(2026, 9, 12, 12),
      history: [
        for (var i = 0; i < 7; i++) StreakDay(date: DateTime(2026, 9, 1 + i), mealsLogged: true, plannedRest: true),
        for (var i = 7; i < 10; i++) StreakDay(date: DateTime(2026, 9, 1 + i), paused: true),
      ],
    );
    expect(s.current, 7);
    expect(s.freezes, 1);
  });
}
