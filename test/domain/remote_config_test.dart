import 'package:flutter_test/flutter_test.dart';
import 'package:gymco/domain/remote_config.dart';

void main() {
  test('with nothing fetched, the app runs on today\'s values', () {
    const c = RemoteConfig.defaults;
    expect(c.photoLog, isTrue);
    expect(c.calorieFloor, 1700);
    expect(c.maxRatePctWeek, 1);
    expect(c.maxWeeklyChange, 120);
    expect(c.freezeEveryDays, 7);
    expect(c.freezeMax, 3);
    expect(c.waterMlPerKg, 35);
    expect(c.minBuild('ios'), 0);
    expect(c.maintenance, isFalse);
  });

  test('a fetched config is read, and anything missing keeps its default', () {
    final c = RemoteConfig.fromJson({
      'features': {'cheat_meals': false},
      'limits': {'photo_note_max_chars': 200},
      'water': {'ml_per_kg': 33},
      'app_gate': {'min_build_android': 102, 'recommended_build': 104},
    });
    expect(c.cheatMeals, isFalse);
    expect(c.photoLog, isTrue);
    expect(c.photoNoteMaxChars, 200);
    expect(c.waterMlPerKg, 33);
    expect(c.minBuild('android'), 102);
    expect(c.minBuild('ios'), 0);
    expect(c.recommendedBuild, 104);
  });

  test('values outside the safety bounds never reach the app, whatever the server says', () {
    final c = RemoteConfig.fromJson({
      'safety': {'calorie_floor': 900, 'max_rate_pct_week': 3, 'max_weekly_target_change_kcal': 500},
      'streak': {'freeze_max': 'lots'},
    });
    expect(c.calorieFloor, 1200);
    expect(c.maxRatePctWeek, 1);
    expect(c.maxWeeklyChange, 120);
    expect(c.freezeMax, 3);
  });

  test('the maintenance message falls back to English, then to the built-in one', () {
    final c = RemoteConfig.fromJson({
      'app_gate': {
        'maintenance_mode': true,
        'maintenance_message': {'en': 'Upgrading', 'ar': '', 'es': 'Mejorando'},
      },
    });
    expect(c.maintenance, isTrue);
    expect(c.maintenanceMessage('es'), 'Mejorando');
    expect(c.maintenanceMessage('ar'), 'Upgrading');
    expect(RemoteConfig.defaults.maintenanceMessage('en'), contains('diary'));
  });

  test('a config survives a round trip through the cache', () {
    final c = RemoteConfig.fromJson({
      'limits': {'photo_note_max_chars': 222},
    });
    expect(RemoteConfig.fromJson(c.toJson()).photoNoteMaxChars, 222);
  });
}
