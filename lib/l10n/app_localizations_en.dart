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
  String get photoComing =>
      'Photograph the plate and Gymco suggests what it sees; you say how much. Arrives with AI logging.';

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
  String get voiceComing =>
      'Hold and say what you ate. It goes through the same reader as writing. Arrives with AI logging.';

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
  String get writeComing =>
      'Write the meal the way you would say it — “two eggs, 150 g rice”. Arrives with AI logging.';

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
}
