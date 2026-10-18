import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dictation.dart';
import '../data/food_source.dart';
import '../data/local_db.dart';
import '../data/models.dart';
import '../domain/cheat_meal.dart';
import '../domain/energy.dart';

/// Opened in main() and injected with an override.
final dbProvider = Provider<LocalDb>((_) => throw UnimplementedError('dbProvider'));
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('prefsProvider'));

final foodSourceProvider = Provider<FoodSource>((_) => OpenFoodFactsSource());

/// On-device speech to text; tests swap in a fake.
final dictationProvider = Provider<Dictation>((_) => DeviceDictation());

/// Injected so tests can pin "today".
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

// ---------------- settings ----------------

class Settings {
  const Settings({this.languageCode, this.cheatAllowance = CheatAllowance.oncePerWeek});

  /// Null follows the phone.
  final String? languageCode;
  final CheatAllowance cheatAllowance;

  Locale? get locale => languageCode == null ? null : Locale(languageCode!);

  Settings copyWith({String? Function()? languageCode, CheatAllowance? cheatAllowance}) => Settings(
    languageCode: languageCode == null ? this.languageCode : languageCode(),
    cheatAllowance: cheatAllowance ?? this.cheatAllowance,
  );
}

class SettingsNotifier extends Notifier<Settings> {
  static const _kLang = 'lang', _kCheat = 'cheatAllowance';

  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  Settings build() {
    final p = ref.watch(prefsProvider);
    return Settings(languageCode: p.getString(_kLang), cheatAllowance: CheatAllowance.values[p.getInt(_kCheat) ?? 1]);
  }

  Future<void> setLanguage(String? code) async {
    code == null ? await _p.remove(_kLang) : await _p.setString(_kLang, code);
    state = state.copyWith(languageCode: () => code);
  }

  Future<void> setCheatAllowance(CheatAllowance a) async {
    await _p.setInt(_kCheat, a.index);
    state = state.copyWith(cheatAllowance: a);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

// ---------------- profile ----------------

class ProfileNotifier extends Notifier<Profile?> {
  static const _k = 'profile';

  @override
  Profile? build() {
    final raw = ref.watch(prefsProvider).getString(_k);
    return raw == null ? null : Profile.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  Future<void> save(Profile p) async {
    await ref.read(prefsProvider).setString(_k, jsonEncode(p.toJson()));
    await ref.read(dbProvider).setWeight(dayKey(p.startedOn), p.weightKg);
    state = p;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

// ---------------- the log ----------------

final todayKeyProvider = Provider<String>((ref) => dayKey(ref.watch(clockProvider)()));

/// The day Today is showing: null is today, else a closed day from the strip.
class ViewDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void show(DateTime? d) => state = d;
}

final viewDayProvider = NotifierProvider<ViewDayNotifier, DateTime?>(ViewDayNotifier.new);

/// Which strip days have food logged.
final loggedDaysProvider = FutureProvider<Set<String>>((ref) {
  final t = ref.watch(clockProvider)();
  final from = DateTime(t.year, t.month, t.day - 7);
  ref.watch(dayEntriesProvider(dayKey(t)));
  return ref.watch(dbProvider).loggedDays(dayKey(from), dayKey(t));
});

/// Water drunk per day, in ml, kept on the phone.
class WaterNotifier extends Notifier<int> {
  WaterNotifier(this.day);
  final String day;

  @override
  int build() => ref.watch(prefsProvider).getInt('water_$day') ?? 0;

  Future<void> add(int ml) async {
    state = (state + ml).clamp(0, 20000);
    await ref.read(prefsProvider).setInt('water_$day', state);
  }
}

final waterProvider = NotifierProvider.family<WaterNotifier, int, String>(WaterNotifier.new);

/// Every weigh-in, oldest first.
final weighInsProvider = FutureProvider<List<(String, double)>>((ref) {
  ref.watch(profileProvider);
  return ref.watch(dbProvider).weighIns();
});

final dayEntriesProvider = FutureProvider.family<List<LogEntry>, String>(
  (ref, day) => ref.watch(dbProvider).entriesFor(day),
);

class DayTotals {
  const DayTotals(this.entries);
  final List<LogEntry> entries;

  double get kcal => entries.fold(0, (s, e) => s + e.kcal);
  Macros get macros => entries.fold(const Macros(protein: 0, carbs: 0, fat: 0), (s, e) => s + e.macros);
  List<LogEntry> inMeal(Meal m) => entries.where((e) => e.meal == m).toList();
  int get mealsLogged => Meal.values.where((m) => inMeal(m).isNotEmpty).length;
}

/// Writes go through here so every screen reading the day refreshes.
class LogActions {
  LogActions(this.ref);
  final Ref ref;

  Future<void> add(LogEntry e) async {
    await ref.read(dbProvider).addEntry(e);
    ref.invalidate(dayEntriesProvider(e.day));
    ref.invalidate(loggedDaysProvider);
  }

  Future<void> setGrams(LogEntry e, double grams, Meal meal) async {
    await ref.read(dbProvider).updateEntryGrams(e, grams, meal);
    ref.invalidate(dayEntriesProvider(e.day));
  }

  Future<int> copyDay(String from) async {
    final to = ref.read(todayKeyProvider);
    final n = await ref.read(dbProvider).copyDay(from: from, to: to);
    ref.invalidate(dayEntriesProvider(to));
    ref.invalidate(loggedDaysProvider);
    return n;
  }

  Future<void> remove(LogEntry e) async {
    await ref.read(dbProvider).deleteEntry(e.id!);
    ref.invalidate(dayEntriesProvider(e.day));
  }

  /// Copy one meal of today into tomorrow.
  Future<int> copyToTomorrow(Meal meal) async {
    final today = ref.read(clockProvider)();
    final to = dayKey(today.add(const Duration(days: 1)));
    final n = await ref.read(dbProvider).repeatMeal(from: dayKey(today), to: to, meal: meal);
    ref.invalidate(dayEntriesProvider(to));
    ref.invalidate(loggedDaysProvider);
    return n;
  }

  Future<void> saveMeal(String name, List<LogEntry> entries) async {
    await ref.read(dbProvider).saveMeal(name, entries);
    ref.invalidate(savedMealsProvider);
  }

  Future<void> logSaved(SavedMeal m, Meal meal) async {
    final day = ref.read(todayKeyProvider);
    for (final (f, g) in m.items) {
      await ref.read(dbProvider).addEntry(LogEntry.of(f, day: day, meal: meal, grams: g));
    }
    ref.invalidate(dayEntriesProvider(day));
    ref.invalidate(loggedDaysProvider);
  }

  Future<int> repeatYesterday(Meal meal) async {
    final today = ref.read(clockProvider)();
    final n = await ref
        .read(dbProvider)
        .repeatMeal(from: dayKey(today.subtract(const Duration(days: 1))), to: dayKey(today), meal: meal);
    ref.invalidate(dayEntriesProvider(dayKey(today)));
    return n;
  }
}

final logActionsProvider = Provider<LogActions>(LogActions.new);

final savedMealsProvider = FutureProvider<List<SavedMeal>>((ref) => ref.watch(dbProvider).savedMeals());
final customFoodsProvider = FutureProvider<List<Food>>((ref) => ref.watch(dbProvider).customFoods());

// ---------------- your data ----------------

final dataCountsProvider = FutureProvider((ref) {
  ref.watch(loggedDaysProvider);
  return ref.watch(dbProvider).counts();
});

/// When the health-data consent was given, from onboarding.
DateTime? consentedAt(SharedPreferences p) => DateTime.tryParse(p.getString('consent_health') ?? '');

Future<void> recordConsent(SharedPreferences p, DateTime at) async {
  if (p.getString('consent_health') == null) await p.setString('consent_health', at.toIso8601String());
}

/// Wipe the phone back to a first run.
Future<void> deleteEverything(WidgetRef ref) async {
  await ref.read(dbProvider).wipe();
  await ref.read(prefsProvider).clear();
  ref.invalidate(settingsProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(dayEntriesProvider);
  ref.invalidate(loggedDaysProvider);
  ref.invalidate(weighInsProvider);
  ref.invalidate(waterProvider);
  ref.invalidate(savedMealsProvider);
  ref.invalidate(customFoodsProvider);
  ref.invalidate(dataCountsProvider);
}
