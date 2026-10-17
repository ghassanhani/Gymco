// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Gymco';

  @override
  String get tabToday => 'Today';

  @override
  String get tabFood => 'Food';

  @override
  String get tabTrain => 'Train';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabMe => 'Me';

  @override
  String todayTitle(String accent) {
    return 'Make it $accent';
  }

  @override
  String get todayAccent => 'count';

  @override
  String kcalLeft(String n) {
    return '$n kcal left';
  }

  @override
  String kcalOver(String n) {
    return '$n kcal past target';
  }

  @override
  String ofGrams(String a, String b) {
    return '$a / $b g';
  }

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get kcal => 'kcal';

  @override
  String get meals => 'Meals';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get snack => 'Snack';

  @override
  String get nothingLogged => 'Nothing logged yet';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count items', one: '1 item');
    return '$_temp0';
  }

  @override
  String get emptyDayTitle => 'A fresh day';

  @override
  String get emptyDayBody => 'Start with whatever you ate first. One meal is a good start.';

  @override
  String get habitsTitle => 'Today\'s habits';

  @override
  String get habitProtein => 'Protein at every meal';

  @override
  String habitMealsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals logged',
      one: '1 meal logged',
      zero: 'No meals logged',
    );
    return '$_temp0';
  }

  @override
  String get addFood => 'Add food';

  @override
  String addTo(String meal) {
    return 'Add to $meal';
  }

  @override
  String get searchFoods => 'Search foods';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get recent => 'Recent';

  @override
  String noResults(String q) {
    return 'No match for \"$q\"';
  }

  @override
  String get noResultsBody => 'Try a shorter word, or scan the packet.';

  @override
  String get barcodeMiss => 'We don\'t know this product yet';

  @override
  String get barcodeMissBody =>
      'Add it to Open Food Facts in about 30 seconds and it\'ll be there for everyone next time.';

  @override
  String get contributeOff => 'Add to Open Food Facts';

  @override
  String get searchingOnline => 'Searching online…';

  @override
  String get offlineSearch => 'Offline — showing foods saved on this phone';

  @override
  String get amount => 'Amount';

  @override
  String get grams => 'g';

  @override
  String get per100g => 'per 100 g';

  @override
  String get log => 'Log';

  @override
  String get delete => 'Delete';

  @override
  String logged(String food) {
    return 'Logged $food';
  }

  @override
  String get cameraPermission => 'Allow the camera to scan barcodes.';

  @override
  String obWelcomeTitle(String accent) {
    return 'Diet and training, $accent';
  }

  @override
  String get obWelcomeAccent => 'together';

  @override
  String get obWelcomeBody => 'Targets that adapt to what you actually eat and weigh. No guessing, no punishment.';

  @override
  String get getStarted => 'Get started';

  @override
  String get obGoalTitle => 'What are you working toward?';

  @override
  String get goalCut => 'Lose fat';

  @override
  String get goalCutSub => 'Keep the muscle, lose the fat';

  @override
  String get goalMaintain => 'Maintain';

  @override
  String get goalMaintainSub => 'Hold your weight, build strength';

  @override
  String get goalBulk => 'Build muscle';

  @override
  String get goalBulkSub => 'A slow, lean gain';

  @override
  String get obBodyTitle => 'About you';

  @override
  String get obBodyBody => 'Used once to seed your first week. After that, your own logs take over.';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get age => 'Age';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get obActivityTitle => 'How active is a normal day?';

  @override
  String get actSedentary => 'Mostly sitting';

  @override
  String get actLight => 'On my feet some of the day';

  @override
  String get actModerate => 'Active job or daily walks';

  @override
  String get actHigh => 'Physical job';

  @override
  String get actAthlete => 'Hard training twice a day';

  @override
  String get obRateTitle => 'How fast?';

  @override
  String ratePerWeek(String pct) {
    return '$pct% of body weight a week';
  }

  @override
  String rateKgPerWeek(String kg) {
    return '≈ $kg kg a week';
  }

  @override
  String get rateWarning =>
      'Faster than 0.85% a week usually costs muscle and sleep. You can, but we\'ll check in more often.';

  @override
  String get rateCapNote => 'Capped at 1% a week.';

  @override
  String get obTargetsTitle => 'Your starting targets';

  @override
  String get obTargetsBody =>
      'This is week one. Every check-in, Gymco recalculates from your logs and trend weight, by at most 120 kcal a week.';

  @override
  String get dailyTarget => 'Daily target';

  @override
  String get noNumbersOffer => 'Rather not see numbers?';

  @override
  String get noNumbersOfferBody => 'No-numbers mode hides calories, macros and weight, and tracks habits instead.';

  @override
  String get continueBtn => 'Continue';

  @override
  String get startBtn => 'Start';

  @override
  String get meTitle => 'Me';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'Phone language';

  @override
  String get noNumbersMode => 'No-numbers mode';

  @override
  String get noNumbersModeSub => 'Hide calories, macros and weight';

  @override
  String get leaveNoNumbersTitle => 'Show numbers again?';

  @override
  String get leaveNoNumbersBody => 'Calories, macros and weight will be visible on every screen.';

  @override
  String get leaveNoNumbersConfirm => 'Show numbers';

  @override
  String get cancel => 'Cancel';

  @override
  String get cheatAllowance => 'Cheat meals';

  @override
  String get cheatOff => 'Off';

  @override
  String get cheatOnce => '1 a week';

  @override
  String get cheatTwice => '2 a week';

  @override
  String get targets => 'Targets';

  @override
  String get redoOnboarding => 'Change goal and targets';

  @override
  String get trainTitle => 'Train';

  @override
  String get progressTitle => 'Progress';

  @override
  String get nextBuild => 'This part of Gymco is designed and is being built next.';

  @override
  String get repeatYesterday => 'Repeat yesterday';

  @override
  String get nothingYesterday => 'Nothing was logged in this meal yesterday';

  @override
  String trainTitleTpl(String accent) {
    return 'Train $accent';
  }

  @override
  String get trainAccent => 'hard';

  @override
  String get routines => 'Routines';

  @override
  String get newRoutine => 'New routine';

  @override
  String get editRoutine => 'Edit routine';

  @override
  String get emptyWorkout => 'Empty workout';

  @override
  String get startRoutine => 'Start';

  @override
  String get resumeWorkout => 'Resume';

  @override
  String inProgress(String time) {
    return 'Workout in progress · $time';
  }

  @override
  String get noRoutinesTitle => 'No routines yet';

  @override
  String get noRoutinesBody => 'Build one, or start an empty workout and add exercises as you go.';

  @override
  String get history => 'History';

  @override
  String get noHistory => 'Finished workouts show up here.';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count sets', one: '1 set');
    return '$_temp0';
  }

  @override
  String exercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count exercises', one: '1 exercise');
    return '$_temp0';
  }

  @override
  String get routineName => 'Routine name';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get save => 'Save';

  @override
  String nameTaken(String name) {
    return 'You already have a routine called “$name”.';
  }

  @override
  String get deleteRoutine => 'Delete routine';

  @override
  String get deleteRoutineTitle => 'Delete this routine?';

  @override
  String get deleteRoutineBody => 'Workouts you\'ve already done stay in your history.';

  @override
  String get edit => 'Edit';

  @override
  String get setsLabel => 'Sets';

  @override
  String get repsLabel => 'Reps';

  @override
  String get restLabel => 'Rest';

  @override
  String repRange(int lo, int hi) {
    return '$lo–$hi reps';
  }

  @override
  String restSeconds(int s) {
    return '$s s rest';
  }

  @override
  String get searchExercises => 'Search exercises';

  @override
  String get allMuscles => 'All';

  @override
  String addCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count exercises',
      one: 'Add 1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get m_chest => 'Chest';

  @override
  String get m_shoulders => 'Shoulders';

  @override
  String get m_triceps => 'Triceps';

  @override
  String get m_biceps => 'Biceps';

  @override
  String get m_forearms => 'Forearms';

  @override
  String get m_lats => 'Lats';

  @override
  String get m_middle_back => 'Mid back';

  @override
  String get m_lower_back => 'Lower back';

  @override
  String get m_traps => 'Traps';

  @override
  String get m_abdominals => 'Abs';

  @override
  String get m_quadriceps => 'Quads';

  @override
  String get m_hamstrings => 'Hamstrings';

  @override
  String get m_glutes => 'Glutes';

  @override
  String get m_calves => 'Calves';

  @override
  String get m_adductors => 'Adductors';

  @override
  String get m_abductors => 'Abductors';

  @override
  String get m_neck => 'Neck';

  @override
  String get finish => 'Finish';

  @override
  String get discard => 'Discard workout';

  @override
  String get discardTitle => 'Discard this workout?';

  @override
  String get discardBody => 'Nothing from it will be saved.';

  @override
  String get unfinishedTitle => 'Some sets aren\'t ticked';

  @override
  String get unfinishedBody => 'Only ticked sets are saved.';

  @override
  String get finishAnyway => 'Finish';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get durationLbl => 'Time';

  @override
  String get volumeLbl => 'Volume';

  @override
  String get setsDoneLbl => 'Sets';

  @override
  String get addSet => 'Add set';

  @override
  String get previous => 'Previous';

  @override
  String get kgLbl => 'kg';

  @override
  String get repsLbl => 'reps';

  @override
  String get restRunning => 'Rest';

  @override
  String get skip => 'Skip';

  @override
  String get setTypeTitle => 'Set type';

  @override
  String get stWarmup => 'Warm-up';

  @override
  String get stWarmupSub => 'Primes the lift. Not counted toward weekly sets.';

  @override
  String get stNormal => 'Working set';

  @override
  String get stNormalSub => 'Counts as one hard set.';

  @override
  String get stFailure => 'To failure';

  @override
  String get stFailureSub => 'Counts as one hard set.';

  @override
  String get stDrop => 'Drop set';

  @override
  String get stDropSub => 'Counts as half a set.';

  @override
  String get removeSet => 'Remove set';

  @override
  String get removeExercise => 'Remove exercise';

  @override
  String get summaryTitle => 'Workout done';

  @override
  String newBest(String exercise) {
    return 'New best: $exercise';
  }

  @override
  String estOneRm(String kg) {
    return 'est. 1RM $kg kg';
  }

  @override
  String get doneBtn => 'Done';

  @override
  String get instructions => 'How to do it';

  @override
  String get primaryMuscles => 'Main muscles';

  @override
  String get secondaryMuscles => 'Also works';

  @override
  String get photoUnavailable => 'Photo not available offline';

  @override
  String get workoutDefaultName => 'Workout';

  @override
  String get startWorkoutHint => 'Add an exercise to begin.';

  @override
  String minutesShort(String m) {
    return '$m min';
  }

  @override
  String get tickSetHint => 'Tick set';
}
