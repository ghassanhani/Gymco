/// Weekly hard sets per muscle group, as the volume cards show them.
///
/// Ten to twenty hard sets a muscle a week is where the evidence is
/// strongest: under it is leaving growth on the table, over it is mostly
/// buying fatigue.
library;

enum MuscleGroup { chest, shoulders, triceps, back, biceps, legs, core }

const int volumeLow = 10;
const int volumeHigh = 20;

/// The group an exercise counts toward, from its primary muscle.
MuscleGroup? groupOf(String primaryMuscle) => switch (primaryMuscle) {
  'chest' => MuscleGroup.chest,
  'shoulders' => MuscleGroup.shoulders,
  'triceps' => MuscleGroup.triceps,
  'lats' || 'middle back' || 'lower back' || 'traps' => MuscleGroup.back,
  'biceps' || 'forearms' => MuscleGroup.biceps,
  'quadriceps' || 'hamstrings' || 'glutes' || 'calves' || 'adductors' || 'abductors' => MuscleGroup.legs,
  'abdominals' => MuscleGroup.core,
  _ => null,
};

enum VolumeState { under, inRange, over }

class GroupVolume {
  const GroupVolume(this.group, this.added, this.total);
  final MuscleGroup group;

  /// Sets this plan adds.
  final int added;

  /// Sets for the week with this plan on top of the rest.
  final int total;

  VolumeState get state =>
      total < volumeLow ? VolumeState.under : (total > volumeHigh ? VolumeState.over : VolumeState.inRange);
}

/// [plan] and [rest] are (primary muscle, sets) pairs. Only the groups this
/// plan touches are returned, biggest first.
List<GroupVolume> weeklyVolume(List<(String, int)> plan, List<(String, int)> rest) {
  final add = <MuscleGroup, int>{};
  for (final (m, sets) in plan) {
    final g = groupOf(m);
    if (g != null) add[g] = (add[g] ?? 0) + sets;
  }
  final base = <MuscleGroup, int>{};
  for (final (m, sets) in rest) {
    final g = groupOf(m);
    if (g != null) base[g] = (base[g] ?? 0) + sets;
  }
  final out = [for (final e in add.entries) GroupVolume(e.key, e.value, (base[e.key] ?? 0) + e.value)];
  out.sort((a, b) => b.total.compareTo(a.total));
  return out;
}

/// The prototype's honest duration estimate: working sets × (rest + 40 s), in minutes.
int planMinutes(Iterable<(int sets, int rest)> items) {
  var s = 0;
  for (final (sets, rest) in items) {
    s += sets * ((rest == 0 ? 90 : rest) + 40);
  }
  return (s / 60).round();
}
