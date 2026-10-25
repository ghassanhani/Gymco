import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/data/models.dart';
import 'package:gymco/domain/iron_rules.dart';
import 'package:gymco/domain/session.dart';

import '../helpers.dart';

final _profile = Profile.fromJson(jsonDecode(savedProfile) as Map<String, Object?>);
final _now = DateTime(2026, 9, 26, 10);
String _ago(int d) => dayKey(DateTime(2026, 9, 26 - d));

IronFacts _facts({
  Map<String, double> resting = const {},
  Map<String, double> sleep = const {},
  Map<String, ({double kcal, int meals})> kcal = const {},
  List<double> trend = const [],
  Map<String, ({PainArea area, bool sharp, String day})> pain = const {},
  HealthProfile? health,
  DateTime? now,
  double protein = 0,
}) => IronFacts(
  now: now ?? _now,
  profile: _profile,
  calorieFloor: 1700,
  restingByDay: resting,
  sleepByDay: sleep,
  dayKcal: kcal,
  trend: trend,
  pain: pain,
  health: health,
  proteinToday: protein,
);

Set<String> _red(List<IronSignal> s) => {
  for (final x in s)
    if (x.level == SignalLevel.red) x.id,
};

void main() {
  test('resting heart rate 10 over its usual three days running is a warning sign', () {
    final usual = {for (var d = 4; d <= 17; d++) _ago(d): 55.0};
    expect(_red(ironSignals(_facts(resting: {...usual, _ago(0): 67, _ago(1): 66, _ago(2): 68}))), {'rhr_high'});
    // Two days high is not three.
    expect(_red(ironSignals(_facts(resting: {...usual, _ago(0): 67, _ago(1): 66, _ago(2): 58}))), isEmpty);
  });

  test('losing over 1.5% a week for two weeks is a warning sign; 0.7% is not', () {
    List<double> trend(double perDay) => [for (var i = 0; i < 15; i++) 80 - perDay * i];
    expect(_red(ironSignals(_facts(trend: trend(0.2)))), {'fast_loss'});
    expect(_red(ironSignals(_facts(trend: trend(0.08)))), isEmpty);
  });

  test('eating far under the floor on logged days is a warning sign, a half-logged day is not', () {
    final low = (kcal: 1100.0, meals: 3);
    expect(_red(ironSignals(_facts(kcal: {_ago(1): low, _ago(2): low, _ago(3): low}))), {'under_eating'});
    final partial = (kcal: 600.0, meals: 1);
    expect(_red(ironSignals(_facts(kcal: {_ago(1): partial, _ago(2): partial, _ago(3): partial}))), isEmpty);
  });

  test('sharp pain this week, or one area hurting twice, is a warning sign', () {
    expect(_red(ironSignals(_facts(pain: {'bench': (area: PainArea.shoulder, sharp: true, day: _ago(2))}))), {
      'sharp_pain',
    });
    expect(
      _red(
        ironSignals(
          _facts(
            pain: {
              'squat': (area: PainArea.knee, sharp: false, day: _ago(3)),
              'lunge': (area: PainArea.knee, sharp: false, day: _ago(9)),
            },
          ),
        ),
      ),
      {'repeated_pain'},
    );
    // A dull ache a month ago is history.
    expect(_red(ironSignals(_facts(pain: {'bench': (area: PainArea.elbow, sharp: true, day: _ago(30))}))), isEmpty);
  });

  test('a yes on the PAR-Q+ needs a doctor\'s clearance until the user has it', () {
    final yes = HealthProfile(parq: [false, true, false, false, false, false, false]);
    expect(_red(ironSignals(_facts(health: yes))), {'needs_clearance'});
    expect(_red(ironSignals(_facts(health: yes.copyWith(cleared: true)))), isEmpty);
  });

  test('protein behind by the afternoon is something to say, not a warning', () {
    final s = ironSignals(_facts(now: DateTime(2026, 9, 26, 15), protein: 40));
    expect(s.map((x) => x.id), contains('protein_gap'));
    expect(_red(s), isEmpty);
  });

  test('a health profile survives a round trip', () {
    final h = HealthProfile(
      injuries: {'knee'},
      conditions: {'asthma'},
      medication: true,
      parq: List.filled(7, false),
      note: 'Old ACL repair',
    );
    final back = HealthProfile.fromJson(jsonDecode(jsonEncode(h.toJson())) as Map<String, Object?>);
    expect(back.injuries, {'knee'});
    expect(back.conditions, {'asthma'});
    expect((back.medication, back.answered, back.note), (true, true, 'Old ACL repair'));
  });
}
