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
  String get obGoalTitle => 'What are you training for?';

  @override
  String get goalCut => 'Cut';

  @override
  String get goalCutSub => 'Lose fat, hold on to muscle and strength';

  @override
  String get goalMaintain => 'Maintain';

  @override
  String get goalMaintainSub => 'Hold weight and keep logging honestly';

  @override
  String get goalBulk => 'Lean bulk';

  @override
  String get goalBulkSub => 'Add size at 0.25–0.5% of body weight a week';

  @override
  String get obBodyTitle => 'About you';

  @override
  String get obBodyBody => 'Used to seed week one only. After 14 days your real expenditure takes over.';

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
      'An estimate, not a verdict. After two or three weeks of logging, Gymco replaces it with your measured expenditure.';

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
    return 'You already have a routine called $name. Pick another name or edit that one.';
  }

  @override
  String get deleteRoutine => 'Delete routine';

  @override
  String get deleteRoutineTitle => 'Delete this routine?';

  @override
  String get deleteRoutineBody =>
      'The routine goes. Every workout you already logged from it stays in your history, with its sets and PRs.';

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
  String get durationLbl => 'Duration';

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
  String get stWarmupSub => 'Does not count toward weekly sets';

  @override
  String get stNormal => 'Normal';

  @override
  String get stNormalSub => 'A hard working set';

  @override
  String get stFailure => 'Failure';

  @override
  String get stFailureSub => 'Taken to technical failure';

  @override
  String get stDrop => 'Drop set';

  @override
  String get stDropSub => 'Counts as half a set';

  @override
  String get removeSet => 'Remove this set';

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

  @override
  String get about => 'about';

  @override
  String get actSitting => 'Mostly sitting';

  @override
  String get actSittingSub => 'Desk job, under 5,000 steps';

  @override
  String get actFeet => 'On my feet';

  @override
  String get actFeetSub => 'Walking a lot, 5,000–10,000 steps';

  @override
  String get actPhysical => 'Physical job';

  @override
  String get actPhysicalSub => 'Lifting or carrying most of the day';

  @override
  String get actVery => 'Very active';

  @override
  String get actVerySub => 'Over 12,000 steps or a second sport';

  @override
  String get addFoodToMeal => 'Add food to this meal';

  @override
  String get addNoWeighing => 'Add what you ate — no weighing';

  @override
  String get addWater => 'Add 250 ml of water';

  @override
  String get agreeToContinue => 'Agree to continue';

  @override
  String get backToToday => 'Back to today';

  @override
  String get calorieFloor => 'Calorie floor';

  @override
  String get cheatAllowanceNote =>
      'Nothing is ever paid back with cardio. A banked meal takes a slice off the days before it; a free one is simply not logged.';

  @override
  String get chooseRoutine => 'Choose a routine';

  @override
  String get cm => 'cm';

  @override
  String get consentHealth =>
      'I agree to Gymco storing my weight, measurements and food logs as health data on this phone, to calculate my targets.';

  @override
  String get copiedToToday => 'Copied to today';

  @override
  String get copyToToday => 'Copy to today';

  @override
  String get createdByYou => 'created by you';

  @override
  String get custom => 'Custom';

  @override
  String get customFood => 'Custom food';

  @override
  String get deleteDigit => 'Delete last digit';

  @override
  String get emptyMeal => 'Empty meal';

  @override
  String get firstRunTip =>
      'Most people log the same eight or ten things. Build those once and a day takes about twenty seconds.';

  @override
  String get floorBody =>
      'Targets are never set below this. Going lower means typing the number yourself, after a warning.';

  @override
  String get floorSub => 'kcal · your floor';

  @override
  String get followsPhone => 'Follows your phone';

  @override
  String get freeAlways => 'free, always';

  @override
  String get genericUsda => 'Generic · USDA';

  @override
  String get genericUsdaVerified => 'Generic · USDA · verified';

  @override
  String get goalAndTargets => 'Goal and targets';

  @override
  String get goalRecomp => 'Recomposition';

  @override
  String get goalRecompSub => 'Sit near maintenance; watch the waist, not the scale';

  @override
  String get goalPrep => 'Contest prep';

  @override
  String get goalPrepSub => 'Work backwards from a stage date';

  @override
  String get goalShortCut => 'cut';

  @override
  String get goalShortBulk => 'lean bulk';

  @override
  String get goalShortRecomp => 'recomp';

  @override
  String get goalShortMaintain => 'maintain';

  @override
  String get goalShortPrep => 'contest prep';

  @override
  String get habitMealsNone => 'Meals logged, none skipped';

  @override
  String get habitProteinEach => 'A protein source at each one';

  @override
  String get habitTrained => 'Trained today';

  @override
  String get habitsHiddenBody =>
      'Your entries are still saved. Nothing is being scored, and no target is tracked against you.';

  @override
  String get habitsHiddenTitle => 'Calories, macros and weight are hidden';

  @override
  String get heightLbl => 'Height';

  @override
  String get heroDoneBody => 'Logged and saved. Recovery is where it turns into the next one.';

  @override
  String get heroExercises => 'exercises';

  @override
  String get heroMin => 'min';

  @override
  String get heroMuscles => 'muscles';

  @override
  String get heroRestBody => 'Nothing scheduled today. Recovery is where the last session turns into the next one.';

  @override
  String get heroRestTitle => 'Rest <em>day</em>';

  @override
  String get heroSets => 'sets';

  @override
  String get heroSetupBody => 'Pick a split or build your own. Gymco schedules it and tracks every set.';

  @override
  String get heroSetupTitle => 'Set up your <em>training</em>';

  @override
  String get heroTagDone => 'Done today';

  @override
  String get heroTagInProgress => 'In progress';

  @override
  String get heroTagToday => 'Today’s workout';

  @override
  String get howTodayWent => 'How today went';

  @override
  String get inThisMeal => 'In this meal';

  @override
  String get kcalADay => 'kcal a day';

  @override
  String get kcalLeftLabel => 'kcal left';

  @override
  String get kcalLoggedLabel => 'kcal logged';

  @override
  String get kcalOverLabel => 'kcal past target';

  @override
  String get kcalToLog => 'kcal to log';

  @override
  String get keepThemHidden => 'Keep them hidden';

  @override
  String get langArabicSub => 'Arabic · right-to-left';

  @override
  String get langEnglishSub => 'English';

  @override
  String get langSpanishSub => 'Spanish';

  @override
  String get logFirstMeal => 'Log your first meal';

  @override
  String get logNoWeighing => 'Log what you ate — no weighing';

  @override
  String get mBarcode => 'Barcode';

  @override
  String get mPhoto => 'Photo';

  @override
  String get mSearch => 'Search';

  @override
  String get mVoice => 'Voice';

  @override
  String get mWrite => 'Write';

  @override
  String get mealDetailTip => 'Tap an item to change its portion. Anything you remove leaves today straight away.';

  @override
  String get mealLabel => 'Meal';

  @override
  String get myMeals => 'My meals';

  @override
  String get noMatchBody => 'Home cooking rarely is. Scan the pack, or try another word.';

  @override
  String get noMatchTitle => 'No match in the database';

  @override
  String get noNumbersOfferLine =>
      'Rather not see numbers? No-numbers mode hides calories, macros and weight, and tracks habits instead.';

  @override
  String get noNumbersOn => 'On — calories and weight hidden';

  @override
  String get noSessionPlanned => 'No session planned';

  @override
  String get nothingInMeal => 'Nothing in this meal yet';

  @override
  String get nothingYesterdayDay => 'Nothing was logged yesterday';

  @override
  String get numbersHidden => 'Numbers hidden';

  @override
  String get obActivityTitleEm => 'How do you <em>move</em> on a normal day?';

  @override
  String get obBodyTitleEm => 'A bit about <em>you</em>';

  @override
  String get obGoalBody =>
      'This sets your rate, protein floor and how the coach reads your data. You can change it any week.';

  @override
  String get obRateBodyGain =>
      'Slow is lean. A quarter to half a percent of body weight a week keeps the gain mostly muscle.';

  @override
  String get obRateBodyLose =>
      'Faster is not better. Between 0.5 and 1% of body weight a week is where muscle retention holds up.';

  @override
  String get obRateTitleGain => 'How fast do you want to gain?';

  @override
  String get obRateTitleLose => 'How fast do you want to lose?';

  @override
  String get pastNoteWithin => 'Within a hundred of target. Days like this are what move the trend line.';

  @override
  String get pctPerWeek => '% / week';

  @override
  String get rateHot =>
      'Above 0.85%/week you start paying in muscle. Gymco will keep saying so, every week, until you slow down.';

  @override
  String get rateOkGain => 'Slow enough that most of the gain is muscle.';

  @override
  String get rateOkLose =>
      'In the range Helms et al. (2014) recommend for natural lifters holding muscle through a deficit.';

  @override
  String get readyToLog => 'ready to log';

  @override
  String get recipes => 'Recipes';

  @override
  String get restDay => 'Rest day';

  @override
  String get ringEmptyBody => 'Nothing logged yet. Your targets are set — the ring fills as you go.';

  @override
  String get rtlNote => 'Arabic flips the whole app to right-to-left, including the week strip and swipe directions.';

  @override
  String get safeguards => 'Safeguards';

  @override
  String get savedSeeTrain => 'Saved · see it in Train';

  @override
  String get scanABarcode => 'Scan a barcode';

  @override
  String get scanBarcodeSub => 'Packaged food resolves straight to the pack’s own numbers';

  @override
  String get searchDatabase => 'Search the database';

  @override
  String get searchOtherLanguage =>
      'Searching in another language often finds more — Gymco keeps every name it learns on the same food.';

  @override
  String get seeTheWeek => 'See the week';

  @override
  String get settings => 'Settings';

  @override
  String get sexForEquation => 'Sex for the energy equation';

  @override
  String get startLogging => 'Start logging';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get supportBody => 'Support lines and services near you';

  @override
  String get supportTitle => 'Talking to someone helps';

  @override
  String get swipeToStart => 'Swipe to start';

  @override
  String get targetsSaved => 'Targets saved — start logging';

  @override
  String get theRemainder => 'the remainder';

  @override
  String get todayPlain => 'Today';

  @override
  String get todayTitleEm => 'Make it <em>count</em>';

  @override
  String get training => 'Training';

  @override
  String get trainingCountedSeparately => 'Training is counted separately. Don’t include the gym here.';

  @override
  String get trendNeedsDays => 'A trend needs about seven days';

  @override
  String get trendWeight => 'Trend weight';

  @override
  String get unitsLanguage => 'Units & language';

  @override
  String get usuallyNow => 'You usually eat around now';

  @override
  String get water => 'Water';

  @override
  String get waterAdded => '250 ml added';

  @override
  String get weightToday => 'Weight today';

  @override
  String get welcomeArtAlt => 'A woman mid kettlebell swing';

  @override
  String get welcomeBody => 'Log food in seconds, train with a plan, and keep a streak worth protecting.';

  @override
  String get welcomeTitleEm => 'Start your <em>fitness</em> journey today';

  @override
  String get yesterdayCopied => 'Yesterday copied in';

  @override
  String get yrs => 'yrs';

  @override
  String addKcal(String kcal) {
    return 'Add $kcal kcal';
  }

  @override
  String saveKcal(String kcal) {
    return 'Save · $kcal kcal';
  }

  @override
  String addToMeal(String meal) {
    return 'Add to $meal';
  }

  @override
  String closedDay(String date) {
    return '$date · closed day';
  }

  @override
  String floorNote(String kcal) {
    return 'Your targets will never be set below $kcal kcal.';
  }

  @override
  String foodAdded(String food) {
    return '$food added';
  }

  @override
  String foodRemoved(String food) {
    return '$food removed';
  }

  @override
  String removeFood(String food) {
    return 'Remove $food';
  }

  @override
  String gPerKg(String g) {
    return '$g g/kg';
  }

  @override
  String heroDoneTitle(String name) {
    return '$name <em>done</em>';
  }

  @override
  String heroWeekTag(int n) {
    return 'Week $n';
  }

  @override
  String itemsLoggedTo(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items logged to $meal',
      one: '1 item logged to $meal',
    );
    return '$_temp0';
  }

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items selected',
      one: '1 item selected',
    );
    return '$_temp0';
  }

  @override
  String kcalAndProtein(String kcal, String p) {
    return '$kcal kcal · $p g protein';
  }

  @override
  String leftToday(String kcal, String p) {
    return '$kcal kcal and $p g protein left today';
  }

  @override
  String litres(String l) {
    return '$l L';
  }

  @override
  String logN(int n) {
    return 'Log $n';
  }

  @override
  String maxPct(String pct) {
    return '$pct max';
  }

  @override
  String meSub(String goal, int week) {
    return '$goal, week $week';
  }

  @override
  String moreCount(int n) {
    return '+$n more';
  }

  @override
  String ofTarget(String n) {
    return '/ $n g';
  }

  @override
  String oneServing(String g) {
    return '1 serving · $g g';
  }

  @override
  String pastNoteOver(String n) {
    return '$n over target — one day, and the weekly average is what the maths reads.';
  }

  @override
  String pastNoteUnder(String n) {
    return '$n under target. Fine once; a habit of it is how you lose more than fat.';
  }

  @override
  String ratePerWeekShort(String pct) {
    return '$pct %/wk';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count results', one: '1 result');
    return '$_temp0';
  }

  @override
  String resumeAt(String time) {
    return 'Resume · $time';
  }

  @override
  String setTo(String food, String g) {
    return '$food set to $g g';
  }

  @override
  String shareOfToday(int pct) {
    return '$pct% of today';
  }

  @override
  String targetsHow(String mult, String rate) {
    return 'Mifflin-St Jeor × $mult, then your chosen rate of $rate%/week. Everything here is editable.';
  }

  @override
  String targetsHowMaintain(String mult) {
    return 'Mifflin-St Jeor × $mult, at maintenance. Everything here is editable.';
  }

  @override
  String targetsLine(String p, String c, String f) {
    return 'Protein $p g · Carbs $c g · Fat $f g';
  }

  @override
  String todaySub(String date, String goal, int week) {
    return '$date · $goal, week $week';
  }

  @override
  String todaySubDayOne(String date) {
    return '$date · day 1';
  }

  @override
  String weighInsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weigh-ins so far',
      one: 'One weigh-in so far',
      zero: 'No weigh-ins yet',
    );
    return '$_temp0';
  }

  @override
  String whatDidYouHave(String meal) {
    return 'What did you have for $meal?';
  }

  @override
  String get mealOptions => 'Meal options';

  @override
  String get saveAsMeal => 'Save as a meal';

  @override
  String get savedToMyMeals => 'Saved — find it under My meals';

  @override
  String get copyToTomorrow => 'Copy to tomorrow';

  @override
  String get copiedToTomorrow => 'Copied to tomorrow';

  @override
  String get clearMeal => 'Clear this meal';

  @override
  String lastLogged(String time) {
    return 'Last logged $time';
  }

  @override
  String get saveToFavourites => 'Save to favourites';

  @override
  String get savedToFavourites => 'Saved to favourites';

  @override
  String get removedFromFavourites => 'Removed from favourites';

  @override
  String get saveAsCustom => 'Save as custom';

  @override
  String get savedAsCustom => 'Saved as a custom food';

  @override
  String labelVerifiedOff(String brand) {
    return '$brand · label verified · Open Food Facts';
  }

  @override
  String get noSavedMeals => 'No saved meals yet. Open a meal you eat often and tap Save as a meal.';

  @override
  String get noCustomFoods => 'No custom foods yet. Open any food and tap Save as custom to keep your own copy.';

  @override
  String get recipesSoon => 'Recipes are next: build one from ingredients, split it into portions, log a portion.';

  @override
  String savedMealSub(int count, String kcal) {
    return '$count items · $kcal kcal';
  }

  @override
  String loggedSavedMeal(String name) {
    return '$name logged';
  }

  @override
  String get yourData => 'Your data';

  @override
  String get yourDataSub => 'Export, consents, delete everything';

  @override
  String get takeEverything => 'Take everything with you';

  @override
  String get takeEverythingSub => 'CSV and JSON, every table';

  @override
  String foodLogRows(String n) {
    return 'Food log · $n rows';
  }

  @override
  String weighInsCount(String n) {
    return 'Weigh-ins · $n';
  }

  @override
  String get exportNow => 'Export now';

  @override
  String get exportFailed => 'Couldn\'t export — try again';

  @override
  String get whatYouAgreed => 'What you agreed to, and when';

  @override
  String get consentHealthRow => 'Health data processing · v1';

  @override
  String get consentAnalyticsRow => 'Anonymous analytics · none collected';

  @override
  String get onPhoneNote =>
      'Everything lives on this phone. There is no account and no server, so nothing leaves it unless you export it.';

  @override
  String get deleteEverything => 'Delete everything';

  @override
  String get deleteEverythingSub => 'One tap, then one confirmation';

  @override
  String get deleteEverythingBody =>
      'Your log, workouts, routines, weigh-ins and targets go at once. Export first if you want your history — it cannot be recovered afterwards.';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteConfirmTitle => 'Delete everything?';

  @override
  String get deleteConfirm => 'Yes, delete it all';

  @override
  String get keepMyData => 'Keep my data';

  @override
  String dataSetsCount(String n) {
    return 'Sets · $n';
  }

  @override
  String get setMacrosManually => 'Set my macros manually';

  @override
  String get useTheseMacros => 'Use these macros';

  @override
  String get backToCalculated => 'Back to the calculated split';

  @override
  String manualKcal(String kcal) {
    return 'That comes to $kcal kcal a day.';
  }

  @override
  String manualBelowFloor(String kcal, String floor) {
    return 'That comes to $kcal kcal — under the $floor kcal floor. Only go there with someone qualified watching.';
  }

  @override
  String projectedKg(String kg) {
    return 'Projected $kg kg';
  }

  @override
  String aroundDate(String date) {
    return 'around $date';
  }

  @override
  String inWeeks(int n) {
    return 'in $n weeks';
  }

  @override
  String moreOf(String what) {
    return 'More $what';
  }

  @override
  String lessOf(String what) {
    return 'Less $what';
  }

  @override
  String get trainTitleEm => 'Train <em>hard</em>';

  @override
  String trainSub(int days, int week) {
    return '$days days a week · week $week';
  }

  @override
  String get noWeeklyPlan => 'No weekly plan yet';

  @override
  String dayAhead(String date) {
    return '$date · ahead';
  }

  @override
  String dayClosed(String date) {
    return '$date · closed';
  }

  @override
  String get todayLbl => 'Today';

  @override
  String plannedOn(String day) {
    return 'Planned · $day';
  }

  @override
  String movedHere(String day) {
    return 'Moved here · was $day';
  }

  @override
  String loggedOfPlanned(int done, int total, int sets) {
    return '$done of $total logged · $sets sets planned';
  }

  @override
  String setsAbout(int sets, int min) {
    return '$sets sets · about $min min';
  }

  @override
  String get startEarly => 'Start early';

  @override
  String get startAll => 'Start all';

  @override
  String get startEarlyNote =>
      'Starting it early moves the rest of the week up with it — the block keeps its order, not its dates.';

  @override
  String get lastTimeRan => 'Last time you ran it';

  @override
  String get somethingElse => 'Something else instead';

  @override
  String restMissed(String name) {
    return '$name was due and nothing was logged. It moved to the next day you train — the week slides, the order holds.';
  }

  @override
  String restAhead(String day) {
    return 'Nothing scheduled. $day is one of the days off this week.';
  }

  @override
  String get restPast =>
      'Nothing was logged, and nothing was due. Recovery is where the last session turns into the next one.';

  @override
  String get nextSession => 'Next session';

  @override
  String get sessionAfter => 'The session after';

  @override
  String get logAnyway => 'Log something anyway';

  @override
  String get allRoutines => 'All routines';

  @override
  String allRoutinesSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n routines', one: '1 routine');
    return '$_temp0 · your exercise library';
  }

  @override
  String weeklySetsOf(String group) {
    return 'Weekly sets · $group';
  }

  @override
  String hardSetsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n hard sets', one: '1 hard set');
    return '$_temp0';
  }

  @override
  String get zoneIn => 'in the productive zone';

  @override
  String get zoneUnder => 'below the productive zone';

  @override
  String get zoneOver => 'above the productive zone';

  @override
  String get gBack => 'Back';

  @override
  String get gLegs => 'Legs';

  @override
  String get gCore => 'Core';

  @override
  String get closedLbl => 'Closed';

  @override
  String get hardSetsLbl => 'Hard sets';

  @override
  String get bestSetEach => 'Best set of each exercise';

  @override
  String runAgain(String name) {
    return 'Run $name again';
  }

  @override
  String get trainEmptyBody => 'Nothing here yet. Start from a proven template, or build exactly what you already do.';

  @override
  String get startEmptyWorkout => 'Start an empty workout';

  @override
  String get startEmptySub => 'Add exercises as you go — it becomes a routine after';

  @override
  String get buildOwn => 'Build my own routine';

  @override
  String get buildOwnSub => 'Unlimited routines, free';

  @override
  String get orTemplate => 'Or start from a template';

  @override
  String get tplUL => 'Upper / Lower, 4 days';

  @override
  String get tplULSub => '12–18 sets per muscle a week · intermediate';

  @override
  String get tplPPL => 'Push / Pull / Legs, 6 days';

  @override
  String get tplPPLSub => 'High frequency · advanced';

  @override
  String get tplFB => 'Full body, 3 days';

  @override
  String get tplFBSub => 'The one to pick while cutting · any level';

  @override
  String templateAdded(String name) {
    return '$name added to your weekly plan';
  }

  @override
  String get tplUpperA => 'Upper A';

  @override
  String get tplUpperB => 'Upper B';

  @override
  String get tplLowerA => 'Lower A';

  @override
  String get tplLowerB => 'Lower B';

  @override
  String get tplPushA => 'Push A';

  @override
  String get tplPushB => 'Push B';

  @override
  String get tplPullA => 'Pull A';

  @override
  String get tplPullB => 'Pull B';

  @override
  String get tplLegsA => 'Legs A';

  @override
  String get tplLegsB => 'Legs B';

  @override
  String get tplFullA => 'Full body A';

  @override
  String get tplFullB => 'Full body B';

  @override
  String get tplFullC => 'Full body C';

  @override
  String inProgressName(String name) {
    return '$name in progress';
  }

  @override
  String resumeSub(String time, int done, int total) {
    return '$time · $done of $total sets';
  }

  @override
  String get discardShort => 'Discard';

  @override
  String get workoutDiscarded => 'Workout discarded — nothing was saved';

  @override
  String routinesSubLib(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n routines', one: '1 routine');
    return '$_temp0 · one per day, or any day';
  }

  @override
  String get newShort => 'New';

  @override
  String get folderPlan => 'Weekly plan';

  @override
  String get folderMine => 'My routines';

  @override
  String get anyDay => 'Any day';

  @override
  String everyDay(String day) {
    return 'Every $day';
  }

  @override
  String routineCardSub(String when, int sets) {
    return '$when · $sets sets';
  }

  @override
  String get addToFolder => 'Add a routine to this folder';

  @override
  String get myExercises => 'My exercises';

  @override
  String myExercisesSub(int n) {
    return '$n in the library · always free';
  }

  @override
  String get exploreRoutines => 'Explore routines';

  @override
  String get exploreSub => 'Templates with the set volume already inside the evidence range';

  @override
  String optionsFor(String name) {
    return 'Options for $name';
  }

  @override
  String get startRoutineFull => 'Start routine';

  @override
  String get editRoutineSub => 'Exercises, set counts, rep ranges';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get duplicateSub => 'A copy you can change without touching this one';

  @override
  String get deleteRoutineSub => 'Your logged history stays';

  @override
  String copyName(String name) {
    return '$name copy';
  }

  @override
  String duplicated(String name) {
    return 'Copied as $name';
  }

  @override
  String deleteNamed(String name) {
    return 'Delete $name?';
  }

  @override
  String get keepIt => 'Keep it';

  @override
  String get neverRun => 'never run';

  @override
  String doneOn(String date) {
    return 'done $date';
  }

  @override
  String get estDuration => 'Est duration';

  @override
  String get exercisesLbl => 'Exercises';

  @override
  String itemLine(int sets, String reps, int rir, String rest) {
    return '$sets sets · $reps reps @ RIR $rir · rest $rest';
  }

  @override
  String get weekEffect => 'What this does to your week';

  @override
  String get weekIfSave => 'Weekly sets if you save this';

  @override
  String setsWkState(String state) {
    return 'sets/wk · $state';
  }

  @override
  String get inRange => 'in range';

  @override
  String get belowRange => 'below range';

  @override
  String get aboveRange => 'above range';

  @override
  String get volumeNote =>
      'Counting this routine on top of what the rest of your week already does. Ten to twenty hard sets a muscle a week is where the evidence is strongest — under it you are leaving growth on the table, over it you are mostly buying fatigue.';

  @override
  String exLineLabel(String name, int sets, String reps) {
    return '$name, $sets sets of $reps';
  }

  @override
  String get loggedLbl => 'Logged';

  @override
  String startOnItsOwn(String name) {
    return 'Start $name on its own';
  }

  @override
  String builderSub(int n, int sets, int min) {
    return '$n exercises · $sets sets · about $min min';
  }

  @override
  String get nothingYet => 'Nothing in it yet';

  @override
  String get nameLbl => 'Name';

  @override
  String get namePlaceholder => 'Push A, Legs heavy, Tuesday…';

  @override
  String get folderLbl => 'Folder';

  @override
  String get dayLbl => 'Day';

  @override
  String dayTakenBy(String day, String name) {
    return '$day, taken by $name';
  }

  @override
  String dayTaken(String name, String day) {
    return '$name is already on $day. Saving this moves that one to Any day.';
  }

  @override
  String get anyDayNote => 'Run it whenever — it stays out of the weekly rotation.';

  @override
  String get dayNote => 'Miss it and it moves to your next training day, keeping the block in order.';

  @override
  String get builderEmpty =>
      'No exercises yet. Add the first one and Gymco will show what it does to your weekly set count as you go.';

  @override
  String repsChip(String reps) {
    return '$reps reps';
  }

  @override
  String restChip(String t) {
    return 'rest $t';
  }

  @override
  String get oneSetFewer => 'One set fewer';

  @override
  String get oneSetMore => 'One set more';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get repRangeLbl => 'Rep range';

  @override
  String repRangeTitle(String name) {
    return 'Rep range · $name';
  }

  @override
  String get repRangeNote =>
      'Anything from five to thirty reps builds muscle if the set is taken close to failure. Heavier ranges cost more rest and more joints; lighter ones cost more discomfort.';

  @override
  String restBetween(String name) {
    return 'Rest between sets · $name';
  }

  @override
  String restBetweenSub(String t) {
    return '$t between sets';
  }

  @override
  String get restBetweenNote =>
      'This is what the timer will suggest during the workout. You can still change it set by set once you are in there.';

  @override
  String get removeFromRoutine => 'Remove from routine';

  @override
  String get hintName => 'Give it a name to save';

  @override
  String get hintTaken => 'That name is taken';

  @override
  String get hintExercise => 'Add at least one exercise';

  @override
  String get saveRoutine => 'Save routine';

  @override
  String routineSaved(String name) {
    return '$name saved';
  }

  @override
  String get leaveTitle => 'Leave without saving?';

  @override
  String leaveEditing(String name) {
    return 'Your changes to $name will be dropped.';
  }

  @override
  String get leaveNew => 'This routine has not been saved yet.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get minimise => 'Minimise workout';

  @override
  String get restTimer => 'Rest timer';

  @override
  String get offLbl => 'Off';

  @override
  String get notePlaceholder => 'Add a note — cue, machine setting, how it felt';

  @override
  String get setH => 'Set';

  @override
  String get rirLbl => 'RIR';

  @override
  String completeSet(String n) {
    return 'Complete set $n';
  }

  @override
  String setTypeLabel(String type) {
    return 'Set type: $type';
  }

  @override
  String get supersetBadge => 'Superset · no rest between';

  @override
  String get unlink => 'Unlink';

  @override
  String get supersetNote =>
      'The timer only starts once the pair is done. Both count as full sets for their own muscles.';

  @override
  String get emptyWorkoutBody =>
      'Empty workout. The clock is already running — add the first exercise whenever you are ready.';

  @override
  String restAfterEachTitle(String name) {
    return 'Rest after each set · $name';
  }

  @override
  String get restNote =>
      'Three minutes or more for heavy compounds — shorter rest costs you reps, and reps are the stimulus.';

  @override
  String restAfterEach(String t) {
    return '$t after each set';
  }

  @override
  String get restOffFor => 'Off for this exercise';

  @override
  String get supersetNext => 'Superset with the next exercise';

  @override
  String get supersetNextSub => 'No rest between the two';

  @override
  String get seeHistory => 'See history and 1RM';

  @override
  String get removeFromWorkout => 'Remove from this workout';

  @override
  String removedFromWorkout(String name) {
    return '$name removed from this workout';
  }

  @override
  String get nothingAfter => 'Nothing after this one to pair with';

  @override
  String get supersetted => 'Supersetted — the timer waits for both';

  @override
  String exAdded(String name) {
    return '$name added';
  }

  @override
  String get resting => 'Resting';

  @override
  String restingFor(String t) {
    return 'Resting, $t left';
  }

  @override
  String nextSetOf(String name, int n) {
    return 'Next: $name, set $n';
  }

  @override
  String get lastSetDone => 'Last set done';

  @override
  String get minus15 => '−15s';

  @override
  String get setRemoved => 'Set removed';

  @override
  String get rirTitle => 'Reps in reserve';

  @override
  String get rirNote => 'How many more you could have done with good form.';

  @override
  String editSetTitle(String n, String name) {
    return 'Set $n · $name';
  }

  @override
  String lastTimeSet(String set) {
    return 'Last time: $set';
  }

  @override
  String get nothingTicked => 'Nothing was ticked, so nothing was saved';

  @override
  String setsUnticked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sets were left unticked — they are not in the log',
      one: '1 set was left unticked — it is not in the log',
    );
    return '$_temp0';
  }

  @override
  String doneTitle(String name) {
    return '$name — done';
  }

  @override
  String get volumeExplain =>
      'Volume is every completed working set multiplied out. Warm-ups are in the log but not in this number, and not in your weekly set count either.';

  @override
  String get prLbl => 'PR';

  @override
  String insightIn(String group, String sets) {
    return '$group is at $sets this week — inside the 10–20 range where the evidence is strongest. Nothing to change.';
  }

  @override
  String insightUnder(String group, String sets) {
    return '$group is at $sets this week — under the 10–20 range. Another session or two would put it there.';
  }

  @override
  String insightOver(String group, String sets) {
    return '$group is at $sets this week — above 20. Past that point it is mostly fatigue.';
  }

  @override
  String get saveAsRoutine => 'Save as routine';

  @override
  String get share => 'Share';

  @override
  String shareText(String name, String time, String volume, String sets) {
    return '$name · $time · $volume · $sets hard sets';
  }

  @override
  String soloLogged(String name) {
    return '$name logged — the rest of the day is still there';
  }

  @override
  String get est1rm => 'Estimated 1RM';

  @override
  String trendKg(String delta, int w) {
    return '$delta kg / $w wk';
  }

  @override
  String get months6 => '6 months';

  @override
  String get chartNeedsTwo => 'Two workouts with this lift and the trend line starts.';

  @override
  String get best5 => 'Best 5 reps';

  @override
  String get best8 => 'Best 8 reps';

  @override
  String get setsWk => 'Sets / wk';

  @override
  String get exClimbing =>
      'This lift is still climbing. Whatever you are doing with the deficit, it is tolerable — no reason to slow down yet.';

  @override
  String get exFlat => 'Holding steady. In a deficit, holding is winning.';

  @override
  String get exDropping =>
      'Down from where it was eight weeks ago. Check sleep and the size of the deficit before blaming the program.';

  @override
  String get exNoHistory => 'No history yet. Log it once and its 1RM trend starts here.';

  @override
  String get historyLbl => 'History';

  @override
  String get back => 'Back';

  @override
  String get addAnExercise => 'Add an exercise';

  @override
  String get searchLibrary => 'Search the exercise library';

  @override
  String get noExerciseMatch => 'Nothing matches. Try a shorter word, or another muscle.';

  @override
  String get inLbl => 'in';

  @override
  String get alreadyIn => 'Already in this workout';

  @override
  String thenEx(String name) {
    return 'Then: $name';
  }

  @override
  String get progressTitleEm => 'Your <em>progress</em>';

  @override
  String get addWeighIn => 'Add a weigh-in';

  @override
  String get weightTab => 'Weight';

  @override
  String get measureTab => 'Measure';

  @override
  String get strengthTab => 'Strength';

  @override
  String get openCheckIn => 'Open this week\'s check-in';

  @override
  String get weighInToday => 'Today\'s weigh-in';

  @override
  String get weighInNote =>
      'Same time, same scale, before breakfast. One weigh-in means little; the trend line is what counts.';

  @override
  String get weighInSaved => 'Weigh-in saved';

  @override
  String get waistToday => 'Today\'s waist';

  @override
  String get waistNote => 'At the navel, relaxed, after breathing out.';

  @override
  String get measurementSaved => 'Measurement saved';

  @override
  String get rateLbl => 'Rate';

  @override
  String pctWk(String v) {
    return '$v %/wk';
  }

  @override
  String get trendNeedsTwo => 'Two weigh-ins a few days apart and the trend line starts.';

  @override
  String get sinceStart => 'Since start';

  @override
  String get waistLbl => 'Waist';

  @override
  String get weighInsLbl => 'Weigh-ins';

  @override
  String get weeklyHardSets => 'Weekly hard sets';

  @override
  String get indirectHalf => 'indirect counted as ½';

  @override
  String get noSetsThisWeek => 'No sets logged this week yet.';

  @override
  String get allInRange => 'Every muscle you trained most is at 10 sets or more this week.';

  @override
  String underTen(String group) {
    return '$group sits under the 10-set mark. Worth a look once you are out of the deficit — not something to fix by adding volume now.';
  }

  @override
  String get waistWhy => 'Waist moves slower than the scale but lies less: water and food in the gut barely touch it.';

  @override
  String get addMeasurement => 'Add a measurement';

  @override
  String get strengthEmpty => 'No lifts logged yet. Finish a workout and your estimated 1RMs show up here.';

  @override
  String get strengthNote => 'Estimated 1RM now, and the change over eight weeks. In a deficit, holding is winning.';

  @override
  String e1rmLine(String kg) {
    return 'est. 1RM $kg kg';
  }

  @override
  String get yourWeek => 'Your week';

  @override
  String get flatWeeks => 'A flat stretch';

  @override
  String checkInSub(String range, int week) {
    return '$range · week $week';
  }

  @override
  String get adjustBtn => 'Adjust';

  @override
  String get acceptTargets => 'Accept targets';

  @override
  String get laterBtn => 'Later';

  @override
  String get notNow => 'Not now';

  @override
  String applyKcal(String n) {
    return 'Apply $n kcal';
  }

  @override
  String get applyChoice => 'Apply';

  @override
  String get startBreak => 'Start the break';

  @override
  String targetsUpdated(String kcal) {
    return 'Targets updated · $kcal kcal';
  }

  @override
  String get askedNextWeek => 'Noted — asked again next week';

  @override
  String get needsTwoWeighIns => 'needs weigh-ins a week apart';

  @override
  String get onPlan => 'on plan';

  @override
  String get fasterThanPlan => 'faster than the plan';

  @override
  String get slowerThanPlan => 'slower than the plan';

  @override
  String get rateVsGoal => 'Rate vs goal';

  @override
  String get daysLogged => 'Days logged';

  @override
  String nOfSeven(int n) {
    return '$n of 7';
  }

  @override
  String get allSevenDays => 'every day';

  @override
  String get fullDaysOnly => 'full days only';

  @override
  String get measuredExpenditure => 'Measured expenditure';

  @override
  String get notMeasuredYet => 'Not measured yet';

  @override
  String notEnoughBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more fully logged days and Gymco can measure what you actually burn.',
      one: 'One more fully logged day and Gymco can measure what you actually burn.',
    );
    return '$_temp0 Until then your starting targets stay as they are.';
  }

  @override
  String expenditureShort(String kcal) {
    return 'From your logs and trend weight you burn about $kcal kcal a day.';
  }

  @override
  String expenditureFell(String intake, String kg, String kcal) {
    return 'You averaged $intake kcal and the trend fell $kg kg. That only balances if you are burning about $kcal.';
  }

  @override
  String expenditureRose(String intake, String kg, String kcal) {
    return 'You averaged $intake kcal and the trend rose $kg kg. That only balances if you are burning about $kcal.';
  }

  @override
  String get nextWeekTargets => 'Next week\'s targets';

  @override
  String get noChange => 'no change';

  @override
  String kcalChange(String n) {
    return '$n kcal';
  }

  @override
  String get targetsMoveNote =>
      'Protein and fat stay put; the change goes to carbs, where it helps your sessions. Weekly moves are capped at 120 kcal so one odd week never swings your diet.';

  @override
  String get targetsHoldNote =>
      'Nothing changes until expenditure is measured. Keep logging full days and weighing in.';

  @override
  String get dietMeetsTraining => 'Diet meets training';

  @override
  String get strengthHolding =>
      'Your main lifts are flat or up while you lose weight. Muscle is holding — this deficit is well tolerated. No change needed.';

  @override
  String get strengthSlipping => 'One of your main lifts is down. Watch it next week; if more follow, slow the cut.';

  @override
  String get fasterThanPlanned => 'This is faster than planned';

  @override
  String get perWeekLbl => 'per week';

  @override
  String fastBody(String goal) {
    return 'You asked for $goal%. At this rate a good part of what you are losing is likely muscle.';
  }

  @override
  String get intakeLbl => 'Intake';

  @override
  String floorIs(String n) {
    return 'floor is $n';
  }

  @override
  String get measuredShort => 'Burned';

  @override
  String get whatToDo => 'What would you like to do?';

  @override
  String eatMore(String n) {
    return 'Eat $n more a day';
  }

  @override
  String eatMoreSub(String goal) {
    return 'Back toward $goal% a week. Recommended.';
  }

  @override
  String get twoWeeksMaintenance => 'Two weeks at maintenance';

  @override
  String get maintenanceThenResume => 'A break, then resume at the planned rate';

  @override
  String get keepGoingAsIAm => 'Keep going as I am';

  @override
  String get askedAgain => 'Gymco will raise this again next week';

  @override
  String floorWarnNote(String n) {
    return 'Targets are never set below $n kcal. If you want to go under that you can, but you will type the number yourself and read this message first.';
  }

  @override
  String stallBody(int weeks) {
    return '$weeks weeks in, and the trend has barely moved for two. Expenditure drifts down on a long diet — normal, and part of why this has stopped.';
  }

  @override
  String get threeOptions => 'Three honest options';

  @override
  String maintenanceSub(String kcal) {
    return '$kcal kcal, no deficit. Mostly this buys you a rest from dieting.';
  }

  @override
  String get checkLogging => 'Check the logging first';

  @override
  String get checkLoggingSub => 'Weekends and snacks are where flat weeks usually start.';

  @override
  String get cut150 => 'Cut 150 more a day';

  @override
  String get cut150Sub => 'Works, but this far in it is the option that costs the most muscle.';

  @override
  String get dietBreakEvidence =>
      'Gymco will not promise you a metabolic reset. Diet breaks helped weight loss in some trials and not in others. What they reliably do is make the next weeks survivable.';

  @override
  String get awardsTitle => 'Awards';

  @override
  String get awardsTitleEm => 'Your <em>awards</em>';

  @override
  String get editGoal => 'Edit goal';

  @override
  String commitmentDays(int n) {
    return '$n-day commitment';
  }

  @override
  String keptOfGoal(int kept, int goal) {
    return '$kept of $goal days kept';
  }

  @override
  String nextAwardIn(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n days', one: '1 day');
    return 'Next award: $name in $_temp0';
  }

  @override
  String get allStreakAwards => 'Every streak award earned';

  @override
  String ofDays(int n) {
    return '/ $n days';
  }

  @override
  String legendStreak(int n) {
    return 'Streak · $n to go';
  }

  @override
  String legendFood(int n) {
    return 'Food · $n of 3 meals';
  }

  @override
  String get legendTrainDone => 'Train · done';

  @override
  String get legendRest => 'Train · rest day';

  @override
  String legendPlanned(String name) {
    return 'Train · $name planned';
  }

  @override
  String dayKept(int n) {
    return 'Day $n kept. See you tomorrow.';
  }

  @override
  String logToKeep(String meal, int n) {
    return 'Log $meal to keep day $n';
  }

  @override
  String trainToKeep(String name, int n) {
    return 'Finish $name to keep day $n';
  }

  @override
  String get logBtn => 'Log';

  @override
  String get trainBtn => 'Train';

  @override
  String goalReached(int n) {
    return '$n days. Your commitment is done.';
  }

  @override
  String get seeRecap => 'See recap';

  @override
  String get thisWeek => 'This week';

  @override
  String get restDaysCount => 'Rest days count';

  @override
  String get bestStreak => 'Best streak';

  @override
  String nDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get freezesLbl => 'Freezes';

  @override
  String freezesOf(int n, int max) {
    return '$n of $max';
  }

  @override
  String challengeDone(int n) {
    return 'Done — $n sessions this month';
  }

  @override
  String challengeLeft(int n, int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '$days days', one: '1 day');
    return 'Train $n times this month · $_temp0 left';
  }

  @override
  String get shelfStreaks => 'Streaks';

  @override
  String get shelfFood => 'Food';

  @override
  String get shelfTraining => 'Training';

  @override
  String gotOf(int got, int n) {
    return '$got of $n';
  }

  @override
  String get awardsNote => 'No award here is for eating less or losing weight. Logging and showing up are what count.';

  @override
  String get earnedLbl => 'Earned';

  @override
  String earnedOn(String date) {
    return 'Earned $date';
  }

  @override
  String get earnedLabel => 'earned';

  @override
  String get lockedLabel => 'locked';

  @override
  String get restartAfterBreak => 'Restart after a break';

  @override
  String nToGo(int n) {
    return '$n to go';
  }

  @override
  String get progressLbl => 'Progress';

  @override
  String nextNamed(String name) {
    return 'Next · $name';
  }

  @override
  String get shareAward => 'Share';

  @override
  String shareAwardText(String name) {
    return 'I earned \"$name\" on Gymco.';
  }

  @override
  String get backToAwards => 'Back to awards';

  @override
  String get mdDays => 'DAYS';

  @override
  String get mdMeals => 'MEALS';

  @override
  String get mdProtein => 'PROTEIN';

  @override
  String get mdWorkouts => 'WORKOUTS';

  @override
  String get mdBests => 'BESTS';

  @override
  String get awFirstWeek => 'First week';

  @override
  String get awFirstWeekD => 'Seven days in a row with every meal logged and every planned workout or rest day kept.';

  @override
  String get awTwoWeeks => 'Two weeks';

  @override
  String get awTwoWeeksD => 'Fourteen kept days in a row. The first week is novelty; the second one is choice.';

  @override
  String get awOneMonth => 'One month strong';

  @override
  String get awOneMonthD => 'Thirty days in a row with every meal logged and every planned workout or rest day kept.';

  @override
  String get awHabit => 'Habit formed';

  @override
  String get awHabitD => 'Sixty-six days, the average it takes a new behaviour to run on its own.';

  @override
  String get awFull => 'Full commitment';

  @override
  String get awFullD => 'Ninety days kept. Three months of showing up, rest days included.';

  @override
  String get awComeback => 'Comeback';

  @override
  String get awComebackD => 'Start a new run after a streak ends. Coming back is the part that counts.';

  @override
  String get awFirstFullDay => 'First full day';

  @override
  String get awFirstFullDayD => 'Breakfast, lunch and dinner logged in one day.';

  @override
  String get awHundredMeals => '100 meals logged';

  @override
  String get awHundredMealsD =>
      'One hundred meals logged. Rough estimates count — what matters is that the day is written down.';

  @override
  String get awProteinWeek => 'Protein week';

  @override
  String get awProteinWeekD =>
      'Your protein target hit on seven days in one week. It is the one number that protects muscle in a cut.';

  @override
  String get awFirstWorkout => 'First workout';

  @override
  String get awFirstWorkoutD => 'Your first logged session in Gymco.';

  @override
  String get awTwentyFive => '25 workouts';

  @override
  String get awTwentyFiveD => 'Twenty-five sessions logged, set by set.';

  @override
  String get awTenBests => '10 personal bests';

  @override
  String get awTenBestsD => 'Ten new best sets. Strength holding in a deficit is the sign the cut is going well.';

  @override
  String awMonth(String month) {
    return '$month challenge';
  }

  @override
  String awMonthD(int n) {
    return 'Train $n times this month.';
  }

  @override
  String get yourCommitment => 'Your commitment';

  @override
  String get howLong => 'How long are you in for?';

  @override
  String get howLongSub => 'Pick a run of days. Every day you keep fills the outer ring.';

  @override
  String get daysWord => 'days';

  @override
  String get goal21 => 'Get started';

  @override
  String get goal30 => 'One month';

  @override
  String get goal66 => 'Make it a habit';

  @override
  String get goal90 => 'Full commitment';

  @override
  String get customLbl => 'Custom';

  @override
  String get customRange => '7 – 365 days';

  @override
  String get useThis => 'Use this';

  @override
  String get dayCountsWhen => 'A day counts when';

  @override
  String get ruleMeals => 'Meals are logged';

  @override
  String get ruleMealsSub => 'Logging counts, not eating less';

  @override
  String get ruleTrain => 'You train or rest as planned';

  @override
  String get ruleTrainSub => 'Rest days on your plan keep the streak';

  @override
  String freezeNote(int n, int max) {
    return 'Earn a streak freeze every $n days you keep. Hold up to $max for sick days and travel.';
  }

  @override
  String alreadyPast(int n) {
    return 'Already past $n days — pick longer';
  }

  @override
  String keepMyDays(int n) {
    return 'Keep my $n days';
  }

  @override
  String commitTo(int n) {
    return 'Commit to $n days';
  }

  @override
  String carryOver(int n, String date) {
    return 'Your $n kept days carry over · finishes $date';
  }

  @override
  String startsToday(String date) {
    return 'Starts today · finishes $date';
  }

  @override
  String goalDoneTitle(int n) {
    return '$n days. Done.';
  }

  @override
  String goalDoneSub(String from, String to, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n freezes used',
      one: '1 freeze used',
      zero: 'no freezes used',
    );
    return '$from – $to · $_temp0';
  }

  @override
  String get workoutsLbl => 'Workouts';

  @override
  String get restDaysKept => 'Rest days kept';

  @override
  String get mealsLoggedLbl => 'Meals logged';

  @override
  String get personalBests => 'Personal bests';

  @override
  String get goalDoneNote => 'Showing up, rest days included. This is what a habit looks like.';

  @override
  String shareMyDays(int n) {
    return 'Share my $n days';
  }

  @override
  String shareGoalText(int n) {
    return '$n days kept on Gymco — every meal logged, every workout and rest day done.';
  }

  @override
  String get setNextCommitment => 'Set your next commitment';

  @override
  String get writeHint =>
      '200g chicken breast, 150g rice and 10g olive oil\n2 eggs with two slices of bread\na scoop of whey';

  @override
  String get writeEmpty =>
      'Write the meal the way you would say it. Amounts in grams, or counts like “two eggs” and “a scoop”, both work.';

  @override
  String itRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'It read $n items', one: 'It read 1 item');
    return '$_temp0';
  }

  @override
  String nAssumed(int n) {
    return '$n assumed';
  }

  @override
  String get assumedTag => 'assumed';

  @override
  String get notInDbYet => 'Not in the database yet';

  @override
  String get searchAction => 'Search';

  @override
  String get assumedNote =>
      'Rows marked assumed had no amount written, so a normal serving was used. Tap a row to set the amount.';

  @override
  String addN(int n) {
    return 'Add $n';
  }

  @override
  String pcfLine(String p, String c, String f) {
    return '$p P · $c C · $f F';
  }

  @override
  String writtenSub(String g, String kcal, String p) {
    return '$g g · $kcal kcal · $p g protein';
  }

  @override
  String removeNamed(String name) {
    return 'Remove $name';
  }

  @override
  String howMuchOf(String name) {
    return 'How much $name?';
  }

  @override
  String get gramsNote => 'In grams, as eaten.';

  @override
  String get voiceHold => 'Hold and say what you ate. It goes through the same reader as writing.';

  @override
  String get voiceListening => 'Listening… let go when you are done.';

  @override
  String get voiceHeard => 'Heard it. Check the transcript before it goes in.';

  @override
  String get transcriptLbl => 'Transcript · edit if it misheard';

  @override
  String get voiceUnavailable =>
      'Dictation is not available on this phone, or the microphone is off for Gymco. Write it instead.';

  @override
  String get dictateMeal => 'Dictate the meal';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountRowSub => 'Backup and photo logging';

  @override
  String accountRowSignedIn(String email) {
    return 'Signed in · $email';
  }

  @override
  String get accountRowOff => 'Phone only';

  @override
  String get signInTitle => 'Back up to an account';

  @override
  String get signInSub => 'Your email and a sign-in link — no password';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get codeHint => '6-digit code';

  @override
  String get sendCode => 'Send sign-in link';

  @override
  String get signInAction => 'Sign in';

  @override
  String codeSentTo(String email) {
    return 'We sent a sign-in link to $email. Open it on this phone and Gymco signs you in. If the email has a code instead, type it here.';
  }

  @override
  String get useOtherEmail => 'Use another email';

  @override
  String get accountWhy =>
      'Your diary stays on this phone either way. An account adds a backup you can restore on a new phone, and photo logging — 10 photos a day, free.';

  @override
  String get cloudNotSetUp => 'Accounts are not switched on in this build. Everything else works on the phone.';

  @override
  String get signedInAs => 'Signed in';

  @override
  String get backupTitle => 'Backup';

  @override
  String backedUpAt(String when) {
    return 'Backed up $when';
  }

  @override
  String get notBackedUp => 'Not backed up yet';

  @override
  String get backupAuto => 'It backs up by itself when you leave the app, at most every six hours.';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupDone => 'Backed up';

  @override
  String get restoreAction => 'Restore from backup';

  @override
  String get restoreTitle => 'Restore this backup?';

  @override
  String restoreBody(String when) {
    return 'The backup from $when replaces what is on this phone now.';
  }

  @override
  String get foundBackupTitle => 'A backup is in your account';

  @override
  String foundBackupBody(String when) {
    return 'From $when. Restore it onto this phone, or keep what this phone has and back that up instead.';
  }

  @override
  String get restoreIt => 'Restore it';

  @override
  String get keepThisPhone => 'Keep this phone’s data';

  @override
  String get restored => 'Restored';

  @override
  String get noBackupYet => 'There is no backup in this account yet';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutNote => 'Signing out keeps everything on this phone.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSub => 'The account and its backup';

  @override
  String get deleteAccountBody =>
      'The account and its backup are deleted now. What is on this phone stays; delete it under Your data.';

  @override
  String get deleteAccountConfirm => 'Delete account and backup';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get errOffline => 'No connection. Try again when you are online.';

  @override
  String get errBadCode => 'That code did not work. Check it, or send a new one.';

  @override
  String get errBusy => 'Too many tries just now. Wait a minute and try again.';

  @override
  String get errGeneric => 'Something went wrong. Try again.';

  @override
  String get photoPrompt => 'Photograph the plate. Gymco suggests what it sees; you say how much.';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get choosePhoto => 'Choose from photos';

  @override
  String get readingPlate => 'Looking at the plate…';

  @override
  String plateThings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n things on the plate',
      one: 'One thing on the plate',
      zero: 'Nothing recognisable on the plate',
    );
    return '$_temp0';
  }

  @override
  String get tapToConfirm => 'tap to confirm';

  @override
  String get fairlyConfident => 'fairly confident';

  @override
  String get notSureCheck => 'not sure — check this one';

  @override
  String get photoAmountNote =>
      'A photo cannot tell how much is on the plate — no recognition system can. Pick the foods here, then set the amounts yourself.';

  @override
  String get photoNeedsAccount =>
      'Photo logging uses an account: the photo is read on our server, 10 a day, free. Writing and search work without one.';

  @override
  String get photoNotSetUp => 'Photo logging is not switched on in this build. Write or search instead.';

  @override
  String scansLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n photo scans left today',
      one: '1 photo scan left today',
      zero: 'No photo scans left today',
    );
    return '$_temp0';
  }

  @override
  String get photoCap => 'That is today’s 10 photo scans. They come back tomorrow; write or search in the meantime.';

  @override
  String get photoRefused => 'That photo could not be read. Try another one.';

  @override
  String get photoAgain => 'Take another';

  @override
  String get notInDbSearch => 'Not on the phone — search for it';
}
