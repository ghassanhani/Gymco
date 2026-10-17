import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/food_source.dart';
import '../data/local_db.dart';
import '../data/models.dart';
import '../domain/cheat_meal.dart';
import '../domain/energy.dart';

/// Opened in main() and injected with an override.
final dbProvider = Provider<LocalDb>((_) => throw UnimplementedError('dbProvider'));
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('prefsProvider'));

final foodSourceProvider = Provider<FoodSource>((_) => OpenFoodFactsSource());

/// Injected so tests can pin "today".
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

// ---------------- settings ----------------

class Settings {
  const Settings({this.languageCode, this.noNumbers = false, this.cheatAllowance = CheatAllowance.oncePerWeek});

  /// Null follows the phone.
  final String? languageCode;
  final bool noNumbers;
  final CheatAllowance cheatAllowance;

  Locale? get locale => languageCode == null ? null : Locale(languageCode!);

  Settings copyWith({String? Function()? languageCode, bool? noNumbers, CheatAllowance? cheatAllowance}) => Settings(
    languageCode: languageCode == null ? this.languageCode : languageCode(),
    noNumbers: noNumbers ?? this.noNumbers,
    cheatAllowance: cheatAllowance ?? this.cheatAllowance,
  );
}

class SettingsNotifier extends Notifier<Settings> {
  static const _kLang = 'lang', _kNoNum = 'noNumbers', _kCheat = 'cheatAllowance';

  SharedPreferences get _p => ref.read(prefsProvider);

  @override
  Settings build() {
    final p = ref.watch(prefsProvider);
    return Settings(
      languageCode: p.getString(_kLang),
      noNumbers: p.getBool(_kNoNum) ?? false,
      cheatAllowance: CheatAllowance.values[p.getInt(_kCheat) ?? 1],
    );
  }

  Future<void> setLanguage(String? code) async {
    code == null ? await _p.remove(_kLang) : await _p.setString(_kLang, code);
    state = state.copyWith(languageCode: () => code);
  }

  Future<void> setNoNumbers(bool on) async {
    await _p.setBool(_kNoNum, on);
    state = state.copyWith(noNumbers: on);
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
  }

  Future<void> remove(LogEntry e) async {
    await ref.read(dbProvider).deleteEntry(e.id!);
    ref.invalidate(dayEntriesProvider(e.day));
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
