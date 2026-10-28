import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/body_fat.dart';
import 'package:gymco/domain/energy.dart';

void main() {
  test('a man is measured by waist and neck', () {
    expect(navyBodyFatPct(sex: Sex.male, heightCm: 178, waistCm: 85, neckCm: 38), closeTo(16.4, 0.2));
  });

  test('a woman needs her hips too', () {
    expect(navyBodyFatPct(sex: Sex.female, heightCm: 165, waistCm: 72, neckCm: 32), isNull);
    expect(navyBodyFatPct(sex: Sex.female, heightCm: 165, waistCm: 72, neckCm: 32, hipsCm: 98), closeTo(27.4, 0.2));
  });

  test('a missing or impossible measurement gives nothing', () {
    expect(navyBodyFatPct(sex: Sex.male, heightCm: 178, waistCm: 85, neckCm: null), isNull);
    expect(navyBodyFatPct(sex: Sex.male, heightCm: 178, waistCm: 38, neckCm: 40), isNull);
  });
}
