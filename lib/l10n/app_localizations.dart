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
  /// **'What are you training for?'**
  String get obGoalTitle;

  /// No description provided for @goalCut.
  ///
  /// In en, this message translates to:
  /// **'Cut'**
  String get goalCut;

  /// No description provided for @goalCutSub.
  ///
  /// In en, this message translates to:
  /// **'Lose fat, hold on to muscle and strength'**
  String get goalCutSub;

  /// No description provided for @goalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get goalMaintain;

  /// No description provided for @goalMaintainSub.
  ///
  /// In en, this message translates to:
  /// **'Hold weight and keep logging honestly'**
  String get goalMaintainSub;

  /// No description provided for @goalBulk.
  ///
  /// In en, this message translates to:
  /// **'Lean bulk'**
  String get goalBulk;

  /// No description provided for @goalBulkSub.
  ///
  /// In en, this message translates to:
  /// **'Add size at 0.25–0.5% of body weight a week'**
  String get goalBulkSub;

  /// No description provided for @obBodyTitle.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get obBodyTitle;

  /// No description provided for @obBodyBody.
  ///
  /// In en, this message translates to:
  /// **'Used to seed week one only. After 14 days your real expenditure takes over.'**
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
  /// **'An estimate, not a verdict. After two or three weeks of logging, Gymco replaces it with your measured expenditure.'**
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
  /// **'You already have a routine called {name}. Pick another name or edit that one.'**
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
  /// **'The routine goes. Every workout you already logged from it stays in your history, with its sets and PRs.'**
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
  /// **'Duration'**
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
  /// **'Does not count toward weekly sets'**
  String get stWarmupSub;

  /// No description provided for @stNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get stNormal;

  /// No description provided for @stNormalSub.
  ///
  /// In en, this message translates to:
  /// **'A hard working set'**
  String get stNormalSub;

  /// No description provided for @stFailure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get stFailure;

  /// No description provided for @stFailureSub.
  ///
  /// In en, this message translates to:
  /// **'Taken to technical failure'**
  String get stFailureSub;

  /// No description provided for @stDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop set'**
  String get stDrop;

  /// No description provided for @stDropSub.
  ///
  /// In en, this message translates to:
  /// **'Counts as half a set'**
  String get stDropSub;

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Remove this set'**
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

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'about'**
  String get about;

  /// No description provided for @actSitting.
  ///
  /// In en, this message translates to:
  /// **'Mostly sitting'**
  String get actSitting;

  /// No description provided for @actSittingSub.
  ///
  /// In en, this message translates to:
  /// **'Desk job, under 5,000 steps'**
  String get actSittingSub;

  /// No description provided for @actFeet.
  ///
  /// In en, this message translates to:
  /// **'On my feet'**
  String get actFeet;

  /// No description provided for @actFeetSub.
  ///
  /// In en, this message translates to:
  /// **'Walking a lot, 5,000–10,000 steps'**
  String get actFeetSub;

  /// No description provided for @actPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical job'**
  String get actPhysical;

  /// No description provided for @actPhysicalSub.
  ///
  /// In en, this message translates to:
  /// **'Lifting or carrying most of the day'**
  String get actPhysicalSub;

  /// No description provided for @actVery.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get actVery;

  /// No description provided for @actVerySub.
  ///
  /// In en, this message translates to:
  /// **'Over 12,000 steps or a second sport'**
  String get actVerySub;

  /// No description provided for @addFoodToMeal.
  ///
  /// In en, this message translates to:
  /// **'Add food to this meal'**
  String get addFoodToMeal;

  /// No description provided for @addNoWeighing.
  ///
  /// In en, this message translates to:
  /// **'Add what you ate — no weighing'**
  String get addNoWeighing;

  /// No description provided for @addWater.
  ///
  /// In en, this message translates to:
  /// **'Add 250 ml of water'**
  String get addWater;

  /// No description provided for @agreeToContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree to continue'**
  String get agreeToContinue;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get backToToday;

  /// No description provided for @calorieFloor.
  ///
  /// In en, this message translates to:
  /// **'Calorie floor'**
  String get calorieFloor;

  /// No description provided for @cheatAllowanceNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing is ever paid back with cardio. A banked meal takes a slice off the days before it; a free one is simply not logged.'**
  String get cheatAllowanceNote;

  /// No description provided for @chooseRoutine.
  ///
  /// In en, this message translates to:
  /// **'Choose a routine'**
  String get chooseRoutine;

  /// No description provided for @cm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cm;

  /// No description provided for @consentHealth.
  ///
  /// In en, this message translates to:
  /// **'I agree to Gymco storing my weight, measurements and food logs as health data on this phone, to calculate my targets.'**
  String get consentHealth;

  /// No description provided for @copiedToToday.
  ///
  /// In en, this message translates to:
  /// **'Copied to today'**
  String get copiedToToday;

  /// No description provided for @copyToToday.
  ///
  /// In en, this message translates to:
  /// **'Copy to today'**
  String get copyToToday;

  /// No description provided for @createdByYou.
  ///
  /// In en, this message translates to:
  /// **'created by you'**
  String get createdByYou;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @customFood.
  ///
  /// In en, this message translates to:
  /// **'Custom food'**
  String get customFood;

  /// No description provided for @deleteDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get deleteDigit;

  /// No description provided for @emptyMeal.
  ///
  /// In en, this message translates to:
  /// **'Empty meal'**
  String get emptyMeal;

  /// No description provided for @firstRunTip.
  ///
  /// In en, this message translates to:
  /// **'Most people log the same eight or ten things. Build those once and a day takes about twenty seconds.'**
  String get firstRunTip;

  /// No description provided for @floorBody.
  ///
  /// In en, this message translates to:
  /// **'Targets are never set below this. Going lower means typing the number yourself, after a warning.'**
  String get floorBody;

  /// No description provided for @floorSub.
  ///
  /// In en, this message translates to:
  /// **'kcal · your floor'**
  String get floorSub;

  /// No description provided for @followsPhone.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone'**
  String get followsPhone;

  /// No description provided for @freeAlways.
  ///
  /// In en, this message translates to:
  /// **'free, always'**
  String get freeAlways;

  /// No description provided for @genericUsda.
  ///
  /// In en, this message translates to:
  /// **'Generic · USDA'**
  String get genericUsda;

  /// No description provided for @genericUsdaVerified.
  ///
  /// In en, this message translates to:
  /// **'Generic · USDA · verified'**
  String get genericUsdaVerified;

  /// No description provided for @goalAndTargets.
  ///
  /// In en, this message translates to:
  /// **'Goal and targets'**
  String get goalAndTargets;

  /// No description provided for @goalRecomp.
  ///
  /// In en, this message translates to:
  /// **'Recomposition'**
  String get goalRecomp;

  /// No description provided for @goalRecompSub.
  ///
  /// In en, this message translates to:
  /// **'Sit near maintenance; watch the waist, not the scale'**
  String get goalRecompSub;

  /// No description provided for @goalPrep.
  ///
  /// In en, this message translates to:
  /// **'Contest prep'**
  String get goalPrep;

  /// No description provided for @goalPrepSub.
  ///
  /// In en, this message translates to:
  /// **'Work backwards from a stage date'**
  String get goalPrepSub;

  /// No description provided for @goalShortCut.
  ///
  /// In en, this message translates to:
  /// **'cut'**
  String get goalShortCut;

  /// No description provided for @goalShortBulk.
  ///
  /// In en, this message translates to:
  /// **'lean bulk'**
  String get goalShortBulk;

  /// No description provided for @goalShortRecomp.
  ///
  /// In en, this message translates to:
  /// **'recomp'**
  String get goalShortRecomp;

  /// No description provided for @goalShortMaintain.
  ///
  /// In en, this message translates to:
  /// **'maintain'**
  String get goalShortMaintain;

  /// No description provided for @goalShortPrep.
  ///
  /// In en, this message translates to:
  /// **'contest prep'**
  String get goalShortPrep;

  /// No description provided for @habitMealsNone.
  ///
  /// In en, this message translates to:
  /// **'Meals logged, none skipped'**
  String get habitMealsNone;

  /// No description provided for @habitProteinEach.
  ///
  /// In en, this message translates to:
  /// **'A protein source at each one'**
  String get habitProteinEach;

  /// No description provided for @habitTrained.
  ///
  /// In en, this message translates to:
  /// **'Trained today'**
  String get habitTrained;

  /// No description provided for @habitsHiddenBody.
  ///
  /// In en, this message translates to:
  /// **'Your entries are still saved. Nothing is being scored, and no target is tracked against you.'**
  String get habitsHiddenBody;

  /// No description provided for @habitsHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Calories, macros and weight are hidden'**
  String get habitsHiddenTitle;

  /// No description provided for @heightLbl.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightLbl;

  /// No description provided for @heroDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Logged and saved. Recovery is where it turns into the next one.'**
  String get heroDoneBody;

  /// No description provided for @heroExercises.
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get heroExercises;

  /// No description provided for @heroMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get heroMin;

  /// No description provided for @heroMuscles.
  ///
  /// In en, this message translates to:
  /// **'muscles'**
  String get heroMuscles;

  /// No description provided for @heroRestBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled today. Recovery is where the last session turns into the next one.'**
  String get heroRestBody;

  /// No description provided for @heroRestTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest <em>day</em>'**
  String get heroRestTitle;

  /// No description provided for @heroSets.
  ///
  /// In en, this message translates to:
  /// **'sets'**
  String get heroSets;

  /// No description provided for @heroSetupBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a split or build your own. Gymco schedules it and tracks every set.'**
  String get heroSetupBody;

  /// No description provided for @heroSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your <em>training</em>'**
  String get heroSetupTitle;

  /// No description provided for @heroTagDone.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get heroTagDone;

  /// No description provided for @heroTagInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get heroTagInProgress;

  /// No description provided for @heroTagToday.
  ///
  /// In en, this message translates to:
  /// **'Today’s workout'**
  String get heroTagToday;

  /// No description provided for @howTodayWent.
  ///
  /// In en, this message translates to:
  /// **'How today went'**
  String get howTodayWent;

  /// No description provided for @inThisMeal.
  ///
  /// In en, this message translates to:
  /// **'In this meal'**
  String get inThisMeal;

  /// No description provided for @kcalADay.
  ///
  /// In en, this message translates to:
  /// **'kcal a day'**
  String get kcalADay;

  /// No description provided for @kcalLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get kcalLeftLabel;

  /// No description provided for @kcalLoggedLabel.
  ///
  /// In en, this message translates to:
  /// **'kcal logged'**
  String get kcalLoggedLabel;

  /// No description provided for @kcalOverLabel.
  ///
  /// In en, this message translates to:
  /// **'kcal past target'**
  String get kcalOverLabel;

  /// No description provided for @kcalToLog.
  ///
  /// In en, this message translates to:
  /// **'kcal to log'**
  String get kcalToLog;

  /// No description provided for @keepThemHidden.
  ///
  /// In en, this message translates to:
  /// **'Keep them hidden'**
  String get keepThemHidden;

  /// No description provided for @langArabicSub.
  ///
  /// In en, this message translates to:
  /// **'Arabic · right-to-left'**
  String get langArabicSub;

  /// No description provided for @langEnglishSub.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglishSub;

  /// No description provided for @langSpanishSub.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanishSub;

  /// No description provided for @logFirstMeal.
  ///
  /// In en, this message translates to:
  /// **'Log your first meal'**
  String get logFirstMeal;

  /// No description provided for @logNoWeighing.
  ///
  /// In en, this message translates to:
  /// **'Log what you ate — no weighing'**
  String get logNoWeighing;

  /// No description provided for @mBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get mBarcode;

  /// No description provided for @mPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get mPhoto;

  /// No description provided for @mSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get mSearch;

  /// No description provided for @mVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get mVoice;

  /// No description provided for @mWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get mWrite;

  /// No description provided for @mealDetailTip.
  ///
  /// In en, this message translates to:
  /// **'Tap an item to change its portion. Anything you remove leaves today straight away.'**
  String get mealDetailTip;

  /// No description provided for @mealLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get mealLabel;

  /// No description provided for @myMeals.
  ///
  /// In en, this message translates to:
  /// **'My meals'**
  String get myMeals;

  /// No description provided for @noMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Home cooking rarely is. Scan the pack, or try another word.'**
  String get noMatchBody;

  /// No description provided for @noMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No match in the database'**
  String get noMatchTitle;

  /// No description provided for @noNumbersOfferLine.
  ///
  /// In en, this message translates to:
  /// **'Rather not see numbers? No-numbers mode hides calories, macros and weight, and tracks habits instead.'**
  String get noNumbersOfferLine;

  /// No description provided for @noNumbersOn.
  ///
  /// In en, this message translates to:
  /// **'On — calories and weight hidden'**
  String get noNumbersOn;

  /// No description provided for @noSessionPlanned.
  ///
  /// In en, this message translates to:
  /// **'No session planned'**
  String get noSessionPlanned;

  /// No description provided for @nothingInMeal.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this meal yet'**
  String get nothingInMeal;

  /// No description provided for @nothingYesterdayDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing was logged yesterday'**
  String get nothingYesterdayDay;

  /// No description provided for @numbersHidden.
  ///
  /// In en, this message translates to:
  /// **'Numbers hidden'**
  String get numbersHidden;

  /// No description provided for @obActivityTitleEm.
  ///
  /// In en, this message translates to:
  /// **'How do you <em>move</em> on a normal day?'**
  String get obActivityTitleEm;

  /// No description provided for @obBodyTitleEm.
  ///
  /// In en, this message translates to:
  /// **'A bit about <em>you</em>'**
  String get obBodyTitleEm;

  /// No description provided for @obGoalBody.
  ///
  /// In en, this message translates to:
  /// **'This sets your rate, protein floor and how the coach reads your data. You can change it any week.'**
  String get obGoalBody;

  /// No description provided for @obRateBodyGain.
  ///
  /// In en, this message translates to:
  /// **'Slow is lean. A quarter to half a percent of body weight a week keeps the gain mostly muscle.'**
  String get obRateBodyGain;

  /// No description provided for @obRateBodyLose.
  ///
  /// In en, this message translates to:
  /// **'Faster is not better. Between 0.5 and 1% of body weight a week is where muscle retention holds up.'**
  String get obRateBodyLose;

  /// No description provided for @obRateTitleGain.
  ///
  /// In en, this message translates to:
  /// **'How fast do you want to gain?'**
  String get obRateTitleGain;

  /// No description provided for @obRateTitleLose.
  ///
  /// In en, this message translates to:
  /// **'How fast do you want to lose?'**
  String get obRateTitleLose;

  /// No description provided for @pastNoteWithin.
  ///
  /// In en, this message translates to:
  /// **'Within a hundred of target. Days like this are what move the trend line.'**
  String get pastNoteWithin;

  /// No description provided for @pctPerWeek.
  ///
  /// In en, this message translates to:
  /// **'% / week'**
  String get pctPerWeek;

  /// No description provided for @photoComing.
  ///
  /// In en, this message translates to:
  /// **'Photograph the plate and Gymco suggests what it sees; you say how much. Arrives with AI logging.'**
  String get photoComing;

  /// No description provided for @rateHot.
  ///
  /// In en, this message translates to:
  /// **'Above 0.85%/week you start paying in muscle. Gymco will keep saying so, every week, until you slow down.'**
  String get rateHot;

  /// No description provided for @rateOkGain.
  ///
  /// In en, this message translates to:
  /// **'Slow enough that most of the gain is muscle.'**
  String get rateOkGain;

  /// No description provided for @rateOkLose.
  ///
  /// In en, this message translates to:
  /// **'In the range Helms et al. (2014) recommend for natural lifters holding muscle through a deficit.'**
  String get rateOkLose;

  /// No description provided for @readyToLog.
  ///
  /// In en, this message translates to:
  /// **'ready to log'**
  String get readyToLog;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get restDay;

  /// No description provided for @ringEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet. Your targets are set — the ring fills as you go.'**
  String get ringEmptyBody;

  /// No description provided for @rtlNote.
  ///
  /// In en, this message translates to:
  /// **'Arabic flips the whole app to right-to-left, including the week strip and swipe directions.'**
  String get rtlNote;

  /// No description provided for @safeguards.
  ///
  /// In en, this message translates to:
  /// **'Safeguards'**
  String get safeguards;

  /// No description provided for @savedSeeTrain.
  ///
  /// In en, this message translates to:
  /// **'Saved · see it in Train'**
  String get savedSeeTrain;

  /// No description provided for @scanABarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode'**
  String get scanABarcode;

  /// No description provided for @scanBarcodeSub.
  ///
  /// In en, this message translates to:
  /// **'Packaged food resolves straight to the pack’s own numbers'**
  String get scanBarcodeSub;

  /// No description provided for @searchDatabase.
  ///
  /// In en, this message translates to:
  /// **'Search the database'**
  String get searchDatabase;

  /// No description provided for @searchOtherLanguage.
  ///
  /// In en, this message translates to:
  /// **'Searching in another language often finds more — Gymco keeps every name it learns on the same food.'**
  String get searchOtherLanguage;

  /// No description provided for @seeTheWeek.
  ///
  /// In en, this message translates to:
  /// **'See the week'**
  String get seeTheWeek;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sexForEquation.
  ///
  /// In en, this message translates to:
  /// **'Sex for the energy equation'**
  String get sexForEquation;

  /// No description provided for @startLogging.
  ///
  /// In en, this message translates to:
  /// **'Start logging'**
  String get startLogging;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @supportBody.
  ///
  /// In en, this message translates to:
  /// **'Support lines and services near you'**
  String get supportBody;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Talking to someone helps'**
  String get supportTitle;

  /// No description provided for @swipeToStart.
  ///
  /// In en, this message translates to:
  /// **'Swipe to start'**
  String get swipeToStart;

  /// No description provided for @targetsSaved.
  ///
  /// In en, this message translates to:
  /// **'Targets saved — start logging'**
  String get targetsSaved;

  /// No description provided for @theRemainder.
  ///
  /// In en, this message translates to:
  /// **'the remainder'**
  String get theRemainder;

  /// No description provided for @todayPlain.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayPlain;

  /// No description provided for @todayTitleEm.
  ///
  /// In en, this message translates to:
  /// **'Make it <em>count</em>'**
  String get todayTitleEm;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @trainingCountedSeparately.
  ///
  /// In en, this message translates to:
  /// **'Training is counted separately. Don’t include the gym here.'**
  String get trainingCountedSeparately;

  /// No description provided for @trendNeedsDays.
  ///
  /// In en, this message translates to:
  /// **'A trend needs about seven days'**
  String get trendNeedsDays;

  /// No description provided for @trendWeight.
  ///
  /// In en, this message translates to:
  /// **'Trend weight'**
  String get trendWeight;

  /// No description provided for @unitsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Units & language'**
  String get unitsLanguage;

  /// No description provided for @usuallyNow.
  ///
  /// In en, this message translates to:
  /// **'You usually eat around now'**
  String get usuallyNow;

  /// No description provided for @voiceComing.
  ///
  /// In en, this message translates to:
  /// **'Hold and say what you ate. It goes through the same reader as writing. Arrives with AI logging.'**
  String get voiceComing;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @waterAdded.
  ///
  /// In en, this message translates to:
  /// **'250 ml added'**
  String get waterAdded;

  /// No description provided for @weightToday.
  ///
  /// In en, this message translates to:
  /// **'Weight today'**
  String get weightToday;

  /// No description provided for @welcomeArtAlt.
  ///
  /// In en, this message translates to:
  /// **'A woman mid kettlebell swing'**
  String get welcomeArtAlt;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Log food in seconds, train with a plan, and keep a streak worth protecting.'**
  String get welcomeBody;

  /// No description provided for @welcomeTitleEm.
  ///
  /// In en, this message translates to:
  /// **'Start your <em>fitness</em> journey today'**
  String get welcomeTitleEm;

  /// No description provided for @writeComing.
  ///
  /// In en, this message translates to:
  /// **'Write the meal the way you would say it — “two eggs, 150 g rice”. Arrives with AI logging.'**
  String get writeComing;

  /// No description provided for @yesterdayCopied.
  ///
  /// In en, this message translates to:
  /// **'Yesterday copied in'**
  String get yesterdayCopied;

  /// No description provided for @yrs.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get yrs;

  /// No description provided for @addKcal.
  ///
  /// In en, this message translates to:
  /// **'Add {kcal} kcal'**
  String addKcal(String kcal);

  /// No description provided for @saveKcal.
  ///
  /// In en, this message translates to:
  /// **'Save · {kcal} kcal'**
  String saveKcal(String kcal);

  /// No description provided for @addToMeal.
  ///
  /// In en, this message translates to:
  /// **'Add to {meal}'**
  String addToMeal(String meal);

  /// No description provided for @closedDay.
  ///
  /// In en, this message translates to:
  /// **'{date} · closed day'**
  String closedDay(String date);

  /// No description provided for @floorNote.
  ///
  /// In en, this message translates to:
  /// **'Your targets will never be set below {kcal} kcal.'**
  String floorNote(String kcal);

  /// No description provided for @foodAdded.
  ///
  /// In en, this message translates to:
  /// **'{food} added'**
  String foodAdded(String food);

  /// No description provided for @foodRemoved.
  ///
  /// In en, this message translates to:
  /// **'{food} removed'**
  String foodRemoved(String food);

  /// No description provided for @removeFood.
  ///
  /// In en, this message translates to:
  /// **'Remove {food}'**
  String removeFood(String food);

  /// No description provided for @gPerKg.
  ///
  /// In en, this message translates to:
  /// **'{g} g/kg'**
  String gPerKg(String g);

  /// No description provided for @heroDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} <em>done</em>'**
  String heroDoneTitle(String name);

  /// No description provided for @heroWeekTag.
  ///
  /// In en, this message translates to:
  /// **'Week {n}'**
  String heroWeekTag(int n);

  /// No description provided for @itemsLoggedTo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item logged to {meal}} other{{count} items logged to {meal}}}'**
  String itemsLoggedTo(int count, String meal);

  /// No description provided for @itemsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item selected} other{{count} items selected}}'**
  String itemsSelected(int count);

  /// No description provided for @kcalAndProtein.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {p} g protein'**
  String kcalAndProtein(String kcal, String p);

  /// No description provided for @leftToday.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal and {p} g protein left today'**
  String leftToday(String kcal, String p);

  /// No description provided for @litres.
  ///
  /// In en, this message translates to:
  /// **'{l} L'**
  String litres(String l);

  /// No description provided for @logN.
  ///
  /// In en, this message translates to:
  /// **'Log {n}'**
  String logN(int n);

  /// No description provided for @maxPct.
  ///
  /// In en, this message translates to:
  /// **'{pct} max'**
  String maxPct(String pct);

  /// No description provided for @meSub.
  ///
  /// In en, this message translates to:
  /// **'{goal}, week {week}'**
  String meSub(String goal, int week);

  /// No description provided for @moreCount.
  ///
  /// In en, this message translates to:
  /// **'+{n} more'**
  String moreCount(int n);

  /// No description provided for @ofTarget.
  ///
  /// In en, this message translates to:
  /// **'/ {n} g'**
  String ofTarget(String n);

  /// No description provided for @oneServing.
  ///
  /// In en, this message translates to:
  /// **'1 serving · {g} g'**
  String oneServing(String g);

  /// No description provided for @pastNoteOver.
  ///
  /// In en, this message translates to:
  /// **'{n} over target — one day, and the weekly average is what the maths reads.'**
  String pastNoteOver(String n);

  /// No description provided for @pastNoteUnder.
  ///
  /// In en, this message translates to:
  /// **'{n} under target. Fine once; a habit of it is how you lose more than fat.'**
  String pastNoteUnder(String n);

  /// No description provided for @ratePerWeekShort.
  ///
  /// In en, this message translates to:
  /// **'{pct} %/wk'**
  String ratePerWeekShort(String pct);

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String resultsCount(int count);

  /// No description provided for @resumeAt.
  ///
  /// In en, this message translates to:
  /// **'Resume · {time}'**
  String resumeAt(String time);

  /// No description provided for @setTo.
  ///
  /// In en, this message translates to:
  /// **'{food} set to {g} g'**
  String setTo(String food, String g);

  /// No description provided for @shareOfToday.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of today'**
  String shareOfToday(int pct);

  /// No description provided for @targetsHow.
  ///
  /// In en, this message translates to:
  /// **'Mifflin-St Jeor × {mult}, then your chosen rate of {rate}%/week. Everything here is editable.'**
  String targetsHow(String mult, String rate);

  /// No description provided for @targetsHowMaintain.
  ///
  /// In en, this message translates to:
  /// **'Mifflin-St Jeor × {mult}, at maintenance. Everything here is editable.'**
  String targetsHowMaintain(String mult);

  /// No description provided for @targetsLine.
  ///
  /// In en, this message translates to:
  /// **'Protein {p} g · Carbs {c} g · Fat {f} g'**
  String targetsLine(String p, String c, String f);

  /// No description provided for @todaySub.
  ///
  /// In en, this message translates to:
  /// **'{date} · {goal}, week {week}'**
  String todaySub(String date, String goal, int week);

  /// No description provided for @todaySubDayOne.
  ///
  /// In en, this message translates to:
  /// **'{date} · day 1'**
  String todaySubDayOne(String date);

  /// No description provided for @weighInsSoFar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No weigh-ins yet} =1{One weigh-in so far} other{{count} weigh-ins so far}}'**
  String weighInsSoFar(int count);

  /// No description provided for @whatDidYouHave.
  ///
  /// In en, this message translates to:
  /// **'What did you have for {meal}?'**
  String whatDidYouHave(String meal);

  /// No description provided for @mealOptions.
  ///
  /// In en, this message translates to:
  /// **'Meal options'**
  String get mealOptions;

  /// No description provided for @saveAsMeal.
  ///
  /// In en, this message translates to:
  /// **'Save as a meal'**
  String get saveAsMeal;

  /// No description provided for @savedToMyMeals.
  ///
  /// In en, this message translates to:
  /// **'Saved — find it under My meals'**
  String get savedToMyMeals;

  /// No description provided for @copyToTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Copy to tomorrow'**
  String get copyToTomorrow;

  /// No description provided for @copiedToTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Copied to tomorrow'**
  String get copiedToTomorrow;

  /// No description provided for @clearMeal.
  ///
  /// In en, this message translates to:
  /// **'Clear this meal'**
  String get clearMeal;

  /// No description provided for @lastLogged.
  ///
  /// In en, this message translates to:
  /// **'Last logged {time}'**
  String lastLogged(String time);

  /// No description provided for @saveToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Save to favourites'**
  String get saveToFavourites;

  /// No description provided for @savedToFavourites.
  ///
  /// In en, this message translates to:
  /// **'Saved to favourites'**
  String get savedToFavourites;

  /// No description provided for @removedFromFavourites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favourites'**
  String get removedFromFavourites;

  /// No description provided for @saveAsCustom.
  ///
  /// In en, this message translates to:
  /// **'Save as custom'**
  String get saveAsCustom;

  /// No description provided for @savedAsCustom.
  ///
  /// In en, this message translates to:
  /// **'Saved as a custom food'**
  String get savedAsCustom;

  /// No description provided for @labelVerifiedOff.
  ///
  /// In en, this message translates to:
  /// **'{brand} · label verified · Open Food Facts'**
  String labelVerifiedOff(String brand);

  /// No description provided for @noSavedMeals.
  ///
  /// In en, this message translates to:
  /// **'No saved meals yet. Open a meal you eat often and tap Save as a meal.'**
  String get noSavedMeals;

  /// No description provided for @noCustomFoods.
  ///
  /// In en, this message translates to:
  /// **'No custom foods yet. Open any food and tap Save as custom to keep your own copy.'**
  String get noCustomFoods;

  /// No description provided for @recipesSoon.
  ///
  /// In en, this message translates to:
  /// **'Recipes are next: build one from ingredients, split it into portions, log a portion.'**
  String get recipesSoon;

  /// No description provided for @savedMealSub.
  ///
  /// In en, this message translates to:
  /// **'{count} items · {kcal} kcal'**
  String savedMealSub(int count, String kcal);

  /// No description provided for @loggedSavedMeal.
  ///
  /// In en, this message translates to:
  /// **'{name} logged'**
  String loggedSavedMeal(String name);

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @yourDataSub.
  ///
  /// In en, this message translates to:
  /// **'Export, consents, delete everything'**
  String get yourDataSub;

  /// No description provided for @takeEverything.
  ///
  /// In en, this message translates to:
  /// **'Take everything with you'**
  String get takeEverything;

  /// No description provided for @takeEverythingSub.
  ///
  /// In en, this message translates to:
  /// **'CSV and JSON, every table'**
  String get takeEverythingSub;

  /// No description provided for @foodLogRows.
  ///
  /// In en, this message translates to:
  /// **'Food log · {n} rows'**
  String foodLogRows(String n);

  /// No description provided for @weighInsCount.
  ///
  /// In en, this message translates to:
  /// **'Weigh-ins · {n}'**
  String weighInsCount(String n);

  /// No description provided for @exportNow.
  ///
  /// In en, this message translates to:
  /// **'Export now'**
  String get exportNow;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t export — try again'**
  String get exportFailed;

  /// No description provided for @whatYouAgreed.
  ///
  /// In en, this message translates to:
  /// **'What you agreed to, and when'**
  String get whatYouAgreed;

  /// No description provided for @consentHealthRow.
  ///
  /// In en, this message translates to:
  /// **'Health data processing · v1'**
  String get consentHealthRow;

  /// No description provided for @consentAnalyticsRow.
  ///
  /// In en, this message translates to:
  /// **'Anonymous analytics · none collected'**
  String get consentAnalyticsRow;

  /// No description provided for @onPhoneNote.
  ///
  /// In en, this message translates to:
  /// **'Everything lives on this phone. There is no account and no server, so nothing leaves it unless you export it.'**
  String get onPhoneNote;

  /// No description provided for @deleteEverything.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteEverything;

  /// No description provided for @deleteEverythingSub.
  ///
  /// In en, this message translates to:
  /// **'One tap, then one confirmation'**
  String get deleteEverythingSub;

  /// No description provided for @deleteEverythingBody.
  ///
  /// In en, this message translates to:
  /// **'Your log, workouts, routines, weigh-ins and targets go at once. Export first if you want your history — it cannot be recovered afterwards.'**
  String get deleteEverythingBody;

  /// No description provided for @deleteAllData.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAllData;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, delete it all'**
  String get deleteConfirm;

  /// No description provided for @keepMyData.
  ///
  /// In en, this message translates to:
  /// **'Keep my data'**
  String get keepMyData;

  /// No description provided for @dataSetsCount.
  ///
  /// In en, this message translates to:
  /// **'Sets · {n}'**
  String dataSetsCount(String n);

  /// No description provided for @setMacrosManually.
  ///
  /// In en, this message translates to:
  /// **'Set my macros manually'**
  String get setMacrosManually;

  /// No description provided for @useTheseMacros.
  ///
  /// In en, this message translates to:
  /// **'Use these macros'**
  String get useTheseMacros;

  /// No description provided for @backToCalculated.
  ///
  /// In en, this message translates to:
  /// **'Back to the calculated split'**
  String get backToCalculated;

  /// No description provided for @manualKcal.
  ///
  /// In en, this message translates to:
  /// **'That comes to {kcal} kcal a day.'**
  String manualKcal(String kcal);

  /// No description provided for @manualBelowFloor.
  ///
  /// In en, this message translates to:
  /// **'That comes to {kcal} kcal — under the {floor} kcal floor. Only go there with someone qualified watching.'**
  String manualBelowFloor(String kcal, String floor);

  /// No description provided for @projectedKg.
  ///
  /// In en, this message translates to:
  /// **'Projected {kg} kg'**
  String projectedKg(String kg);

  /// No description provided for @aroundDate.
  ///
  /// In en, this message translates to:
  /// **'around {date}'**
  String aroundDate(String date);

  /// No description provided for @inWeeks.
  ///
  /// In en, this message translates to:
  /// **'in {n} weeks'**
  String inWeeks(int n);

  /// No description provided for @moreOf.
  ///
  /// In en, this message translates to:
  /// **'More {what}'**
  String moreOf(String what);

  /// No description provided for @lessOf.
  ///
  /// In en, this message translates to:
  /// **'Less {what}'**
  String lessOf(String what);

  /// No description provided for @trainTitleEm.
  ///
  /// In en, this message translates to:
  /// **'Train <em>hard</em>'**
  String get trainTitleEm;

  /// No description provided for @trainSub.
  ///
  /// In en, this message translates to:
  /// **'{days} days a week · week {week}'**
  String trainSub(int days, int week);

  /// No description provided for @noWeeklyPlan.
  ///
  /// In en, this message translates to:
  /// **'No weekly plan yet'**
  String get noWeeklyPlan;

  /// No description provided for @dayAhead.
  ///
  /// In en, this message translates to:
  /// **'{date} · ahead'**
  String dayAhead(String date);

  /// No description provided for @dayClosed.
  ///
  /// In en, this message translates to:
  /// **'{date} · closed'**
  String dayClosed(String date);

  /// No description provided for @todayLbl.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLbl;

  /// No description provided for @plannedOn.
  ///
  /// In en, this message translates to:
  /// **'Planned · {day}'**
  String plannedOn(String day);

  /// No description provided for @movedHere.
  ///
  /// In en, this message translates to:
  /// **'Moved here · was {day}'**
  String movedHere(String day);

  /// No description provided for @loggedOfPlanned.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} logged · {sets} sets planned'**
  String loggedOfPlanned(int done, int total, int sets);

  /// No description provided for @setsAbout.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets · about {min} min'**
  String setsAbout(int sets, int min);

  /// No description provided for @startEarly.
  ///
  /// In en, this message translates to:
  /// **'Start early'**
  String get startEarly;

  /// No description provided for @startAll.
  ///
  /// In en, this message translates to:
  /// **'Start all'**
  String get startAll;

  /// No description provided for @startEarlyNote.
  ///
  /// In en, this message translates to:
  /// **'Starting it early moves the rest of the week up with it — the block keeps its order, not its dates.'**
  String get startEarlyNote;

  /// No description provided for @lastTimeRan.
  ///
  /// In en, this message translates to:
  /// **'Last time you ran it'**
  String get lastTimeRan;

  /// No description provided for @somethingElse.
  ///
  /// In en, this message translates to:
  /// **'Something else instead'**
  String get somethingElse;

  /// No description provided for @restMissed.
  ///
  /// In en, this message translates to:
  /// **'{name} was due and nothing was logged. It moved to the next day you train — the week slides, the order holds.'**
  String restMissed(String name);

  /// No description provided for @restAhead.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled. {day} is one of the days off this week.'**
  String restAhead(String day);

  /// No description provided for @restPast.
  ///
  /// In en, this message translates to:
  /// **'Nothing was logged, and nothing was due. Recovery is where the last session turns into the next one.'**
  String get restPast;

  /// No description provided for @nextSession.
  ///
  /// In en, this message translates to:
  /// **'Next session'**
  String get nextSession;

  /// No description provided for @sessionAfter.
  ///
  /// In en, this message translates to:
  /// **'The session after'**
  String get sessionAfter;

  /// No description provided for @logAnyway.
  ///
  /// In en, this message translates to:
  /// **'Log something anyway'**
  String get logAnyway;

  /// No description provided for @allRoutines.
  ///
  /// In en, this message translates to:
  /// **'All routines'**
  String get allRoutines;

  /// No description provided for @allRoutinesSub.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 routine} other{{n} routines}} · your exercise library'**
  String allRoutinesSub(int n);

  /// No description provided for @weeklySetsOf.
  ///
  /// In en, this message translates to:
  /// **'Weekly sets · {group}'**
  String weeklySetsOf(String group);

  /// No description provided for @hardSetsN.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hard set} other{{n} hard sets}}'**
  String hardSetsN(int n);

  /// No description provided for @zoneIn.
  ///
  /// In en, this message translates to:
  /// **'in the productive zone'**
  String get zoneIn;

  /// No description provided for @zoneUnder.
  ///
  /// In en, this message translates to:
  /// **'below the productive zone'**
  String get zoneUnder;

  /// No description provided for @zoneOver.
  ///
  /// In en, this message translates to:
  /// **'above the productive zone'**
  String get zoneOver;

  /// No description provided for @gBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get gBack;

  /// No description provided for @gLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get gLegs;

  /// No description provided for @gCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get gCore;

  /// No description provided for @closedLbl.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedLbl;

  /// No description provided for @hardSetsLbl.
  ///
  /// In en, this message translates to:
  /// **'Hard sets'**
  String get hardSetsLbl;

  /// No description provided for @bestSetEach.
  ///
  /// In en, this message translates to:
  /// **'Best set of each exercise'**
  String get bestSetEach;

  /// No description provided for @runAgain.
  ///
  /// In en, this message translates to:
  /// **'Run {name} again'**
  String runAgain(String name);

  /// No description provided for @trainEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet. Start from a proven template, or build exactly what you already do.'**
  String get trainEmptyBody;

  /// No description provided for @startEmptyWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start an empty workout'**
  String get startEmptyWorkout;

  /// No description provided for @startEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Add exercises as you go — it becomes a routine after'**
  String get startEmptySub;

  /// No description provided for @buildOwn.
  ///
  /// In en, this message translates to:
  /// **'Build my own routine'**
  String get buildOwn;

  /// No description provided for @buildOwnSub.
  ///
  /// In en, this message translates to:
  /// **'Unlimited routines, free'**
  String get buildOwnSub;

  /// No description provided for @orTemplate.
  ///
  /// In en, this message translates to:
  /// **'Or start from a template'**
  String get orTemplate;

  /// No description provided for @tplUL.
  ///
  /// In en, this message translates to:
  /// **'Upper / Lower, 4 days'**
  String get tplUL;

  /// No description provided for @tplULSub.
  ///
  /// In en, this message translates to:
  /// **'12–18 sets per muscle a week · intermediate'**
  String get tplULSub;

  /// No description provided for @tplPPL.
  ///
  /// In en, this message translates to:
  /// **'Push / Pull / Legs, 6 days'**
  String get tplPPL;

  /// No description provided for @tplPPLSub.
  ///
  /// In en, this message translates to:
  /// **'High frequency · advanced'**
  String get tplPPLSub;

  /// No description provided for @tplFB.
  ///
  /// In en, this message translates to:
  /// **'Full body, 3 days'**
  String get tplFB;

  /// No description provided for @tplFBSub.
  ///
  /// In en, this message translates to:
  /// **'The one to pick while cutting · any level'**
  String get tplFBSub;

  /// No description provided for @templateAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added to your weekly plan'**
  String templateAdded(String name);

  /// No description provided for @tplUpperA.
  ///
  /// In en, this message translates to:
  /// **'Upper A'**
  String get tplUpperA;

  /// No description provided for @tplUpperB.
  ///
  /// In en, this message translates to:
  /// **'Upper B'**
  String get tplUpperB;

  /// No description provided for @tplLowerA.
  ///
  /// In en, this message translates to:
  /// **'Lower A'**
  String get tplLowerA;

  /// No description provided for @tplLowerB.
  ///
  /// In en, this message translates to:
  /// **'Lower B'**
  String get tplLowerB;

  /// No description provided for @tplPushA.
  ///
  /// In en, this message translates to:
  /// **'Push A'**
  String get tplPushA;

  /// No description provided for @tplPushB.
  ///
  /// In en, this message translates to:
  /// **'Push B'**
  String get tplPushB;

  /// No description provided for @tplPullA.
  ///
  /// In en, this message translates to:
  /// **'Pull A'**
  String get tplPullA;

  /// No description provided for @tplPullB.
  ///
  /// In en, this message translates to:
  /// **'Pull B'**
  String get tplPullB;

  /// No description provided for @tplLegsA.
  ///
  /// In en, this message translates to:
  /// **'Legs A'**
  String get tplLegsA;

  /// No description provided for @tplLegsB.
  ///
  /// In en, this message translates to:
  /// **'Legs B'**
  String get tplLegsB;

  /// No description provided for @tplFullA.
  ///
  /// In en, this message translates to:
  /// **'Full body A'**
  String get tplFullA;

  /// No description provided for @tplFullB.
  ///
  /// In en, this message translates to:
  /// **'Full body B'**
  String get tplFullB;

  /// No description provided for @tplFullC.
  ///
  /// In en, this message translates to:
  /// **'Full body C'**
  String get tplFullC;

  /// No description provided for @inProgressName.
  ///
  /// In en, this message translates to:
  /// **'{name} in progress'**
  String inProgressName(String name);

  /// No description provided for @resumeSub.
  ///
  /// In en, this message translates to:
  /// **'{time} · {done} of {total} sets'**
  String resumeSub(String time, int done, int total);

  /// No description provided for @discardShort.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardShort;

  /// No description provided for @workoutDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Workout discarded — nothing was saved'**
  String get workoutDiscarded;

  /// No description provided for @routinesSubLib.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 routine} other{{n} routines}} · one per day, or any day'**
  String routinesSubLib(int n);

  /// No description provided for @newShort.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newShort;

  /// No description provided for @folderPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan'**
  String get folderPlan;

  /// No description provided for @folderMine.
  ///
  /// In en, this message translates to:
  /// **'My routines'**
  String get folderMine;

  /// No description provided for @anyDay.
  ///
  /// In en, this message translates to:
  /// **'Any day'**
  String get anyDay;

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every {day}'**
  String everyDay(String day);

  /// No description provided for @routineCardSub.
  ///
  /// In en, this message translates to:
  /// **'{when} · {sets} sets'**
  String routineCardSub(String when, int sets);

  /// No description provided for @addToFolder.
  ///
  /// In en, this message translates to:
  /// **'Add a routine to this folder'**
  String get addToFolder;

  /// No description provided for @myExercises.
  ///
  /// In en, this message translates to:
  /// **'My exercises'**
  String get myExercises;

  /// No description provided for @myExercisesSub.
  ///
  /// In en, this message translates to:
  /// **'{n} in the library · always free'**
  String myExercisesSub(int n);

  /// No description provided for @exploreRoutines.
  ///
  /// In en, this message translates to:
  /// **'Explore routines'**
  String get exploreRoutines;

  /// No description provided for @exploreSub.
  ///
  /// In en, this message translates to:
  /// **'Templates with the set volume already inside the evidence range'**
  String get exploreSub;

  /// No description provided for @optionsFor.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String optionsFor(String name);

  /// No description provided for @startRoutineFull.
  ///
  /// In en, this message translates to:
  /// **'Start routine'**
  String get startRoutineFull;

  /// No description provided for @editRoutineSub.
  ///
  /// In en, this message translates to:
  /// **'Exercises, set counts, rep ranges'**
  String get editRoutineSub;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicateSub.
  ///
  /// In en, this message translates to:
  /// **'A copy you can change without touching this one'**
  String get duplicateSub;

  /// No description provided for @deleteRoutineSub.
  ///
  /// In en, this message translates to:
  /// **'Your logged history stays'**
  String get deleteRoutineSub;

  /// No description provided for @copyName.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String copyName(String name);

  /// No description provided for @duplicated.
  ///
  /// In en, this message translates to:
  /// **'Copied as {name}'**
  String duplicated(String name);

  /// No description provided for @deleteNamed.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteNamed(String name);

  /// No description provided for @keepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get keepIt;

  /// No description provided for @neverRun.
  ///
  /// In en, this message translates to:
  /// **'never run'**
  String get neverRun;

  /// No description provided for @doneOn.
  ///
  /// In en, this message translates to:
  /// **'done {date}'**
  String doneOn(String date);

  /// No description provided for @estDuration.
  ///
  /// In en, this message translates to:
  /// **'Est duration'**
  String get estDuration;

  /// No description provided for @exercisesLbl.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesLbl;

  /// No description provided for @itemLine.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets · {reps} reps @ RIR {rir} · rest {rest}'**
  String itemLine(int sets, String reps, int rir, String rest);

  /// No description provided for @weekEffect.
  ///
  /// In en, this message translates to:
  /// **'What this does to your week'**
  String get weekEffect;

  /// No description provided for @weekIfSave.
  ///
  /// In en, this message translates to:
  /// **'Weekly sets if you save this'**
  String get weekIfSave;

  /// No description provided for @setsWkState.
  ///
  /// In en, this message translates to:
  /// **'sets/wk · {state}'**
  String setsWkState(String state);

  /// No description provided for @inRange.
  ///
  /// In en, this message translates to:
  /// **'in range'**
  String get inRange;

  /// No description provided for @belowRange.
  ///
  /// In en, this message translates to:
  /// **'below range'**
  String get belowRange;

  /// No description provided for @aboveRange.
  ///
  /// In en, this message translates to:
  /// **'above range'**
  String get aboveRange;

  /// No description provided for @volumeNote.
  ///
  /// In en, this message translates to:
  /// **'Counting this routine on top of what the rest of your week already does. Ten to twenty hard sets a muscle a week is where the evidence is strongest — under it you are leaving growth on the table, over it you are mostly buying fatigue.'**
  String get volumeNote;

  /// No description provided for @exLineLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, {sets} sets of {reps}'**
  String exLineLabel(String name, int sets, String reps);

  /// No description provided for @loggedLbl.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get loggedLbl;

  /// No description provided for @startOnItsOwn.
  ///
  /// In en, this message translates to:
  /// **'Start {name} on its own'**
  String startOnItsOwn(String name);

  /// No description provided for @builderSub.
  ///
  /// In en, this message translates to:
  /// **'{n} exercises · {sets} sets · about {min} min'**
  String builderSub(int n, int sets, int min);

  /// No description provided for @nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing in it yet'**
  String get nothingYet;

  /// No description provided for @nameLbl.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLbl;

  /// No description provided for @namePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Push A, Legs heavy, Tuesday…'**
  String get namePlaceholder;

  /// No description provided for @folderLbl.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get folderLbl;

  /// No description provided for @dayLbl.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayLbl;

  /// No description provided for @dayTakenBy.
  ///
  /// In en, this message translates to:
  /// **'{day}, taken by {name}'**
  String dayTakenBy(String day, String name);

  /// No description provided for @dayTaken.
  ///
  /// In en, this message translates to:
  /// **'{name} is already on {day}. Saving this moves that one to Any day.'**
  String dayTaken(String name, String day);

  /// No description provided for @anyDayNote.
  ///
  /// In en, this message translates to:
  /// **'Run it whenever — it stays out of the weekly rotation.'**
  String get anyDayNote;

  /// No description provided for @dayNote.
  ///
  /// In en, this message translates to:
  /// **'Miss it and it moves to your next training day, keeping the block in order.'**
  String get dayNote;

  /// No description provided for @builderEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet. Add the first one and Gymco will show what it does to your weekly set count as you go.'**
  String get builderEmpty;

  /// No description provided for @repsChip.
  ///
  /// In en, this message translates to:
  /// **'{reps} reps'**
  String repsChip(String reps);

  /// No description provided for @restChip.
  ///
  /// In en, this message translates to:
  /// **'rest {t}'**
  String restChip(String t);

  /// No description provided for @oneSetFewer.
  ///
  /// In en, this message translates to:
  /// **'One set fewer'**
  String get oneSetFewer;

  /// No description provided for @oneSetMore.
  ///
  /// In en, this message translates to:
  /// **'One set more'**
  String get oneSetMore;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @repRangeLbl.
  ///
  /// In en, this message translates to:
  /// **'Rep range'**
  String get repRangeLbl;

  /// No description provided for @repRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Rep range · {name}'**
  String repRangeTitle(String name);

  /// No description provided for @repRangeNote.
  ///
  /// In en, this message translates to:
  /// **'Anything from five to thirty reps builds muscle if the set is taken close to failure. Heavier ranges cost more rest and more joints; lighter ones cost more discomfort.'**
  String get repRangeNote;

  /// No description provided for @restBetween.
  ///
  /// In en, this message translates to:
  /// **'Rest between sets · {name}'**
  String restBetween(String name);

  /// No description provided for @restBetweenSub.
  ///
  /// In en, this message translates to:
  /// **'{t} between sets'**
  String restBetweenSub(String t);

  /// No description provided for @restBetweenNote.
  ///
  /// In en, this message translates to:
  /// **'This is what the timer will suggest during the workout. You can still change it set by set once you are in there.'**
  String get restBetweenNote;

  /// No description provided for @removeFromRoutine.
  ///
  /// In en, this message translates to:
  /// **'Remove from routine'**
  String get removeFromRoutine;

  /// No description provided for @hintName.
  ///
  /// In en, this message translates to:
  /// **'Give it a name to save'**
  String get hintName;

  /// No description provided for @hintTaken.
  ///
  /// In en, this message translates to:
  /// **'That name is taken'**
  String get hintTaken;

  /// No description provided for @hintExercise.
  ///
  /// In en, this message translates to:
  /// **'Add at least one exercise'**
  String get hintExercise;

  /// No description provided for @saveRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save routine'**
  String get saveRoutine;

  /// No description provided for @routineSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved'**
  String routineSaved(String name);

  /// No description provided for @leaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving?'**
  String get leaveTitle;

  /// No description provided for @leaveEditing.
  ///
  /// In en, this message translates to:
  /// **'Your changes to {name} will be dropped.'**
  String leaveEditing(String name);

  /// No description provided for @leaveNew.
  ///
  /// In en, this message translates to:
  /// **'This routine has not been saved yet.'**
  String get leaveNew;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @minimise.
  ///
  /// In en, this message translates to:
  /// **'Minimise workout'**
  String get minimise;

  /// No description provided for @restTimer.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get restTimer;

  /// No description provided for @offLbl.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get offLbl;

  /// No description provided for @notePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a note — cue, machine setting, how it felt'**
  String get notePlaceholder;

  /// No description provided for @setH.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setH;

  /// No description provided for @rirLbl.
  ///
  /// In en, this message translates to:
  /// **'RIR'**
  String get rirLbl;

  /// No description provided for @completeSet.
  ///
  /// In en, this message translates to:
  /// **'Complete set {n}'**
  String completeSet(String n);

  /// No description provided for @setTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Set type: {type}'**
  String setTypeLabel(String type);

  /// No description provided for @supersetBadge.
  ///
  /// In en, this message translates to:
  /// **'Superset · no rest between'**
  String get supersetBadge;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @supersetNote.
  ///
  /// In en, this message translates to:
  /// **'The timer only starts once the pair is done. Both count as full sets for their own muscles.'**
  String get supersetNote;

  /// No description provided for @emptyWorkoutBody.
  ///
  /// In en, this message translates to:
  /// **'Empty workout. The clock is already running — add the first exercise whenever you are ready.'**
  String get emptyWorkoutBody;

  /// No description provided for @restAfterEachTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest after each set · {name}'**
  String restAfterEachTitle(String name);

  /// No description provided for @restNote.
  ///
  /// In en, this message translates to:
  /// **'Three minutes or more for heavy compounds — shorter rest costs you reps, and reps are the stimulus.'**
  String get restNote;

  /// No description provided for @restAfterEach.
  ///
  /// In en, this message translates to:
  /// **'{t} after each set'**
  String restAfterEach(String t);

  /// No description provided for @restOffFor.
  ///
  /// In en, this message translates to:
  /// **'Off for this exercise'**
  String get restOffFor;

  /// No description provided for @supersetNext.
  ///
  /// In en, this message translates to:
  /// **'Superset with the next exercise'**
  String get supersetNext;

  /// No description provided for @supersetNextSub.
  ///
  /// In en, this message translates to:
  /// **'No rest between the two'**
  String get supersetNextSub;

  /// No description provided for @seeHistory.
  ///
  /// In en, this message translates to:
  /// **'See history and 1RM'**
  String get seeHistory;

  /// No description provided for @removeFromWorkout.
  ///
  /// In en, this message translates to:
  /// **'Remove from this workout'**
  String get removeFromWorkout;

  /// No description provided for @removedFromWorkout.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from this workout'**
  String removedFromWorkout(String name);

  /// No description provided for @nothingAfter.
  ///
  /// In en, this message translates to:
  /// **'Nothing after this one to pair with'**
  String get nothingAfter;

  /// No description provided for @supersetted.
  ///
  /// In en, this message translates to:
  /// **'Supersetted — the timer waits for both'**
  String get supersetted;

  /// No description provided for @exAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String exAdded(String name);

  /// No description provided for @resting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get resting;

  /// No description provided for @restingFor.
  ///
  /// In en, this message translates to:
  /// **'Resting, {t} left'**
  String restingFor(String t);

  /// No description provided for @nextSetOf.
  ///
  /// In en, this message translates to:
  /// **'Next: {name}, set {n}'**
  String nextSetOf(String name, int n);

  /// No description provided for @lastSetDone.
  ///
  /// In en, this message translates to:
  /// **'Last set done'**
  String get lastSetDone;

  /// No description provided for @minus15.
  ///
  /// In en, this message translates to:
  /// **'−15s'**
  String get minus15;

  /// No description provided for @setRemoved.
  ///
  /// In en, this message translates to:
  /// **'Set removed'**
  String get setRemoved;

  /// No description provided for @rirTitle.
  ///
  /// In en, this message translates to:
  /// **'Reps in reserve'**
  String get rirTitle;

  /// No description provided for @rirNote.
  ///
  /// In en, this message translates to:
  /// **'How many more you could have done with good form.'**
  String get rirNote;

  /// No description provided for @editSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set {n} · {name}'**
  String editSetTitle(String n, String name);

  /// No description provided for @lastTimeSet.
  ///
  /// In en, this message translates to:
  /// **'Last time: {set}'**
  String lastTimeSet(String set);

  /// No description provided for @nothingTicked.
  ///
  /// In en, this message translates to:
  /// **'Nothing was ticked, so nothing was saved'**
  String get nothingTicked;

  /// No description provided for @setsUnticked.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 set was left unticked — it is not in the log} other{{n} sets were left unticked — they are not in the log}}'**
  String setsUnticked(int n);

  /// No description provided for @doneTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — done'**
  String doneTitle(String name);

  /// No description provided for @volumeExplain.
  ///
  /// In en, this message translates to:
  /// **'Volume is every completed working set multiplied out. Warm-ups are in the log but not in this number, and not in your weekly set count either.'**
  String get volumeExplain;

  /// No description provided for @prLbl.
  ///
  /// In en, this message translates to:
  /// **'PR'**
  String get prLbl;

  /// No description provided for @insightIn.
  ///
  /// In en, this message translates to:
  /// **'{group} is at {sets} this week — inside the 10–20 range where the evidence is strongest. Nothing to change.'**
  String insightIn(String group, String sets);

  /// No description provided for @insightUnder.
  ///
  /// In en, this message translates to:
  /// **'{group} is at {sets} this week — under the 10–20 range. Another session or two would put it there.'**
  String insightUnder(String group, String sets);

  /// No description provided for @insightOver.
  ///
  /// In en, this message translates to:
  /// **'{group} is at {sets} this week — above 20. Past that point it is mostly fatigue.'**
  String insightOver(String group, String sets);

  /// No description provided for @saveAsRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save as routine'**
  String get saveAsRoutine;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'{name} · {time} · {volume} · {sets} hard sets'**
  String shareText(String name, String time, String volume, String sets);

  /// No description provided for @soloLogged.
  ///
  /// In en, this message translates to:
  /// **'{name} logged — the rest of the day is still there'**
  String soloLogged(String name);

  /// No description provided for @est1rm.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM'**
  String get est1rm;

  /// No description provided for @trendKg.
  ///
  /// In en, this message translates to:
  /// **'{delta} kg / {w} wk'**
  String trendKg(String delta, int w);

  /// No description provided for @months6.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get months6;

  /// No description provided for @chartNeedsTwo.
  ///
  /// In en, this message translates to:
  /// **'Two workouts with this lift and the trend line starts.'**
  String get chartNeedsTwo;

  /// No description provided for @best5.
  ///
  /// In en, this message translates to:
  /// **'Best 5 reps'**
  String get best5;

  /// No description provided for @best8.
  ///
  /// In en, this message translates to:
  /// **'Best 8 reps'**
  String get best8;

  /// No description provided for @setsWk.
  ///
  /// In en, this message translates to:
  /// **'Sets / wk'**
  String get setsWk;

  /// No description provided for @exClimbing.
  ///
  /// In en, this message translates to:
  /// **'This lift is still climbing. Whatever you are doing with the deficit, it is tolerable — no reason to slow down yet.'**
  String get exClimbing;

  /// No description provided for @exFlat.
  ///
  /// In en, this message translates to:
  /// **'Holding steady. In a deficit, holding is winning.'**
  String get exFlat;

  /// No description provided for @exDropping.
  ///
  /// In en, this message translates to:
  /// **'Down from where it was eight weeks ago. Check sleep and the size of the deficit before blaming the program.'**
  String get exDropping;

  /// No description provided for @exNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet. Log it once and its 1RM trend starts here.'**
  String get exNoHistory;

  /// No description provided for @historyLbl.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyLbl;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @addAnExercise.
  ///
  /// In en, this message translates to:
  /// **'Add an exercise'**
  String get addAnExercise;

  /// No description provided for @searchLibrary.
  ///
  /// In en, this message translates to:
  /// **'Search the exercise library'**
  String get searchLibrary;

  /// No description provided for @noExerciseMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches. Try a shorter word, or another muscle.'**
  String get noExerciseMatch;

  /// No description provided for @inLbl.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inLbl;

  /// No description provided for @alreadyIn.
  ///
  /// In en, this message translates to:
  /// **'Already in this workout'**
  String get alreadyIn;

  /// No description provided for @thenEx.
  ///
  /// In en, this message translates to:
  /// **'Then: {name}'**
  String thenEx(String name);
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
