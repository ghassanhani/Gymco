import 'dart:math' as math;

import 'energy.dart';

/// The body measurements the app keeps, in the order they are shown. Each is
/// stored under its name, in centimetres.
enum BodyMeasure { waist, hips, neck, chest, arm, thigh }

/// Body fat from a tape measure, by the US Navy formula: waist and neck, and
/// hips for women, with height. Good to about 3–4 points against a scan, and
/// best for watching the trend. Null when a measurement is missing or the
/// numbers can't be right.
double? navyBodyFatPct({
  required Sex sex,
  required double heightCm,
  required double? waistCm,
  required double? neckCm,
  double? hipsCm,
}) {
  if (waistCm == null || neckCm == null || heightCm <= 0) return null;
  double log10(double x) => math.log(x) / math.ln10;
  final double pct;
  switch (sex) {
    case Sex.male:
      if (waistCm - neckCm <= 0) return null;
      pct = 495 / (1.0324 - 0.19077 * log10(waistCm - neckCm) + 0.15456 * log10(heightCm)) - 450;
    case Sex.female:
      if (hipsCm == null || waistCm + hipsCm - neckCm <= 0) return null;
      pct = 495 / (1.29579 - 0.35004 * log10(waistCm + hipsCm - neckCm) + 0.22100 * log10(heightCm)) - 450;
  }
  return pct.isFinite && pct >= 2 && pct <= 60 ? pct : null;
}
