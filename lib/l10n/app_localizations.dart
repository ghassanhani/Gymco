import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en'), Locale('es')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Gymco'**
  String get appName;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get tabFood;

  /// No description provided for @tabTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get tabTrain;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Make it {accent}'**
  String todayTitle(String accent);

  /// No description provided for @todayAccent.
  ///
  /// In en, this message translates to:
  /// **'count'**
  String get todayAccent;

  /// No description provided for @kcalLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} kcal left'**
  String kcalLeft(String n);

  /// No description provided for @kcalOver.
  ///
  /// In en, this message translates to:
  /// **'{n} kcal past target'**
  String kcalOver(String n);

  /// No description provided for @ofGrams.
  ///
  /// In en, this message translates to:
  /// **'{a} / {b} g'**
  String ofGrams(String a, String b);

  /// No description provided for @protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fat;

  /// No description provided for @kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @snack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get snack;

  /// No description provided for @nothingLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get nothingLogged;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemsCount(int count);

  /// No description provided for @emptyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'A fresh day'**
  String get emptyDayTitle;

  /// No description provided for @emptyDayBody.
  ///
  /// In en, this message translates to:
  /// **'Start with whatever you ate first. One meal is a good start.'**
  String get emptyDayBody;

  /// No description provided for @habitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s habits'**
  String get habitsTitle;

  /// No description provided for @habitProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein at every meal'**
  String get habitProtein;

  /// No description provided for @habitMealsLogged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No meals logged} =1{1 meal logged} other{{count} meals logged}}'**
  String habitMealsLogged(int count);

  /// No description provided for @addFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get addFood;

  /// No description provided for @addTo.
  ///
  /// In en, this message translates to:
  /// **'Add to {meal}'**
  String addTo(String meal);

  /// No description provided for @searchFoods.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get searchFoods;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcode;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No match for \"{q}\"'**
  String noResults(String q);

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter word, or scan the packet.'**
  String get noResultsBody;

  /// No description provided for @barcodeMiss.
  ///
  /// In en, this message translates to:
  /// **'We don\'t know this product yet'**
  String get barcodeMiss;

  /// No description provided for @barcodeMissBody.
  ///
  /// In en, this message translates to:
  /// **'Add it to Open Food Facts in about 30 seconds and it\'ll be there for everyone next time.'**
  String get barcodeMissBody;

  /// No description provided for @contributeOff.
  ///
  /// In en, this message translates to:
  /// **'Add to Open Food Facts'**
  String get contributeOff;

  /// No description provided for @searchingOnline.
  ///
  /// In en, this message translates to:
  /// **'Searching online…'**
  String get searchingOnline;

  /// No description provided for @offlineSearch.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing foods saved on this phone'**
  String get offlineSearch;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get grams;

  /// No description provided for @per100g.
  ///
  /// In en, this message translates to:
  /// **'per 100 g'**
  String get per100g;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @logged.
  ///
  /// In en, this message translates to:
  /// **'Logged {food}'**
  String logged(String food);

  /// No description provided for @cameraPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow the camera to scan barcodes.'**
  String get cameraPermission;

  /// No description provided for @obWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Diet and training, {accent}'**
  String obWelcomeTitle(String accent);

  /// No description provided for @obWelcomeAccent.
  ///
  /// In en, this message translates to:
  /// **'together'**
  String get obWelcomeAccent;

  /// No description provided for @obWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Targets that adapt to what you actually eat and weigh. No guessing, no punishment.'**
  String get obWelcomeBody;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @obGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you working toward?'**
  String get obGoalTitle;

  /// No description provided for @goalCut.
  ///
  /// In en, this message translates to:
  /// **'Lose fat'**
  String get goalCut;

  /// No description provided for @goalCutSub.
  ///
  /// In en, this message translates to:
  /// **'Keep the muscle, lose the fat'**
  String get goalCutSub;

  /// No description provided for @goalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goalMaintain;

  /// No description provided for @goalMaintainSub.
  ///
  /// In en, this message translates to:
  /// **'Hold your weight, build strength'**
  String get goalMaintainSub;

  /// No description provided for @goalBulk.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get goalBulk;

  /// No description provided for @goalBulkSub.
  ///
  /// In en, this message translates to:
  /// **'A slow, lean gain'**
  String get goalBulkSub;

  /// No description provided for @obBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get obBodyTitle;

  /// No description provided for @obBodyBody.
  ///
  /// In en, this message translates to:
  /// **'Used once to seed your first week. After that, your own logs take over.'**
  String get obBodyBody;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @obActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'How active is a normal day?'**
  String get obActivityTitle;

  /// No description provided for @actSedentary.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting'**
  String get actSedentary;

  /// No description provided for @actLight.
  ///
  /// In en, this message translates to:
  /// **'On my feet some of the day'**
  String get actLight;

  /// No description provided for @actModerate.
  ///
  /// In en, this message translates to:
  /// **'Active job or daily walks'**
  String get actModerate;

  /// No description provided for @actHigh.
  ///
  /// In en, this message translates to:
  /// **'Physical job'**
  String get actHigh;

  /// No description provided for @actAthlete.
  ///
  /// In en, this message translates to:
  /// **'Hard training twice a day'**
  String get actAthlete;

  /// No description provided for @obRateTitle.
  ///
  /// In en, this message translates to:
  /// **'How fast?'**
  String get obRateTitle;

  /// No description provided for @ratePerWeek.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of body weight a week'**
  String ratePerWeek(String pct);

  /// No description provided for @rateKgPerWeek.
  ///
  /// In en, this message translates to:
  /// **'≈ {kg} kg a week'**
  String rateKgPerWeek(String kg);

  /// No description provided for @rateWarning.
  ///
  /// In en, this message translates to:
  /// **'Faster than 0.85% a week usually costs muscle and sleep. You can, but we\'ll check in more often.'**
  String get rateWarning;

  /// No description provided for @rateCapNote.
  ///
  /// In en, this message translates to:
  /// **'Capped at 1% a week.'**
  String get rateCapNote;

  /// No description provided for @obTargetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your starting targets'**
  String get obTargetsTitle;

  /// No description provided for @obTargetsBody.
  ///
  /// In en, this message translates to:
  /// **'This is week one. Every check-in, Gymco recalculates from your logs and trend weight, by at most 120 kcal a week.'**
  String get obTargetsBody;

  /// No description provided for @dailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get dailyTarget;

  /// No description provided for @noNumbersOffer.
  ///
  /// In en, this message translates to:
  /// **'Rather not see numbers?'**
  String get noNumbersOffer;

  /// No description provided for @noNumbersOfferBody.
  ///
  /// In en, this message translates to:
  /// **'No-numbers mode hides calories, macros and weight, and tracks habits instead.'**
  String get noNumbersOfferBody;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @startBtn.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startBtn;

  /// No description provided for @meTitle.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get meTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get systemLanguage;

  /// No description provided for @noNumbersMode.
  ///
  /// In en, this message translates to:
  /// **'No-numbers mode'**
  String get noNumbersMode;

  /// No description provided for @noNumbersModeSub.
  ///
  /// In en, this message translates to:
  /// **'Hide calories, macros and weight'**
  String get noNumbersModeSub;

  /// No description provided for @leaveNoNumbersTitle.
  ///
  /// In en, this message translates to:
  /// **'Show numbers again?'**
  String get leaveNoNumbersTitle;

  /// No description provided for @leaveNoNumbersBody.
  ///
  /// In en, this message translates to:
  /// **'Calories, macros and weight will be visible on every screen.'**
  String get leaveNoNumbersBody;

  /// No description provided for @leaveNoNumbersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Show numbers'**
  String get leaveNoNumbersConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cheatAllowance.
  ///
  /// In en, this message translates to:
  /// **'Cheat meals'**
  String get cheatAllowance;

  /// No description provided for @cheatOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get cheatOff;

  /// No description provided for @cheatOnce.
  ///
  /// In en, this message translates to:
  /// **'1 a week'**
  String get cheatOnce;

  /// No description provided for @cheatTwice.
  ///
  /// In en, this message translates to:
  /// **'2 a week'**
  String get cheatTwice;

  /// No description provided for @targets.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get targets;

  /// No description provided for @redoOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Change goal and targets'**
  String get redoOnboarding;

  /// No description provided for @trainTitle.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get trainTitle;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @nextBuild.
  ///
  /// In en, this message translates to:
  /// **'This part of Gymco is designed and is being built next.'**
  String get nextBuild;

  /// No description provided for @repeatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Repeat yesterday'**
  String get repeatYesterday;

  /// No description provided for @nothingYesterday.
  ///
  /// In en, this message translates to:
  /// **'Nothing was logged in this meal yesterday'**
  String get nothingYesterday;

  /// No description provided for @trainTitleTpl.
  ///
  /// In en, this message translates to:
  /// **'Train {accent}'**
  String trainTitleTpl(String accent);

  /// No description provided for @trainAccent.
  ///
  /// In en, this message translates to:
  /// **'hard'**
  String get trainAccent;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routines;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get newRoutine;

  /// No description provided for @editRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit routine'**
  String get editRoutine;

  /// No description provided for @emptyWorkout.
  ///
  /// In en, this message translates to:
  /// **'Empty workout'**
  String get emptyWorkout;

  /// No description provided for @startRoutine.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startRoutine;

  /// No description provided for @resumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeWorkout;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress · {time}'**
  String inProgress(String time);

  /// No description provided for @noRoutinesTitle.
  ///
  /// In en, this message translates to:
  /// **'No routines yet'**
  String get noRoutinesTitle;

  /// No description provided for @noRoutinesBody.
  ///
  /// In en, this message translates to:
  /// **'Build one, or start an empty workout and add exercises as you go.'**
  String get noRoutinesBody;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'Finished workouts show up here.'**
  String get noHistory;

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String setsCount(int count);

  /// No description provided for @exercisesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exercisesCount(int count);

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine name'**
  String get routineName;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nameTaken.
  ///
  /// In en, this message translates to:
  /// **'You already have a routine called “{name}”.'**
  String nameTaken(String name);

  /// No description provided for @deleteRoutine.
  ///
  /// In en, this message translates to:
  /// **'Delete routine'**
  String get deleteRoutine;

  /// No description provided for @deleteRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this routine?'**
  String get deleteRoutineTitle;

  /// No description provided for @deleteRoutineBody.
  ///
  /// In en, this message translates to:
  /// **'Workouts you\'ve already done stay in your history.'**
  String get deleteRoutineBody;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @setsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsLabel;

  /// No description provided for @restLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restLabel;

  /// No description provided for @repRange.
  ///
  /// In en, this message translates to:
  /// **'{lo}–{hi} reps'**
  String repRange(int lo, int hi);

  /// No description provided for @restSeconds.
  ///
  /// In en, this message translates to:
  /// **'{s} s rest'**
  String restSeconds(int s);

  /// No description provided for @searchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get searchExercises;

  /// No description provided for @allMuscles.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allMuscles;

  /// No description provided for @addCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 exercise} other{Add {count} exercises}}'**
  String addCount(int count);

  /// No description provided for @m_chest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get m_chest;

  /// No description provided for @m_shoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get m_shoulders;

  /// No description provided for @m_triceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get m_triceps;

  /// No description provided for @m_biceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get m_biceps;

  /// No description provided for @m_forearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get m_forearms;

  /// No description provided for @m_lats.
  ///
  /// In en, this message translates to:
  /// **'Lats'**
  String get m_lats;

  /// No description provided for @m_middle_back.
  ///
  /// In en, this message translates to:
  /// **'Mid back'**
  String get m_middle_back;

  /// No description provided for @m_lower_back.
  ///
  /// In en, this message translates to:
  /// **'Lower back'**
  String get m_lower_back;

  /// No description provided for @m_traps.
  ///
  /// In en, this message translates to:
  /// **'Traps'**
  String get m_traps;

  /// No description provided for @m_abdominals.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get m_abdominals;

  /// No description provided for @m_quadriceps.
  ///
  /// In en, this message translates to:
  /// **'Quads'**
  String get m_quadriceps;

  /// No description provided for @m_hamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get m_hamstrings;

  /// No description provided for @m_glutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get m_glutes;

  /// No description provided for @m_calves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get m_calves;

  /// No description provided for @m_adductors.
  ///
  /// In en, this message translates to:
  /// **'Adductors'**
  String get m_adductors;

  /// No description provided for @m_abductors.
  ///
  /// In en, this message translates to:
  /// **'Abductors'**
  String get m_abductors;

  /// No description provided for @m_neck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get m_neck;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard workout'**
  String get discard;

  /// No description provided for @discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this workout?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing from it will be saved.'**
  String get discardBody;

  /// No description provided for @unfinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Some sets aren\'t ticked'**
  String get unfinishedTitle;

  /// No description provided for @unfinishedBody.
  ///
  /// In en, this message translates to:
  /// **'Only ticked sets are saved.'**
  String get unfinishedBody;

  /// No description provided for @finishAnyway.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishAnyway;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @durationLbl.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get durationLbl;

  /// No description provided for @volumeLbl.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLbl;

  /// No description provided for @setsDoneLbl.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsDoneLbl;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSet;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @kgLbl.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgLbl;

  /// No description provided for @repsLbl.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get repsLbl;

  /// No description provided for @restRunning.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restRunning;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @setTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Set type'**
  String get setTypeTitle;

  /// No description provided for @stWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get stWarmup;

  /// No description provided for @stWarmupSub.
  ///
  /// In en, this message translates to:
  /// **'Primes the lift. Not counted toward weekly sets.'**
  String get stWarmupSub;

  /// No description provided for @stNormal.
  ///
  /// In en, this message translates to:
  /// **'Working set'**
  String get stNormal;

  /// No description provided for @stNormalSub.
  ///
  /// In en, this message translates to:
  /// **'Counts as one hard set.'**
  String get stNormalSub;

  /// No description provided for @stFailure.
  ///
  /// In en, this message translates to:
  /// **'To failure'**
  String get stFailure;

  /// No description provided for @stFailureSub.
  ///
  /// In en, this message translates to:
  /// **'Counts as one hard set.'**
  String get stFailureSub;

  /// No description provided for @stDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop set'**
  String get stDrop;

  /// No description provided for @stDropSub.
  ///
  /// In en, this message translates to:
  /// **'Counts as half a set.'**
  String get stDropSub;

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Remove set'**
  String get removeSet;

  /// No description provided for @removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get removeExercise;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout done'**
  String get summaryTitle;

  /// No description provided for @newBest.
  ///
  /// In en, this message translates to:
  /// **'New best: {exercise}'**
  String newBest(String exercise);

  /// No description provided for @estOneRm.
  ///
  /// In en, this message translates to:
  /// **'est. 1RM {kg} kg'**
  String estOneRm(String kg);

  /// No description provided for @doneBtn.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneBtn;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'How to do it'**
  String get instructions;

  /// No description provided for @primaryMuscles.
  ///
  /// In en, this message translates to:
  /// **'Main muscles'**
  String get primaryMuscles;

  /// No description provided for @secondaryMuscles.
  ///
  /// In en, this message translates to:
  /// **'Also works'**
  String get secondaryMuscles;

  /// No description provided for @photoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo not available offline'**
  String get photoUnavailable;

  /// No description provided for @workoutDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutDefaultName;

  /// No description provided for @startWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'Add an exercise to begin.'**
  String get startWorkoutHint;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String minutesShort(String m);

  /// No description provided for @tickSetHint.
  ///
  /// In en, this message translates to:
  /// **'Tick set'**
  String get tickSetHint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
