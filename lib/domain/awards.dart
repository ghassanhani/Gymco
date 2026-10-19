/// Awards: earned by logging and showing up. None is for eating less or
/// losing weight.
library;

import 'streak.dart';

enum AwardGroup { streak, food, training, challenge }

enum MedalShape { hex, circle, shield }

enum MedalTone { lime, gold, green, orange, blue }

class Award {
  const Award({
    required this.id,
    required this.group,
    required this.shape,
    required this.tone,
    required this.need,
    required this.have,
    this.big,
    this.small,
    this.icon,
    this.earnedOn,
    this.names,
    this.descriptions,
  });

  final String id;
  final AwardGroup group;
  final MedalShape shape;
  final MedalTone tone;
  final int need;
  final int have;

  /// The number on the medal ("30"), its unit ("DAYS"), or an icon instead.
  final String? big;
  final String? small;
  final String? icon;
  final DateTime? earnedOn;

  /// Its name and description by language code, for awards and challenges
  /// from a content pack; null for the built-in ones, which are localised.
  final Map<String, String>? names;
  final Map<String, String>? descriptions;

  /// The same award with [have] and [earnedOn] changed.
  Award copyWith({int? have, DateTime? earnedOn}) => Award(
    id: id,
    group: group,
    shape: shape,
    tone: tone,
    need: need,
    have: have ?? this.have,
    big: big,
    small: small,
    icon: icon,
    earnedOn: earnedOn ?? this.earnedOn,
    names: names,
    descriptions: descriptions,
  );

  bool get earned => have >= need;
  int get toGo => (need - have).clamp(0, need);
}

/// What the awards are counted from.
class AwardStats {
  const AwardStats({
    required this.streak,
    required this.fullDays,
    required this.mealsLogged,
    required this.bestProteinWeek,
    required this.workouts,
    required this.prs,
    required this.workoutsThisMonth,
    this.firstWorkout,
  });

  final StreakState streak;

  /// Days with breakfast, lunch and dinner logged, oldest first.
  final List<DateTime> fullDays;
  final int mealsLogged;

  /// Most days in one Monday-to-Sunday week with the protein target hit.
  final int bestProteinWeek;
  final int workouts;
  final DateTime? firstWorkout;
  final int prs;
  final int workoutsThisMonth;
}

const streakMilestones = [7, 14, 30, 66, 90];

/// The month's challenge target when no content pack sets one.
const monthlyChallenge = 12;

/// What an award from a content pack counts.
enum AwardMetric {
  /// Full days logged.
  loggedDays,

  /// Workouts finished.
  workouts,

  /// The best streak.
  streakDays,
}

/// An award from a content pack: earned when [metric] reaches [threshold].
/// Like every award, it rewards showing up.
class ExtraAward {
  const ExtraAward({
    required this.id,
    required this.metric,
    required this.threshold,
    required this.names,
    required this.descriptions,
  });
  final String id;
  final AwardMetric metric;
  final int threshold;
  final Map<String, String> names;
  final Map<String, String> descriptions;
}

/// When each run length was first reached, walking the marks in order.
/// Frozen and repairable days hold a run; a missed day ends it.
Map<int, DateTime> milestoneDates(Map<DateTime, DayMark> marks, [List<int> milestones = streakMilestones]) {
  final out = <int, DateTime>{};
  var run = 0;
  for (final d in marks.keys.toList()..sort()) {
    switch (marks[d]!) {
      case DayMark.kept:
        run++;
        for (final m in milestones) {
          if (run == m) out.putIfAbsent(m, () => d);
        }
      case DayMark.missed:
        run = 0;
      case DayMark.frozen || DayMark.repairable || DayMark.today || DayMark.open:
        break;
    }
  }
  return out;
}

/// A kept day after a missed one: the run that started over.
DateTime? comebackDate(Map<DateTime, DayMark> marks) {
  var missed = false;
  for (final d in marks.keys.toList()..sort()) {
    if (marks[d] == DayMark.missed) missed = true;
    if (missed && marks[d] == DayMark.kept) return d;
  }
  return null;
}

/// The built-in awards, then [extra] from a content pack. The month's
/// challenge needs [monthTarget] workouts and is called [monthTitle] when a
/// pack names it.
List<Award> awards(
  AwardStats s, {
  List<ExtraAward> extra = const [],
  int monthTarget = monthlyChallenge,
  Map<String, String>? monthTitle,
}) {
  final dates = milestoneDates(s.streak.marks);
  final best = s.streak.best;
  return [
    for (final n in streakMilestones)
      Award(
        id: 's$n',
        group: AwardGroup.streak,
        shape: MedalShape.hex,
        tone: n == 90 ? MedalTone.gold : MedalTone.lime,
        big: '$n',
        small: 'DAYS',
        need: n,
        have: best,
        earnedOn: dates[n],
      ),
    () {
      final back = comebackDate(s.streak.marks);
      return Award(
        id: 'back',
        group: AwardGroup.streak,
        shape: MedalShape.hex,
        tone: MedalTone.blue,
        icon: 'repeat',
        need: 1,
        have: back == null ? 0 : 1,
        earnedOn: back,
      );
    }(),
    Award(
      id: 'f1',
      group: AwardGroup.food,
      shape: MedalShape.circle,
      tone: MedalTone.green,
      icon: 'food',
      need: 1,
      have: s.fullDays.isEmpty ? 0 : 1,
      earnedOn: s.fullDays.firstOrNull,
    ),
    Award(
      id: 'f100',
      group: AwardGroup.food,
      shape: MedalShape.circle,
      tone: MedalTone.green,
      big: '100',
      small: 'MEALS',
      need: 100,
      have: s.mealsLogged,
    ),
    Award(
      id: 'fp',
      group: AwardGroup.food,
      shape: MedalShape.circle,
      tone: MedalTone.green,
      big: '7',
      small: 'PROTEIN',
      need: 7,
      have: s.bestProteinWeek,
    ),
    Award(
      id: 't1',
      group: AwardGroup.training,
      shape: MedalShape.circle,
      tone: MedalTone.orange,
      icon: 'dumb',
      need: 1,
      have: s.workouts > 0 ? 1 : 0,
      earnedOn: s.firstWorkout,
    ),
    Award(
      id: 't25',
      group: AwardGroup.training,
      shape: MedalShape.circle,
      tone: MedalTone.orange,
      big: '25',
      small: 'WORKOUTS',
      need: 25,
      have: s.workouts,
    ),
    Award(
      id: 'tpr',
      group: AwardGroup.training,
      shape: MedalShape.circle,
      tone: MedalTone.orange,
      big: '10',
      small: 'BESTS',
      need: 10,
      have: s.prs,
    ),
    Award(
      id: 'month',
      group: AwardGroup.challenge,
      shape: MedalShape.shield,
      tone: MedalTone.blue,
      need: monthTarget,
      have: s.workoutsThisMonth,
      names: monthTitle,
    ),
    for (final x in extra) _extra(s, x),
  ];
}

Award _extra(AwardStats s, ExtraAward x) {
  final (group, shape, tone, small, have, earnedOn) = switch (x.metric) {
    AwardMetric.loggedDays => (
      AwardGroup.food,
      MedalShape.circle,
      MedalTone.green,
      'DAYS',
      s.fullDays.length,
      s.fullDays.length >= x.threshold ? s.fullDays[x.threshold - 1] : null,
    ),
    AwardMetric.workouts => (AwardGroup.training, MedalShape.circle, MedalTone.orange, 'WORKOUTS', s.workouts, null),
    AwardMetric.streakDays => (
      AwardGroup.streak,
      MedalShape.hex,
      MedalTone.lime,
      'DAYS',
      s.streak.best,
      milestoneDates(s.streak.marks, [x.threshold])[x.threshold],
    ),
  };
  return Award(
    id: 'pk_${x.id}',
    group: group,
    shape: shape,
    tone: tone,
    big: '${x.threshold}',
    small: small,
    need: x.threshold,
    have: have,
    earnedOn: earnedOn,
    names: x.names,
    descriptions: x.descriptions,
  );
}

/// The next streak award still ahead, for the "next award" line.
Award? nextStreakAward(List<Award> all) =>
    all.where((a) => a.group == AwardGroup.streak && a.icon == null && !a.earned).firstOrNull;

/// Best count of protein days in any Monday-to-Sunday week.
int bestProteinWeek(Iterable<DateTime> hitDays) {
  final byWeek = <DateTime, int>{};
  for (final d in hitDays) {
    final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    byWeek[monday] = (byWeek[monday] ?? 0) + 1;
  }
  return byWeek.values.fold(0, (a, b) => a > b ? a : b);
}
