import 'remote_config.dart';

/// One drink: when, as minutes after midnight, and how much.
typedef Sip = ({int minute, int ml});

/// A day's water: every drink, in the order it was logged.
class WaterDay {
  const WaterDay(this.sips);
  final List<Sip> sips;

  int get ml => sips.fold(0, (s, x) => s + x.ml);

  /// Stored as "minute:ml,minute:ml".
  String encode() => sips.map((s) => '${s.minute}:${s.ml}').join(',');

  static WaterDay decode(String? raw, {int? legacyMl}) {
    if (raw == null || raw.isEmpty) {
      // Days logged before the log existed kept only a total.
      return WaterDay([if (legacyMl != null && legacyMl > 0) (minute: 0, ml: legacyMl)]);
    }
    return WaterDay([
      for (final part in raw.split(','))
        if (part.split(':') case [final m, final v] when int.tryParse(m) != null && int.tryParse(v) != null)
          (minute: int.parse(m), ml: int.parse(v)),
    ]);
  }
}

/// A daily water goal: about 35 ml per kg of body weight, with half a
/// litre more on a training day, rounded to 100 ml and kept to 1.5–5 L.
int waterGoalMl({required double weightKg, required bool trained}) {
  final c = RemoteConfig.current;
  final base = (weightKg * c.waterMlPerKg / 100).round() * 100;
  return (base + (trained ? c.waterTrainingBonusMl : 0)).clamp(c.waterMinMl, c.waterMaxMl);
}
