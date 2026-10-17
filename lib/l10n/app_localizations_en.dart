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
}
