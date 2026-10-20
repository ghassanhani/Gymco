// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'جيمكو';

  @override
  String get tabToday => 'اليوم';

  @override
  String get tabFood => 'الطعام';

  @override
  String get tabTrain => 'التمرين';

  @override
  String get tabProgress => 'التقدّم';

  @override
  String get tabMe => 'أنا';

  @override
  String todayTitle(String accent) {
    return 'اجعلها $accent';
  }

  @override
  String get todayAccent => 'تُحتسب';

  @override
  String kcalLeft(String n) {
    return 'متبقٍ $n سعرة';
  }

  @override
  String kcalOver(String n) {
    return '$n سعرة فوق الهدف';
  }

  @override
  String ofGrams(String a, String b) {
    return '$a / $b غ';
  }

  @override
  String get protein => 'بروتين';

  @override
  String get carbs => 'كربوهيدرات';

  @override
  String get fat => 'دهون';

  @override
  String get kcal => 'سعرة';

  @override
  String get meals => 'الوجبات';

  @override
  String get breakfast => 'الفطور';

  @override
  String get lunch => 'الغداء';

  @override
  String get dinner => 'العشاء';

  @override
  String get snack => 'وجبة خفيفة';

  @override
  String get nothingLogged => 'لم يُسجَّل شيء بعد';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر',
      many: '$count عنصرًا',
      few: '$count عناصر',
      two: 'عنصران',
      one: 'عنصر واحد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String get emptyDayTitle => 'يوم جديد';

  @override
  String get emptyDayBody => 'ابدأ بأول ما أكلته. وجبة واحدة بداية جيدة.';

  @override
  String get addFood => 'أضف طعامًا';

  @override
  String addTo(String meal) {
    return 'أضف إلى $meal';
  }

  @override
  String get searchFoods => 'ابحث عن الأطعمة';

  @override
  String get scanBarcode => 'امسح الباركود';

  @override
  String get recent => 'الأخيرة';

  @override
  String noResults(String q) {
    return 'لا نتائج لـ \"$q\"';
  }

  @override
  String get noResultsBody => 'جرّب كلمة أقصر، أو امسح العبوة.';

  @override
  String get barcodeMiss => 'لا نعرف هذا المنتج بعد';

  @override
  String get barcodeMissBody =>
      'أضفه إلى Open Food Facts في نحو 30 ثانية وسيكون متاحًا للجميع في المرة القادمة.';

  @override
  String get contributeOff => 'أضف إلى Open Food Facts';

  @override
  String get searchingOnline => 'جارٍ البحث على الإنترنت…';

  @override
  String get offlineSearch => 'غير متصل — تظهر الأطعمة المحفوظة على هذا الهاتف';

  @override
  String get amount => 'الكمية';

  @override
  String get grams => 'غ';

  @override
  String get per100g => 'لكل 100 غ';

  @override
  String get log => 'سجّل';

  @override
  String get delete => 'احذف';

  @override
  String logged(String food) {
    return 'تم تسجيل $food';
  }

  @override
  String get cameraPermission => 'اسمح باستخدام الكاميرا لمسح الباركود.';

  @override
  String obWelcomeTitle(String accent) {
    return 'الغذاء والتمرين، $accent';
  }

  @override
  String get obWelcomeAccent => 'معًا';

  @override
  String get obWelcomeBody =>
      'أهداف تتكيّف مع ما تأكله وتزنه فعلًا. بلا تخمين وبلا عقاب.';

  @override
  String get getStarted => 'ابدأ';

  @override
  String get obGoalTitle => 'لأجل ماذا تتمرّن؟';

  @override
  String get goalCut => 'تنشيف';

  @override
  String get goalCutSub => 'اخسر الدهون، واحتفظ بالعضل والقوة';

  @override
  String get goalMaintain => 'الثبات';

  @override
  String get goalMaintainSub => 'ثبّت وزنك واستمر في التسجيل بصدق';

  @override
  String get goalBulk => 'تضخيم نظيف';

  @override
  String get goalBulkSub => 'زِد الحجم بنسبة 0.25–0.5% من وزن الجسم أسبوعيًا';

  @override
  String get obBodyTitle => 'عنك';

  @override
  String get obBodyBody =>
      'تُستخدم لبدء الأسبوع الأول فقط. بعد 14 يومًا يتولّى إنفاقك الحقيقي.';

  @override
  String get sexMale => 'ذكر';

  @override
  String get sexFemale => 'أنثى';

  @override
  String get age => 'العمر';

  @override
  String get heightCm => 'الطول (سم)';

  @override
  String get weightKg => 'الوزن (كغ)';

  @override
  String get obActivityTitle => 'ما مدى نشاط يومك العادي؟';

  @override
  String get actSedentary => 'جلوس معظم الوقت';

  @override
  String get actLight => 'واقف جزءًا من اليوم';

  @override
  String get actModerate => 'عمل نشط أو مشي يومي';

  @override
  String get actHigh => 'عمل بدني';

  @override
  String get actAthlete => 'تمرين شاق مرتين يوميًا';

  @override
  String get obRateTitle => 'بأي سرعة؟';

  @override
  String ratePerWeek(String pct) {
    return '$pct% من وزن الجسم أسبوعيًا';
  }

  @override
  String rateKgPerWeek(String kg) {
    return '≈ $kg كغ أسبوعيًا';
  }

  @override
  String get rateWarning =>
      'أسرع من 0.85% أسبوعيًا غالبًا ما يكلّف العضل والنوم. يمكنك ذلك، لكننا سنتابع معك أكثر.';

  @override
  String get rateCapNote => 'الحد الأقصى 1% أسبوعيًا.';

  @override
  String get obTargetsTitle => 'أهدافك الأولى';

  @override
  String get obTargetsBody =>
      'تقدير لا حكم. بعد أسبوعين أو ثلاثة من التسجيل، يستبدله جيمكو بإنفاقك المقيس.';

  @override
  String get dailyTarget => 'الهدف اليومي';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get startBtn => 'ابدأ';

  @override
  String get meTitle => 'أنا';

  @override
  String get language => 'اللغة';

  @override
  String get systemLanguage => 'لغة الهاتف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get cheatAllowance => 'الوجبات الحرّة';

  @override
  String get cheatOff => 'إيقاف';

  @override
  String get cheatOnce => '1 أسبوعيًا';

  @override
  String get cheatTwice => '2 أسبوعيًا';

  @override
  String get targets => 'الأهداف';

  @override
  String get redoOnboarding => 'غيّر الهدف والأهداف اليومية';

  @override
  String get trainTitle => 'التمرين';

  @override
  String get progressTitle => 'التقدّم';

  @override
  String get nextBuild => 'هذا الجزء من جيمكو مصمَّم ويُبنى الآن.';

  @override
  String get repeatYesterday => 'كرّر الأمس';

  @override
  String get nothingYesterday => 'لم يُسجَّل شيء في هذه الوجبة أمس';

  @override
  String trainTitleTpl(String accent) {
    return 'تمرّن $accent';
  }

  @override
  String get trainAccent => 'بقوة';

  @override
  String get routines => 'البرامج';

  @override
  String get newRoutine => 'برنامج جديد';

  @override
  String get editRoutine => 'عدّل البرنامج';

  @override
  String get emptyWorkout => 'تمرين فارغ';

  @override
  String get startRoutine => 'ابدأ';

  @override
  String get resumeWorkout => 'تابع';

  @override
  String inProgress(String time) {
    return 'تمرين جارٍ · $time';
  }

  @override
  String get noRoutinesTitle => 'لا برامج بعد';

  @override
  String get noRoutinesBody =>
      'أنشئ برنامجًا، أو ابدأ تمرينًا فارغًا وأضف التمارين أثناءه.';

  @override
  String get history => 'السجل';

  @override
  String get noHistory => 'تظهر التمارين المنتهية هنا.';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مجموعة',
      many: '$count مجموعة',
      few: '$count مجموعات',
      two: 'مجموعتان',
      one: 'مجموعة واحدة',
      zero: 'لا مجموعات',
    );
    return '$_temp0';
  }

  @override
  String exercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تمرين',
      many: '$count تمرينًا',
      few: '$count تمارين',
      two: 'تمرينان',
      one: 'تمرين واحد',
      zero: 'لا تمارين',
    );
    return '$_temp0';
  }

  @override
  String get routineName => 'اسم البرنامج';

  @override
  String get addExercise => 'أضف تمرينًا';

  @override
  String get save => 'احفظ';

  @override
  String nameTaken(String name) {
    return 'لديك برنامج باسم $name بالفعل. اختر اسمًا آخر أو عدّل ذلك البرنامج.';
  }

  @override
  String get deleteRoutine => 'احذف البرنامج';

  @override
  String get deleteRoutineTitle => 'حذف هذا البرنامج؟';

  @override
  String get deleteRoutineBody =>
      'يُحذف البرنامج. كل تمرين سجّلته منه يبقى في سجلك بمجموعاته وأرقامه القياسية.';

  @override
  String get edit => 'تعديل';

  @override
  String get setsLabel => 'المجموعات';

  @override
  String get repsLabel => 'التكرارات';

  @override
  String get restLabel => 'الراحة';

  @override
  String repRange(int lo, int hi) {
    return '$lo–$hi تكرار';
  }

  @override
  String restSeconds(int s) {
    return 'راحة $s ث';
  }

  @override
  String get searchExercises => 'ابحث عن التمارين';

  @override
  String get allMuscles => 'الكل';

  @override
  String addCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أضف $count تمرين',
      many: 'أضف $count تمرينًا',
      few: 'أضف $count تمارين',
      two: 'أضف تمرينين',
      one: 'أضف تمرينًا واحدًا',
      zero: 'أضف',
    );
    return '$_temp0';
  }

  @override
  String get m_chest => 'الصدر';

  @override
  String get m_shoulders => 'الأكتاف';

  @override
  String get m_triceps => 'الترايسبس';

  @override
  String get m_biceps => 'البايسبس';

  @override
  String get m_forearms => 'الساعدان';

  @override
  String get m_lats => 'الظهر العريض';

  @override
  String get m_middle_back => 'منتصف الظهر';

  @override
  String get m_lower_back => 'أسفل الظهر';

  @override
  String get m_traps => 'الترابيس';

  @override
  String get m_abdominals => 'البطن';

  @override
  String get m_quadriceps => 'الفخذ الأمامي';

  @override
  String get m_hamstrings => 'الفخذ الخلفي';

  @override
  String get m_glutes => 'الأرداف';

  @override
  String get m_calves => 'السمانة';

  @override
  String get m_adductors => 'الفخذ الداخلي';

  @override
  String get m_abductors => 'الفخذ الخارجي';

  @override
  String get m_neck => 'الرقبة';

  @override
  String get finish => 'إنهاء';

  @override
  String get discard => 'تجاهل التمرين';

  @override
  String get discardTitle => 'تجاهل هذا التمرين؟';

  @override
  String get discardBody => 'لن يُحفظ شيء منه.';

  @override
  String get unfinishedTitle => 'بعض المجموعات غير مؤشَّرة';

  @override
  String get unfinishedBody => 'تُحفظ المجموعات المؤشَّرة فقط.';

  @override
  String get finishAnyway => 'إنهاء';

  @override
  String get keepGoing => 'تابع التمرين';

  @override
  String get durationLbl => 'المدة';

  @override
  String get volumeLbl => 'الحجم';

  @override
  String get setsDoneLbl => 'المجموعات';

  @override
  String get addSet => 'أضف مجموعة';

  @override
  String get previous => 'السابق';

  @override
  String get kgLbl => 'كغ';

  @override
  String get repsLbl => 'تكرار';

  @override
  String get restRunning => 'راحة';

  @override
  String get skip => 'تخطَّ';

  @override
  String get setTypeTitle => 'نوع المجموعة';

  @override
  String get stWarmup => 'إحماء';

  @override
  String get stWarmupSub => 'لا تُحسب ضمن المجموعات الأسبوعية';

  @override
  String get stNormal => 'عادية';

  @override
  String get stNormalSub => 'مجموعة عمل فعّالة';

  @override
  String get stFailure => 'حتى الفشل';

  @override
  String get stFailureSub => 'حتى الفشل التقني';

  @override
  String get stDrop => 'مجموعة تنازلية';

  @override
  String get stDropSub => 'تُحسب نصف مجموعة';

  @override
  String get removeSet => 'أزل هذه المجموعة';

  @override
  String get removeExercise => 'احذف التمرين';

  @override
  String get summaryTitle => 'انتهى التمرين';

  @override
  String newBest(String exercise) {
    return 'رقم جديد: $exercise';
  }

  @override
  String estOneRm(String kg) {
    return 'أقصى تكرار تقديري $kg كغ';
  }

  @override
  String get doneBtn => 'تم';

  @override
  String get instructions => 'طريقة الأداء';

  @override
  String get primaryMuscles => 'العضلات الأساسية';

  @override
  String get secondaryMuscles => 'يعمل أيضًا على';

  @override
  String get photoUnavailable => 'الصورة غير متاحة دون اتصال';

  @override
  String get workoutDefaultName => 'تمرين';

  @override
  String get startWorkoutHint => 'أضف تمرينًا للبدء.';

  @override
  String minutesShort(String m) {
    return '$m د';
  }

  @override
  String get tickSetHint => 'أشّر المجموعة';

  @override
  String get about => 'نحو';

  @override
  String get actSitting => 'جلوس معظم الوقت';

  @override
  String get actSittingSub => 'عمل مكتبي، أقل من 5,000 خطوة';

  @override
  String get actFeet => 'واقف معظم اليوم';

  @override
  String get actFeetSub => 'مشي كثير، 5,000–10,000 خطوة';

  @override
  String get actPhysical => 'عمل بدني';

  @override
  String get actPhysicalSub => 'رفع أو حمل معظم اليوم';

  @override
  String get actVery => 'نشيط جدًا';

  @override
  String get actVerySub => 'أكثر من 12,000 خطوة أو رياضة ثانية';

  @override
  String get addFoodToMeal => 'أضف طعامًا إلى هذه الوجبة';

  @override
  String get agreeToContinue => 'وافق للمتابعة';

  @override
  String get backToToday => 'العودة إلى اليوم';

  @override
  String get calorieFloor => 'الحد الأدنى للسعرات';

  @override
  String get cheatAllowanceNote =>
      'لا يُعوَّض شيء بالكارديو أبدًا. الوجبة المدّخرة تقتطع جزءًا من الأيام التي قبلها؛ والحرّة لا تُسجَّل ببساطة.';

  @override
  String get chooseRoutine => 'اختر برنامجًا';

  @override
  String get cm => 'سم';

  @override
  String get consentHealth =>
      'أوافق على أن يحفظ جيمكو وزني وقياساتي وسجلات طعامي كبيانات صحية على هذا الهاتف لحساب أهدافي.';

  @override
  String get copiedToToday => 'نُسخ إلى اليوم';

  @override
  String get copyToToday => 'انسخ إلى اليوم';

  @override
  String get createdByYou => 'أنشأته أنت';

  @override
  String get custom => 'مخصّص';

  @override
  String get customFood => 'طعام مخصّص';

  @override
  String get deleteDigit => 'احذف آخر رقم';

  @override
  String get emptyMeal => 'وجبة فارغة';

  @override
  String get firstRunTip =>
      'معظم الناس يسجّلون الأشياء الثمانية أو العشرة نفسها. سجّلها مرة واحدة ويصبح اليوم نحو عشرين ثانية.';

  @override
  String get floorBody =>
      'لا تُحدَّد الأهداف تحت هذا الرقم أبدًا. النزول عنه يعني أن تكتب الرقم بنفسك، بعد تحذير.';

  @override
  String get floorSub => 'سعرة · حدّك الأدنى';

  @override
  String get followsPhone => 'يتبع لغة هاتفك';

  @override
  String get freeAlways => 'مجانًا، دائمًا';

  @override
  String get genericUsda => 'عام · USDA';

  @override
  String get genericUsdaVerified => 'عام · USDA · موثَّق';

  @override
  String get goalAndTargets => 'الهدف والأهداف اليومية';

  @override
  String get goalRecomp => 'إعادة تشكيل الجسم';

  @override
  String get goalRecompSub => 'ابقَ قرب الثبات؛ راقب الخصر لا الميزان';

  @override
  String get goalPrep => 'تحضير لمسابقة';

  @override
  String get goalPrepSub => 'خطّط بالعكس من موعد المسابقة';

  @override
  String get goalShortCut => 'تنشيف';

  @override
  String get goalShortBulk => 'تضخيم';

  @override
  String get goalShortRecomp => 'إعادة تشكيل';

  @override
  String get goalShortMaintain => 'ثبات';

  @override
  String get goalShortPrep => 'تحضير';

  @override
  String get heightLbl => 'الطول';

  @override
  String get heroDoneBody =>
      'سُجّل وحُفظ. الراحة هي حيث يتحوّل إلى التمرين القادم.';

  @override
  String get heroExercises => 'تمارين';

  @override
  String get heroMin => 'دقيقة';

  @override
  String get heroMuscles => 'عضلات';

  @override
  String get heroRestBody =>
      'لا شيء مجدول اليوم. الراحة هي حيث يتحوّل التمرين الماضي إلى القادم.';

  @override
  String get heroRestTitle => 'يوم <em>راحة</em>';

  @override
  String get heroSets => 'مجموعات';

  @override
  String get heroSetupBody =>
      'اختر تقسيمًا أو ابنِ برنامجك. جيمكو يجدوله ويتابع كل مجموعة.';

  @override
  String get heroSetupTitle => 'جهّز <em>تمرينك</em>';

  @override
  String get heroTagDone => 'أُنجز اليوم';

  @override
  String get heroTagInProgress => 'جارٍ الآن';

  @override
  String get heroTagToday => 'تمرين اليوم';

  @override
  String get inThisMeal => 'في هذه الوجبة';

  @override
  String get kcalADay => 'سعرة يوميًا';

  @override
  String get kcalLeftLabel => 'سعرة متبقية';

  @override
  String get kcalLoggedLabel => 'سعرة مسجّلة';

  @override
  String get kcalOverLabel => 'سعرة فوق الهدف';

  @override
  String get kcalToLog => 'سعرة للتسجيل';

  @override
  String get langArabicSub => 'العربية · من اليمين لليسار';

  @override
  String get langEnglishSub => 'الإنجليزية';

  @override
  String get langSpanishSub => 'الإسبانية';

  @override
  String get logFirstMeal => 'سجّل وجبتك الأولى';

  @override
  String get mBarcode => 'باركود';

  @override
  String get mPhoto => 'صورة';

  @override
  String get mSearch => 'بحث';

  @override
  String get mVoice => 'صوت';

  @override
  String get mWrite => 'كتابة';

  @override
  String get mealDetailTip =>
      'المس عنصرًا لتغيير كميته. ما تحذفه يخرج من اليوم فورًا.';

  @override
  String get mealLabel => 'الوجبة';

  @override
  String get myMeals => 'وجباتي';

  @override
  String get noMatchBody =>
      'الطبخ المنزلي نادرًا ما يكون فيها. امسح العبوة، أو جرّب كلمة أخرى.';

  @override
  String get noMatchTitle => 'لا تطابق في قاعدة البيانات';

  @override
  String get noSessionPlanned => 'لا تمرين مخطّط';

  @override
  String get nothingInMeal => 'لا شيء في هذه الوجبة بعد';

  @override
  String get nothingYesterdayDay => 'لم يُسجَّل شيء أمس';

  @override
  String get obActivityTitleEm => 'كيف <em>تتحرّك</em> في يوم عادي؟';

  @override
  String get obBodyTitleEm => 'قليلًا <em>عنك</em>';

  @override
  String get obGoalBody =>
      'يحدّد هذا سرعتك وحدّ البروتين وطريقة قراءة بياناتك. يمكنك تغييره أي أسبوع.';

  @override
  String get obRateBodyGain =>
      'البطء نظيف. ربع إلى نصف بالمئة من وزن الجسم أسبوعيًا يبقي الزيادة عضلًا في معظمها.';

  @override
  String get obRateBodyLose =>
      'الأسرع ليس الأفضل. بين 0.5 و1% من وزن الجسم أسبوعيًا يبقى العضل محفوظًا.';

  @override
  String get obRateTitleGain => 'بأي سرعة تريد أن تزيد؟';

  @override
  String get obRateTitleLose => 'بأي سرعة تريد أن تخسر؟';

  @override
  String get pastNoteWithin =>
      'ضمن مئة سعرة من الهدف. أيام كهذه هي ما يحرّك خط الاتجاه.';

  @override
  String get pctPerWeek => '% / أسبوع';

  @override
  String get rateHot =>
      'فوق 0.85% أسبوعيًا تبدأ بخسارة العضل. سيكرّر جيمكو ذلك كل أسبوع حتى تبطئ.';

  @override
  String get rateOkGain => 'بطيء بما يكفي لتكون معظم الزيادة عضلًا.';

  @override
  String get rateOkLose =>
      'ضمن النطاق الذي يوصي به Helms وزملاؤه (2014) للرياضيين الطبيعيين للحفاظ على العضل أثناء العجز.';

  @override
  String get recipes => 'وصفات';

  @override
  String get restDay => 'يوم راحة';

  @override
  String get ringEmptyBody =>
      'لم يُسجَّل شيء بعد. أهدافك جاهزة — تمتلئ الحلقة مع تقدّمك.';

  @override
  String get rtlNote =>
      'العربية تقلب التطبيق كله من اليمين لليسار، بما في ذلك شريط الأسبوع واتجاهات السحب.';

  @override
  String get safeguards => 'ضمانات';

  @override
  String get savedSeeTrain => 'حُفظ · شاهده في التمرين';

  @override
  String get scanABarcode => 'امسح باركود';

  @override
  String get scanBarcodeSub => 'الطعام المعلّب يُقرأ مباشرة من أرقام العبوة';

  @override
  String get searchDatabase => 'ابحث في قاعدة البيانات';

  @override
  String get searchOtherLanguage =>
      'البحث بلغة أخرى يجد أكثر غالبًا — جيمكو يحفظ كل اسم يتعلّمه على الطعام نفسه.';

  @override
  String get seeTheWeek => 'شاهد الأسبوع';

  @override
  String get settings => 'الإعدادات';

  @override
  String get sexForEquation => 'الجنس لمعادلة الطاقة';

  @override
  String get startLogging => 'ابدأ التسجيل';

  @override
  String get startWorkout => 'ابدأ التمرين';

  @override
  String get targetsSaved => 'حُفظت الأهداف — ابدأ التسجيل';

  @override
  String get theRemainder => 'الباقي';

  @override
  String get todayTitleEm => 'اجعلها <em>تُحتسب</em>';

  @override
  String get training => 'التمرين';

  @override
  String get trainingCountedSeparately =>
      'التمرين يُحتسب منفصلًا. لا تُدخل النادي هنا.';

  @override
  String get trendNeedsDays => 'الاتجاه يحتاج نحو سبعة أيام';

  @override
  String get trendWeight => 'وزن الاتجاه';

  @override
  String get unitsLanguage => 'الوحدات واللغة';

  @override
  String get usuallyNow => 'عادةً تأكل في هذا الوقت';

  @override
  String get weightToday => 'الوزن اليوم';

  @override
  String get welcomeArtAlt => 'امرأة أثناء أرجحة كيتلبل';

  @override
  String get welcomeBody =>
      'سجّل طعامك في ثوانٍ، وتمرّن بخطة، وحافظ على سلسلة تستحق الحماية.';

  @override
  String get welcomeTitleEm => 'ابدأ رحلة <em>لياقتك</em> اليوم';

  @override
  String get yesterdayCopied => 'نُسخ الأمس';

  @override
  String get yrs => 'سنة';

  @override
  String addKcal(String kcal) {
    return 'أضف $kcal سعرة';
  }

  @override
  String saveKcal(String kcal) {
    return 'احفظ · $kcal سعرة';
  }

  @override
  String addToMeal(String meal) {
    return 'أضف إلى $meal';
  }

  @override
  String closedDay(String date) {
    return '$date · يوم مغلق';
  }

  @override
  String floorNote(String kcal) {
    return 'لن تُحدَّد أهدافك تحت $kcal سعرة أبدًا.';
  }

  @override
  String foodAdded(String food) {
    return 'أُضيف $food';
  }

  @override
  String foodRemoved(String food) {
    return 'حُذف $food';
  }

  @override
  String removeFood(String food) {
    return 'احذف $food';
  }

  @override
  String gPerKg(String g) {
    return '$g غ/كغ';
  }

  @override
  String heroDoneTitle(String name) {
    return '$name <em>أُنجز</em>';
  }

  @override
  String heroWeekTag(int n) {
    return 'الأسبوع $n';
  }

  @override
  String itemsLoggedTo(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سُجّل $count عنصر في $meal',
      many: 'سُجّل $count عنصرًا في $meal',
      few: 'سُجّلت $count عناصر في $meal',
      two: 'سُجّل عنصران في $meal',
      one: 'سُجّل عنصر واحد في $meal',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عنصر محدّد',
      many: '$count عنصرًا محدّدًا',
      few: '$count عناصر محدّدة',
      two: 'عنصران محدّدان',
      one: 'عنصر واحد محدّد',
      zero: 'لا عناصر',
    );
    return '$_temp0';
  }

  @override
  String kcalAndProtein(String kcal, String p) {
    return '$kcal سعرة · $p غ بروتين';
  }

  @override
  String leftToday(String kcal, String p) {
    return 'متبقٍ اليوم $kcal سعرة و$p غ بروتين';
  }

  @override
  String litres(String l) {
    return '$l ل';
  }

  @override
  String logN(int n) {
    return 'سجّل $n';
  }

  @override
  String maxPct(String pct) {
    return '$pct حد أقصى';
  }

  @override
  String meSub(String goal, int week) {
    return '$goal، الأسبوع $week';
  }

  @override
  String moreCount(int n) {
    return '+$n أخرى';
  }

  @override
  String ofTarget(String n) {
    return '/ $n غ';
  }

  @override
  String oneServing(String g) {
    return 'حصة واحدة · $g غ';
  }

  @override
  String pastNoteOver(String n) {
    return '$n فوق الهدف — يوم واحد، والمعدل الأسبوعي هو ما تقرؤه الحسابات.';
  }

  @override
  String pastNoteUnder(String n) {
    return '$n تحت الهدف. لا بأس مرة؛ أما العادة فبها تخسر أكثر من الدهون.';
  }

  @override
  String ratePerWeekShort(String pct) {
    return '$pct %/أسبوع';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count نتيجة',
      many: '$count نتيجة',
      few: '$count نتائج',
      two: 'نتيجتان',
      one: 'نتيجة واحدة',
      zero: 'لا نتائج',
    );
    return '$_temp0';
  }

  @override
  String resumeAt(String time) {
    return 'تابع · $time';
  }

  @override
  String setTo(String food, String g) {
    return 'ضُبط $food على $g غ';
  }

  @override
  String shareOfToday(int pct) {
    return '$pct% من اليوم';
  }

  @override
  String targetsHow(String mult, String rate) {
    return 'معادلة Mifflin-St Jeor × $mult، ثم سرعتك المختارة $rate% أسبوعيًا. كل شيء هنا قابل للتعديل.';
  }

  @override
  String targetsHowMaintain(String mult) {
    return 'معادلة Mifflin-St Jeor × $mult، عند الثبات. كل شيء هنا قابل للتعديل.';
  }

  @override
  String targetsLine(String p, String c, String f) {
    return 'بروتين $p غ · كربوهيدرات $c غ · دهون $f غ';
  }

  @override
  String todaySub(String date, String goal, int week) {
    return '$date · $goal، الأسبوع $week';
  }

  @override
  String todaySubDayOne(String date) {
    return '$date · اليوم الأول';
  }

  @override
  String weighInsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وزن حتى الآن',
      many: '$count وزنًا حتى الآن',
      few: '$count أوزان حتى الآن',
      two: 'وزنان حتى الآن',
      one: 'وزن واحد حتى الآن',
      zero: 'لا أوزان بعد',
    );
    return '$_temp0';
  }

  @override
  String whatDidYouHave(String meal) {
    return 'ماذا تناولت في $meal؟';
  }

  @override
  String get mealOptions => 'خيارات الوجبة';

  @override
  String get saveAsMeal => 'احفظها كوجبة';

  @override
  String get savedToMyMeals => 'حُفظت — تجدها في وجباتي';

  @override
  String get copyToTomorrow => 'انسخ إلى الغد';

  @override
  String get copiedToTomorrow => 'نُسخت إلى الغد';

  @override
  String get clearMeal => 'امسح هذه الوجبة';

  @override
  String lastLogged(String time) {
    return 'آخر تسجيل $time';
  }

  @override
  String get saveToFavourites => 'احفظ في المفضّلة';

  @override
  String get savedToFavourites => 'حُفظ في المفضّلة';

  @override
  String get removedFromFavourites => 'أُزيل من المفضّلة';

  @override
  String get saveAsCustom => 'احفظه كمخصّص';

  @override
  String get savedAsCustom => 'حُفظ كطعام مخصّص';

  @override
  String labelVerifiedOff(String brand) {
    return '$brand · ملصق موثّق · Open Food Facts';
  }

  @override
  String get noSavedMeals =>
      'لا وجبات محفوظة بعد. افتح وجبة تأكلها كثيرًا واضغط «احفظها كوجبة».';

  @override
  String get noCustomFoods =>
      'لا أطعمة مخصّصة بعد. افتح أي طعام واضغط «احفظه كمخصّص» لتحتفظ بنسختك.';

  @override
  String savedMealSub(int count, String kcal) {
    return '$count عناصر · $kcal سعرة';
  }

  @override
  String loggedSavedMeal(String name) {
    return 'سُجّلت $name';
  }

  @override
  String get yourData => 'بياناتك';

  @override
  String get yourDataSub => 'التصدير والموافقات وحذف كل شيء';

  @override
  String get takeEverything => 'خذ كل شيء معك';

  @override
  String get takeEverythingSub => 'CSV وJSON، كل الجداول';

  @override
  String foodLogRows(String n) {
    return 'سجل الطعام · $n صف';
  }

  @override
  String weighInsCount(String n) {
    return 'الأوزان · $n';
  }

  @override
  String get exportNow => 'صدّر الآن';

  @override
  String get exportFailed => 'تعذّر التصدير — حاول مرة أخرى';

  @override
  String get whatYouAgreed => 'ما وافقت عليه ومتى';

  @override
  String get consentHealthRow => 'معالجة البيانات الصحية · v1';

  @override
  String get consentAnalyticsRow => 'تحليلات مجهولة · لا شيء يُجمع';

  @override
  String get onPhoneNote =>
      'كل شيء على هذا الهاتف. لا حساب ولا خادم، فلا يخرج شيء إلا إذا صدّرته.';

  @override
  String get deleteEverything => 'احذف كل شيء';

  @override
  String get deleteEverythingSub => 'نقرة واحدة ثم تأكيد واحد';

  @override
  String get deleteEverythingBody =>
      'يُحذف سجلك وتمارينك وبرامجك وأوزانك وأهدافك فورًا. صدّر أولًا إن أردت سجلّك — لا يمكن استعادته بعد ذلك.';

  @override
  String get deleteAllData => 'احذف كل البيانات';

  @override
  String get deleteConfirmTitle => 'حذف كل شيء؟';

  @override
  String get deleteConfirm => 'نعم، احذف الكل';

  @override
  String get keepMyData => 'أبقِ بياناتي';

  @override
  String dataSetsCount(String n) {
    return 'المجموعات · $n';
  }

  @override
  String get setMacrosManually => 'سأحدد الماكروز بنفسي';

  @override
  String get useTheseMacros => 'استخدم هذه الماكروز';

  @override
  String get backToCalculated => 'عُد إلى التقسيم المحسوب';

  @override
  String manualKcal(String kcal) {
    return 'المجموع $kcal سعرة في اليوم.';
  }

  @override
  String manualBelowFloor(String kcal, String floor) {
    return 'المجموع $kcal سعرة — أقل من الحد الأدنى $floor. لا تنزل إليه إلا بإشراف مختص.';
  }

  @override
  String projectedKg(String kg) {
    return 'المتوقع $kg كغ';
  }

  @override
  String aroundDate(String date) {
    return 'حوالي $date';
  }

  @override
  String inWeeks(int n) {
    return 'خلال $n أسبوعًا';
  }

  @override
  String moreOf(String what) {
    return 'زد $what';
  }

  @override
  String lessOf(String what) {
    return 'قلّل $what';
  }

  @override
  String get trainTitleEm => 'تمرّن <em>بقوة</em>';

  @override
  String trainSub(int days, int week) {
    return '$days أيام في الأسبوع · الأسبوع $week';
  }

  @override
  String get noWeeklyPlan => 'لا خطة أسبوعية بعد';

  @override
  String dayAhead(String date) {
    return '$date · قادم';
  }

  @override
  String dayClosed(String date) {
    return '$date · مُغلق';
  }

  @override
  String get todayLbl => 'اليوم';

  @override
  String plannedOn(String day) {
    return 'مُخطط · $day';
  }

  @override
  String movedHere(String day) {
    return 'نُقل إلى هنا · كان $day';
  }

  @override
  String loggedOfPlanned(int done, int total, int sets) {
    return 'سُجّل $done من $total · $sets مجموعة مخططة';
  }

  @override
  String setsAbout(int sets, int min) {
    return '$sets مجموعة · نحو $min دقيقة';
  }

  @override
  String get startEarly => 'ابدأ مبكرًا';

  @override
  String get startAll => 'ابدأ الكل';

  @override
  String get startEarlyNote =>
      'البدء مبكرًا يقدّم بقية الأسبوع معه — الخطة تحفظ ترتيبها لا تواريخها.';

  @override
  String get lastTimeRan => 'آخر مرة نفّذتها';

  @override
  String get somethingElse => 'شيء آخر بدلًا منه';

  @override
  String restMissed(String name) {
    return 'كان $name مستحقًا ولم يُسجَّل شيء. انتقل إلى يوم تمرينك التالي — الأسبوع ينزلق والترتيب يبقى.';
  }

  @override
  String restAhead(String day) {
    return 'لا شيء مجدول. $day من أيام الراحة هذا الأسبوع.';
  }

  @override
  String get restPast =>
      'لم يُسجَّل شيء ولم يكن شيء مستحقًا. في التعافي تتحول الحصة الماضية إلى التالية.';

  @override
  String get nextSession => 'الحصة التالية';

  @override
  String get sessionAfter => 'الحصة بعدها';

  @override
  String get logAnyway => 'سجّل شيئًا على أي حال';

  @override
  String get allRoutines => 'كل البرامج';

  @override
  String allRoutinesSub(int n) {
    return '$n برامج · مكتبة تمارينك';
  }

  @override
  String weeklySetsOf(String group) {
    return 'المجموعات الأسبوعية · $group';
  }

  @override
  String hardSetsN(int n) {
    return '$n مجموعة فعّالة';
  }

  @override
  String get zoneIn => 'في النطاق المنتج';

  @override
  String get zoneUnder => 'دون النطاق المنتج';

  @override
  String get zoneOver => 'فوق النطاق المنتج';

  @override
  String get gBack => 'الظهر';

  @override
  String get gLegs => 'الأرجل';

  @override
  String get gCore => 'الجذع';

  @override
  String get closedLbl => 'مُغلق';

  @override
  String get hardSetsLbl => 'مجموعات فعّالة';

  @override
  String get bestSetEach => 'أفضل مجموعة لكل تمرين';

  @override
  String runAgain(String name) {
    return 'نفّذ $name مجددًا';
  }

  @override
  String get trainEmptyBody =>
      'لا شيء هنا بعد. ابدأ بقالب مجرّب، أو ابنِ تمامًا ما تفعله الآن.';

  @override
  String get startEmptyWorkout => 'ابدأ تمرينًا فارغًا';

  @override
  String get startEmptySub => 'أضف التمارين أثناءه — ويصبح برنامجًا بعدها';

  @override
  String get buildOwn => 'ابنِ برنامجي بنفسي';

  @override
  String get buildOwnSub => 'برامج بلا حدود، مجانًا';

  @override
  String get orTemplate => 'أو ابدأ من قالب';

  @override
  String get tplUL => 'علوي / سفلي، 4 أيام';

  @override
  String get tplULSub => '12–18 مجموعة لكل عضلة أسبوعيًا · متوسط';

  @override
  String get tplPPL => 'دفع / سحب / أرجل، 6 أيام';

  @override
  String get tplPPLSub => 'تكرار عالٍ · متقدم';

  @override
  String get tplFB => 'الجسم كاملًا، 3 أيام';

  @override
  String get tplFBSub => 'الخيار الأفضل أثناء التنشيف · أي مستوى';

  @override
  String templateAdded(String name) {
    return 'أُضيف $name إلى خطتك الأسبوعية';
  }

  @override
  String get tplUpperA => 'علوي أ';

  @override
  String get tplUpperB => 'علوي ب';

  @override
  String get tplLowerA => 'سفلي أ';

  @override
  String get tplLowerB => 'سفلي ب';

  @override
  String get tplPushA => 'دفع أ';

  @override
  String get tplPushB => 'دفع ب';

  @override
  String get tplPullA => 'سحب أ';

  @override
  String get tplPullB => 'سحب ب';

  @override
  String get tplLegsA => 'أرجل أ';

  @override
  String get tplLegsB => 'أرجل ب';

  @override
  String get tplFullA => 'جسم كامل أ';

  @override
  String get tplFullB => 'جسم كامل ب';

  @override
  String get tplFullC => 'جسم كامل ج';

  @override
  String inProgressName(String name) {
    return '$name قيد التنفيذ';
  }

  @override
  String resumeSub(String time, int done, int total) {
    return '$time · $done من $total مجموعة';
  }

  @override
  String get discardShort => 'تجاهل';

  @override
  String get workoutDiscarded => 'تم تجاهل التمرين — لم يُحفظ شيء';

  @override
  String routinesSubLib(int n) {
    return '$n برامج · واحد لكل يوم، أو أي يوم';
  }

  @override
  String get newShort => 'جديد';

  @override
  String get folderPlan => 'الخطة الأسبوعية';

  @override
  String get folderMine => 'برامجي';

  @override
  String get anyDay => 'أي يوم';

  @override
  String everyDay(String day) {
    return 'كل $day';
  }

  @override
  String routineCardSub(String when, int sets) {
    return '$when · $sets مجموعة';
  }

  @override
  String get addToFolder => 'أضف برنامجًا إلى هذا المجلد';

  @override
  String get myExercises => 'تماريني';

  @override
  String myExercisesSub(int n) {
    return '$n في المكتبة · مجانًا دائمًا';
  }

  @override
  String get exploreRoutines => 'استكشف البرامج';

  @override
  String get exploreSub => 'قوالب حجم مجموعاتها ضمن النطاق المدعوم بالأدلة';

  @override
  String optionsFor(String name) {
    return 'خيارات $name';
  }

  @override
  String get startRoutineFull => 'ابدأ البرنامج';

  @override
  String get editRoutineSub => 'التمارين وعدد المجموعات ونطاق التكرارات';

  @override
  String get duplicate => 'نسخ';

  @override
  String get duplicateSub => 'نسخة تغيّرها دون المساس بهذا';

  @override
  String get deleteRoutineSub => 'سجلك يبقى';

  @override
  String copyName(String name) {
    return 'نسخة $name';
  }

  @override
  String duplicated(String name) {
    return 'نُسخ باسم $name';
  }

  @override
  String deleteNamed(String name) {
    return 'حذف $name؟';
  }

  @override
  String get keepIt => 'أبقِه';

  @override
  String get neverRun => 'لم يُنفَّذ بعد';

  @override
  String doneOn(String date) {
    return 'نُفّذ $date';
  }

  @override
  String get estDuration => 'المدة التقديرية';

  @override
  String get exercisesLbl => 'التمارين';

  @override
  String itemLine(int sets, String reps, int rir, String rest) {
    return '$sets مجموعات · $reps تكرار @ RIR $rir · راحة $rest';
  }

  @override
  String get weekEffect => 'ما يفعله هذا بأسبوعك';

  @override
  String get weekIfSave => 'المجموعات الأسبوعية إن حفظته';

  @override
  String setsWkState(String state) {
    return 'مجموعة/أسبوع · $state';
  }

  @override
  String get inRange => 'ضمن النطاق';

  @override
  String get belowRange => 'دون النطاق';

  @override
  String get aboveRange => 'فوق النطاق';

  @override
  String get volumeNote =>
      'محسوبًا فوق ما يفعله بقية أسبوعك. عشر إلى عشرين مجموعة فعّالة لكل عضلة أسبوعيًا هو ما تدعمه الأدلة بقوة — تحته تترك نموًا، وفوقه تشتري تعبًا غالبًا.';

  @override
  String exLineLabel(String name, int sets, String reps) {
    return '$name، $sets مجموعات من $reps';
  }

  @override
  String get loggedLbl => 'سُجّل';

  @override
  String startOnItsOwn(String name) {
    return 'ابدأ $name وحده';
  }

  @override
  String builderSub(int n, int sets, int min) {
    return '$n تمارين · $sets مجموعة · نحو $min دقيقة';
  }

  @override
  String get nothingYet => 'لا شيء فيه بعد';

  @override
  String get nameLbl => 'الاسم';

  @override
  String get namePlaceholder => 'دفع أ، أرجل ثقيلة، الثلاثاء…';

  @override
  String get folderLbl => 'المجلد';

  @override
  String get dayLbl => 'اليوم';

  @override
  String dayTakenBy(String day, String name) {
    return '$day، يشغله $name';
  }

  @override
  String dayTaken(String name, String day) {
    return '$name موجود بالفعل يوم $day. الحفظ سيأخذ هذا اليوم منه.';
  }

  @override
  String get anyDayNote => 'نفّذه متى شئت — يبقى خارج الدورة الأسبوعية.';

  @override
  String get dayNote =>
      'إن فاتك ينتقل إلى يوم تمرينك التالي، محافظًا على ترتيب الخطة.';

  @override
  String get builderEmpty =>
      'لا تمارين بعد. أضف الأول وسيُظهر جيمكو أثره على مجموعاتك الأسبوعية أولًا بأول.';

  @override
  String repsChip(String reps) {
    return '$reps تكرار';
  }

  @override
  String restChip(String t) {
    return 'راحة $t';
  }

  @override
  String get oneSetFewer => 'مجموعة أقل';

  @override
  String get oneSetMore => 'مجموعة أكثر';

  @override
  String get moveUp => 'انقل لأعلى';

  @override
  String get moveDown => 'انقل لأسفل';

  @override
  String get repRangeLbl => 'نطاق التكرارات';

  @override
  String repRangeTitle(String name) {
    return 'نطاق التكرارات · $name';
  }

  @override
  String get repRangeNote =>
      'أي عدد من خمسة إلى ثلاثين تكرارًا يبني العضل إن اقتربت المجموعة من الفشل. النطاقات الأثقل تكلّف راحة ومفاصل أكثر، والأخف تكلّف انزعاجًا أكثر.';

  @override
  String restBetween(String name) {
    return 'الراحة بين المجموعات · $name';
  }

  @override
  String restBetweenSub(String t) {
    return '$t بين المجموعات';
  }

  @override
  String get restBetweenNote =>
      'هذا ما سيقترحه المؤقت أثناء التمرين. يمكنك تغييره مجموعة بمجموعة هناك.';

  @override
  String get removeFromRoutine => 'أزل من البرنامج';

  @override
  String get hintName => 'سمّه لتحفظه';

  @override
  String get hintTaken => 'هذا الاسم مستخدم';

  @override
  String get hintExercise => 'أضف تمرينًا واحدًا على الأقل';

  @override
  String get saveRoutine => 'احفظ البرنامج';

  @override
  String routineSaved(String name) {
    return 'حُفظ $name';
  }

  @override
  String get leaveTitle => 'المغادرة دون حفظ؟';

  @override
  String leaveEditing(String name) {
    return 'ستُلغى تغييراتك على $name.';
  }

  @override
  String get leaveNew => 'لم يُحفظ هذا البرنامج بعد.';

  @override
  String get keepEditing => 'متابعة التعديل';

  @override
  String get minimise => 'صغّر التمرين';

  @override
  String get restTimer => 'مؤقت الراحة';

  @override
  String get offLbl => 'متوقف';

  @override
  String get notePlaceholder => 'أضف ملاحظة — تلميح، ضبط الجهاز، كيف شعرت';

  @override
  String get setH => '#';

  @override
  String get rirLbl => 'RIR';

  @override
  String completeSet(String n) {
    return 'أكمل المجموعة $n';
  }

  @override
  String setTypeLabel(String type) {
    return 'نوع المجموعة: $type';
  }

  @override
  String get supersetBadge => 'سوبر سِت · بلا راحة بينهما';

  @override
  String get unlink => 'افصل';

  @override
  String get supersetNote =>
      'لا يبدأ المؤقت إلا بعد إنهاء الزوج. كلاهما يُحسب مجموعة كاملة لعضلاته.';

  @override
  String get emptyWorkoutBody =>
      'تمرين فارغ. الساعة تعمل بالفعل — أضف التمرين الأول متى كنت جاهزًا.';

  @override
  String restAfterEachTitle(String name) {
    return 'الراحة بعد كل مجموعة · $name';
  }

  @override
  String get restNote =>
      'ثلاث دقائق أو أكثر للتمارين المركبة الثقيلة — الراحة الأقصر تكلّفك تكرارات، والتكرارات هي المحفّز.';

  @override
  String restAfterEach(String t) {
    return '$t بعد كل مجموعة';
  }

  @override
  String get restOffFor => 'متوقف لهذا التمرين';

  @override
  String get supersetNext => 'سوبر سِت مع التمرين التالي';

  @override
  String get supersetNextSub => 'بلا راحة بينهما';

  @override
  String get seeHistory => 'اعرض السجل وأقصى تكرار';

  @override
  String get removeFromWorkout => 'أزل من هذا التمرين';

  @override
  String removedFromWorkout(String name) {
    return 'أُزيل $name من هذا التمرين';
  }

  @override
  String get nothingAfter => 'لا شيء بعده لإقرانه به';

  @override
  String get supersetted => 'تم الإقران — المؤقت ينتظر الاثنين';

  @override
  String exAdded(String name) {
    return 'أُضيف $name';
  }

  @override
  String get resting => 'راحة';

  @override
  String restingFor(String t) {
    return 'راحة، متبقٍ $t';
  }

  @override
  String nextSetOf(String name, int n) {
    return 'التالي: $name، المجموعة $n';
  }

  @override
  String get lastSetDone => 'آخر مجموعة انتهت';

  @override
  String get minus15 => '−15ث';

  @override
  String get setRemoved => 'أُزيلت المجموعة';

  @override
  String get rirTitle => 'التكرارات المتبقية';

  @override
  String get rirNote => 'كم تكرارًا إضافيًا كنت تستطيع بأداء سليم.';

  @override
  String editSetTitle(String n, String name) {
    return 'المجموعة $n · $name';
  }

  @override
  String lastTimeSet(String set) {
    return 'آخر مرة: $set';
  }

  @override
  String get nothingTicked => 'لم تُعلَّم أي مجموعة، فلم يُحفظ شيء';

  @override
  String setsUnticked(int n) {
    return '$n مجموعة بقيت دون علامة — ليست في السجل';
  }

  @override
  String doneTitle(String name) {
    return '$name — انتهى';
  }

  @override
  String get volumeExplain =>
      'الحجم هو كل مجموعة عمل مكتملة مضروبة. الإحماء في السجل لكنه ليس في هذا الرقم، ولا في عدّ مجموعاتك الأسبوعية.';

  @override
  String get prLbl => 'رقم قياسي';

  @override
  String insightIn(String group, String sets) {
    return '$group عند $sets هذا الأسبوع — ضمن نطاق 10–20 الأقوى دليلًا. لا شيء يتغيّر.';
  }

  @override
  String insightUnder(String group, String sets) {
    return '$group عند $sets هذا الأسبوع — دون نطاق 10–20. حصة أو اثنتان تضعه فيه.';
  }

  @override
  String insightOver(String group, String sets) {
    return '$group عند $sets هذا الأسبوع — فوق 20. بعدها غالبًا تعب فقط.';
  }

  @override
  String get saveAsRoutine => 'احفظه كبرنامج';

  @override
  String get share => 'مشاركة';

  @override
  String shareText(String name, String time, String volume, String sets) {
    return '$name · $time · $volume · $sets مجموعة فعّالة';
  }

  @override
  String soloLogged(String name) {
    return 'سُجّل $name — بقية اليوم ما زالت هناك';
  }

  @override
  String get est1rm => 'أقصى تكرار تقديري';

  @override
  String trendKg(String delta, int w) {
    return '$delta كغ / $w أسابيع';
  }

  @override
  String get months6 => '6 أشهر';

  @override
  String get chartNeedsTwo => 'تمرينان بهذا التمرين ويبدأ خط الاتجاه.';

  @override
  String get best5 => 'أفضل 5 تكرارات';

  @override
  String get best8 => 'أفضل 8 تكرارات';

  @override
  String get setsWk => 'مجموعة / أسبوع';

  @override
  String get exClimbing =>
      'هذا التمرين ما زال يرتفع. أيًّا كان ما تفعله بالعجز فهو محتمل — لا سبب للإبطاء بعد.';

  @override
  String get exFlat => 'ثابت. في العجز، الثبات انتصار.';

  @override
  String get exDropping =>
      'أقل مما كان قبل ثمانية أسابيع. راجع النوم وحجم العجز قبل لوم البرنامج.';

  @override
  String get exNoHistory => 'لا سجل بعد. سجّله مرة ويبدأ اتجاه أقصى تكرار هنا.';

  @override
  String get historyLbl => 'السجل';

  @override
  String get back => 'رجوع';

  @override
  String get addAnExercise => 'أضف تمرينًا';

  @override
  String get searchLibrary => 'ابحث في مكتبة التمارين';

  @override
  String get noExerciseMatch => 'لا نتائج. جرّب كلمة أقصر أو عضلة أخرى.';

  @override
  String get inLbl => 'مُضاف';

  @override
  String get alreadyIn => 'موجود في هذا التمرين';

  @override
  String thenEx(String name) {
    return 'بعدها: $name';
  }

  @override
  String get progressTitleEm => '<em>تقدّمك</em>';

  @override
  String get addWeighIn => 'أضف وزنًا';

  @override
  String get weightTab => 'الوزن';

  @override
  String get measureTab => 'القياسات';

  @override
  String get strengthTab => 'القوة';

  @override
  String get openCheckIn => 'افتح مراجعة هذا الأسبوع';

  @override
  String get weighInToday => 'وزن اليوم';

  @override
  String get weighInNote =>
      'الوقت نفسه والميزان نفسه قبل الفطور. وزن واحد لا يعني الكثير؛ خط الاتجاه هو المهم.';

  @override
  String get weighInSaved => 'حُفظ الوزن';

  @override
  String get waistToday => 'محيط الخصر اليوم';

  @override
  String get waistNote => 'عند السرّة، مسترخيًا، بعد الزفير.';

  @override
  String get measurementSaved => 'حُفظ القياس';

  @override
  String get rateLbl => 'المعدل';

  @override
  String pctWk(String v) {
    return '$v %/أسبوع';
  }

  @override
  String get trendNeedsTwo => 'وزنان بينهما أيام قليلة ويبدأ خط الاتجاه.';

  @override
  String get sinceStart => 'منذ البداية';

  @override
  String get waistLbl => 'الخصر';

  @override
  String get weighInsLbl => 'الأوزان';

  @override
  String get weeklyHardSets => 'المجموعات الفعّالة أسبوعيًا';

  @override
  String get indirectHalf => 'غير المباشرة تُحسب ½';

  @override
  String get noSetsThisWeek => 'لا مجموعات مسجّلة هذا الأسبوع بعد.';

  @override
  String get allInRange =>
      'كل عضلة تدرّبت عليها أكثر بلغت 10 مجموعات أو أكثر هذا الأسبوع.';

  @override
  String underTen(String group) {
    return '$group دون حد العشر مجموعات. يستحق النظر بعد انتهاء العجز — لا يُصلح بزيادة الحجم الآن.';
  }

  @override
  String get waistWhy =>
      'الخصر يتحرك أبطأ من الميزان لكنه أصدق: الماء والطعام لا يكادان يؤثران فيه.';

  @override
  String get addMeasurement => 'أضف قياسًا';

  @override
  String get strengthEmpty =>
      'لا تمارين مسجّلة بعد. أنهِ تمرينًا وستظهر هنا تقديرات أقصى تكرار.';

  @override
  String get strengthNote =>
      'أقصى تكرار تقديري الآن والتغيّر خلال ثمانية أسابيع. في العجز، الثبات انتصار.';

  @override
  String e1rmLine(String kg) {
    return 'أقصى تكرار تقديري $kg كغ';
  }

  @override
  String get yourWeek => 'أسبوعك';

  @override
  String get flatWeeks => 'فترة ثابتة';

  @override
  String checkInSub(String range, int week) {
    return '$range · الأسبوع $week';
  }

  @override
  String get adjustBtn => 'عدّل';

  @override
  String get acceptTargets => 'اقبل الأهداف';

  @override
  String get laterBtn => 'لاحقًا';

  @override
  String get notNow => 'ليس الآن';

  @override
  String applyKcal(String n) {
    return 'طبّق $n سعرة';
  }

  @override
  String get applyChoice => 'طبّق';

  @override
  String get startBreak => 'ابدأ الاستراحة';

  @override
  String targetsUpdated(String kcal) {
    return 'حُدّثت الأهداف · $kcal سعرة';
  }

  @override
  String get askedNextWeek => 'تم — سنسأل مجددًا الأسبوع القادم';

  @override
  String get needsTwoWeighIns => 'يحتاج أوزانًا بينها أسبوع';

  @override
  String get onPlan => 'حسب الخطة';

  @override
  String get fasterThanPlan => 'أسرع من الخطة';

  @override
  String get slowerThanPlan => 'أبطأ من الخطة';

  @override
  String get rateVsGoal => 'المعدل مقابل الهدف';

  @override
  String get daysLogged => 'الأيام المسجّلة';

  @override
  String nOfSeven(int n) {
    return '$n من 7';
  }

  @override
  String get allSevenDays => 'كل يوم';

  @override
  String get fullDaysOnly => 'الأيام الكاملة فقط';

  @override
  String get measuredExpenditure => 'الإنفاق المقيس';

  @override
  String get notMeasuredYet => 'لم يُقَس بعد';

  @override
  String notEnoughBody(int n) {
    return '$n أيام مسجّلة كاملة أخرى ويقيس جيمكو ما تحرقه فعلًا. حتى ذلك الحين تبقى أهدافك كما هي.';
  }

  @override
  String expenditureShort(String kcal) {
    return 'من سجلاتك ووزن الاتجاه تحرق نحو $kcal سعرة يوميًا.';
  }

  @override
  String expenditureFell(String intake, String kg, String kcal) {
    return 'كان متوسطك $intake سعرة وانخفض الاتجاه $kg كغ. لا يستقيم ذلك إلا إن كنت تحرق نحو $kcal.';
  }

  @override
  String expenditureRose(String intake, String kg, String kcal) {
    return 'كان متوسطك $intake سعرة وارتفع الاتجاه $kg كغ. لا يستقيم ذلك إلا إن كنت تحرق نحو $kcal.';
  }

  @override
  String get nextWeekTargets => 'أهداف الأسبوع القادم';

  @override
  String get noChange => 'بلا تغيير';

  @override
  String kcalChange(String n) {
    return '$n سعرة';
  }

  @override
  String get targetsMoveNote =>
      'البروتين والدهون ثابتان؛ والتغيير يذهب للكربوهيدرات حيث يفيد تمارينك. التغيير الأسبوعي محدود بـ120 سعرة حتى لا يقلب أسبوع غريب نظامك.';

  @override
  String get targetsHoldNote =>
      'لا شيء يتغيّر حتى يُقاس الإنفاق. واصل تسجيل أيام كاملة ووزن نفسك.';

  @override
  String get dietMeetsTraining => 'النظام الغذائي والتمرين';

  @override
  String get strengthHolding =>
      'تمارينك الأساسية ثابتة أو في ارتفاع وأنت تخسر الوزن. العضل صامد — هذا العجز محتمل جيدًا. لا حاجة لتغيير.';

  @override
  String get strengthSlipping =>
      'أحد تمارينك الأساسية انخفض. راقبه الأسبوع القادم؛ وإن تبعه غيره فأبطئ التنشيف.';

  @override
  String get fasterThanPlanned => 'هذا أسرع من المخطط';

  @override
  String get perWeekLbl => 'في الأسبوع';

  @override
  String fastBody(String goal) {
    return 'طلبت $goal%. بهذا المعدل جزء كبير مما تخسره عضل على الأرجح.';
  }

  @override
  String get intakeLbl => 'المدخول';

  @override
  String floorIs(String n) {
    return 'الحد الأدنى $n';
  }

  @override
  String get measuredShort => 'المحروق';

  @override
  String get whatToDo => 'ماذا تريد أن تفعل؟';

  @override
  String eatMore(String n) {
    return 'كُل $n سعرة إضافية يوميًا';
  }

  @override
  String eatMoreSub(String goal) {
    return 'عودة نحو $goal% أسبوعيًا. مُوصى به.';
  }

  @override
  String get twoWeeksMaintenance => 'أسبوعان على الثبات';

  @override
  String get maintenanceThenResume => 'استراحة ثم العودة للمعدل المخطط';

  @override
  String get keepGoingAsIAm => 'أكمل كما أنا';

  @override
  String get askedAgain => 'سيطرح جيمكو هذا مجددًا الأسبوع القادم';

  @override
  String floorWarnNote(String n) {
    return 'لا تُضبط الأهداف أبدًا تحت $n سعرة. يمكنك النزول إن أردت، لكنك ستكتب الرقم بنفسك بعد قراءة هذه الرسالة.';
  }

  @override
  String stallBody(int weeks) {
    return 'بعد $weeks أسابيع، بالكاد تحرّك الاتجاه منذ أسبوعين. الإنفاق ينخفض في الحمية الطويلة — أمر طبيعي وجزء من سبب التوقف.';
  }

  @override
  String get threeOptions => 'ثلاثة خيارات صادقة';

  @override
  String maintenanceSub(String kcal) {
    return '$kcal سعرة بلا عجز. في الغالب يمنحك هذا استراحة من الحمية.';
  }

  @override
  String get checkLogging => 'راجع التسجيل أولًا';

  @override
  String get checkLoggingSub =>
      'العطلات والوجبات الخفيفة هي غالبًا بداية الأسابيع الثابتة.';

  @override
  String get cut150 => 'اقطع 150 سعرة إضافية يوميًا';

  @override
  String get cut150Sub => 'ينجح، لكنه بعد هذه المدة الخيار الأكثر كلفة للعضل.';

  @override
  String get dietBreakEvidence =>
      'لن يعدك جيمكو بإعادة ضبط الأيض. استراحات الحمية ساعدت في بعض التجارب ولم تساعد في غيرها. ما تفعله بثبات هو جعل الأسابيع التالية محتملة.';

  @override
  String get awardsTitle => 'الجوائز';

  @override
  String get awardsTitleEm => '<em>جوائزك</em>';

  @override
  String get editGoal => 'عدّل الهدف';

  @override
  String commitmentDays(int n) {
    return 'التزام $n يومًا';
  }

  @override
  String keptOfGoal(int kept, int goal) {
    return '$kept من $goal يومًا محفوظًا';
  }

  @override
  String nextAwardIn(String name, int n) {
    return 'الجائزة التالية: $name خلال $n يوم';
  }

  @override
  String get allStreakAwards => 'نلت كل جوائز السلسلة';

  @override
  String ofDays(int n) {
    return '/ $n يومًا';
  }

  @override
  String legendStreak(int n) {
    return 'السلسلة · متبقٍ $n';
  }

  @override
  String legendFood(int n) {
    return 'الطعام · $n من 3 وجبات';
  }

  @override
  String get legendTrainDone => 'التمرين · تم';

  @override
  String get legendRest => 'التمرين · يوم راحة';

  @override
  String legendPlanned(String name) {
    return 'التمرين · $name مخطط';
  }

  @override
  String dayKept(int n) {
    return 'اليوم $n محفوظ. نراك غدًا.';
  }

  @override
  String logToKeep(String meal, int n) {
    return 'سجّل $meal لتحفظ اليوم $n';
  }

  @override
  String trainToKeep(String name, int n) {
    return 'أنهِ $name لتحفظ اليوم $n';
  }

  @override
  String get logBtn => 'سجّل';

  @override
  String get trainBtn => 'تمرّن';

  @override
  String goalReached(int n) {
    return '$n يومًا. أتممت التزامك.';
  }

  @override
  String get seeRecap => 'اعرض الملخص';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get restDaysCount => 'أيام الراحة تُحسب';

  @override
  String get bestStreak => 'أفضل سلسلة';

  @override
  String nDays(int n) {
    return '$n يوم';
  }

  @override
  String get freezesLbl => 'التجميد';

  @override
  String freezesOf(int n, int max) {
    return '$n من $max';
  }

  @override
  String challengeDone(int n) {
    return 'تم — $n حصة هذا الشهر';
  }

  @override
  String challengeLeft(int n, int days) {
    return 'تمرّن $n مرة هذا الشهر · متبقٍ $days يوم';
  }

  @override
  String get shelfStreaks => 'السلاسل';

  @override
  String get shelfFood => 'الطعام';

  @override
  String get shelfTraining => 'التمرين';

  @override
  String gotOf(int got, int n) {
    return '$got من $n';
  }

  @override
  String get awardsNote =>
      'لا جائزة هنا لأكل أقل أو خسارة وزن. التسجيل والحضور هما ما يُحسب.';

  @override
  String get earnedLbl => 'مُنحت';

  @override
  String earnedOn(String date) {
    return 'مُنحت $date';
  }

  @override
  String get earnedLabel => 'مُنحت';

  @override
  String get lockedLabel => 'مقفلة';

  @override
  String get restartAfterBreak => 'ابدأ من جديد بعد انقطاع';

  @override
  String nToGo(int n) {
    return 'متبقٍ $n';
  }

  @override
  String get progressLbl => 'التقدّم';

  @override
  String nextNamed(String name) {
    return 'التالية · $name';
  }

  @override
  String get shareAward => 'مشاركة';

  @override
  String shareAwardText(String name) {
    return 'نلت «$name» على جيمكو.';
  }

  @override
  String get backToAwards => 'العودة إلى الجوائز';

  @override
  String get mdDays => 'يوم';

  @override
  String get mdMeals => 'وجبة';

  @override
  String get mdProtein => 'بروتين';

  @override
  String get mdWorkouts => 'تمرين';

  @override
  String get mdBests => 'أرقام';

  @override
  String get awFirstWeek => 'الأسبوع الأول';

  @override
  String get awFirstWeekD =>
      'سبعة أيام متتالية بكل وجبة مسجّلة وكل تمرين أو يوم راحة مخطط محفوظ.';

  @override
  String get awTwoWeeks => 'أسبوعان';

  @override
  String get awTwoWeeksD =>
      'أربعة عشر يومًا محفوظًا متتاليًا. الأسبوع الأول حماس، والثاني اختيار.';

  @override
  String get awOneMonth => 'شهر من القوة';

  @override
  String get awOneMonthD =>
      'ثلاثون يومًا متتاليًا بكل وجبة مسجّلة وكل تمرين أو يوم راحة مخطط محفوظ.';

  @override
  String get awHabit => 'عادة راسخة';

  @override
  String get awHabitD =>
      'ستة وستون يومًا، متوسط ما يحتاجه سلوك جديد ليصبح تلقائيًا.';

  @override
  String get awFull => 'التزام كامل';

  @override
  String get awFullD =>
      'تسعون يومًا محفوظًا. ثلاثة أشهر من الحضور، بما فيها أيام الراحة.';

  @override
  String get awComeback => 'العودة';

  @override
  String get awComebackD =>
      'ابدأ سلسلة جديدة بعد انتهاء أخرى. العودة هي ما يُحسب.';

  @override
  String get awFirstFullDay => 'أول يوم كامل';

  @override
  String get awFirstFullDayD => 'فطور وغداء وعشاء مسجّلة في يوم واحد.';

  @override
  String get awHundredMeals => '100 وجبة مسجّلة';

  @override
  String get awHundredMealsD =>
      'مئة وجبة مسجّلة. التقديرات التقريبية تُحسب — المهم أن يُكتب اليوم.';

  @override
  String get awProteinWeek => 'أسبوع البروتين';

  @override
  String get awProteinWeekD =>
      'بلغت هدف البروتين سبعة أيام في أسبوع واحد. إنه الرقم الذي يحمي العضل أثناء التنشيف.';

  @override
  String get awFirstWorkout => 'أول تمرين';

  @override
  String get awFirstWorkoutD => 'أول حصة مسجّلة لك في جيمكو.';

  @override
  String get awTwentyFive => '25 تمرينًا';

  @override
  String get awTwentyFiveD => 'خمس وعشرون حصة مسجّلة مجموعة بمجموعة.';

  @override
  String get awTenBests => '10 أرقام قياسية';

  @override
  String get awTenBestsD =>
      'عشر مجموعات قياسية جديدة. ثبات القوة في العجز علامة على أن التنشيف يسير جيدًا.';

  @override
  String awMonth(String month) {
    return 'تحدّي $month';
  }

  @override
  String awMonthD(int n) {
    return 'تمرّن $n مرة هذا الشهر.';
  }

  @override
  String get yourCommitment => 'التزامك';

  @override
  String get howLong => 'إلى متى أنت ملتزم؟';

  @override
  String get howLongSub =>
      'اختر عددًا من الأيام. كل يوم تحفظه يملأ الحلقة الخارجية.';

  @override
  String get daysWord => 'يومًا';

  @override
  String get goal21 => 'ابدأ';

  @override
  String get goal30 => 'شهر واحد';

  @override
  String get goal66 => 'اجعلها عادة';

  @override
  String get goal90 => 'التزام كامل';

  @override
  String get customLbl => 'مخصّص';

  @override
  String get customRange => '7 – 365 يومًا';

  @override
  String get useThis => 'استخدم هذا';

  @override
  String get dayCountsWhen => 'يُحسب اليوم عندما';

  @override
  String get ruleMeals => 'تُسجَّل الوجبات';

  @override
  String get ruleMealsSub => 'التسجيل هو ما يُحسب، لا الأكل الأقل';

  @override
  String get ruleTrain => 'تتمرّن أو ترتاح حسب الخطة';

  @override
  String get ruleTrainSub => 'أيام الراحة في خطتك تحفظ السلسلة';

  @override
  String freezeNote(int n, int max) {
    return 'احصل على تجميد كل $n أيام تحفظها. احتفظ بحتى $max للمرض والسفر.';
  }

  @override
  String alreadyPast(int n) {
    return 'تجاوزت $n يومًا — اختر أطول';
  }

  @override
  String keepMyDays(int n) {
    return 'أبقِ أيامي الـ$n';
  }

  @override
  String commitTo(int n) {
    return 'التزم بـ$n يومًا';
  }

  @override
  String carryOver(int n, String date) {
    return 'أيامك المحفوظة الـ$n تُحتسب · ينتهي $date';
  }

  @override
  String startsToday(String date) {
    return 'يبدأ اليوم · ينتهي $date';
  }

  @override
  String goalDoneTitle(int n) {
    return '$n يومًا. تم.';
  }

  @override
  String goalDoneSub(String from, String to, int n) {
    return '$from – $to · $n تجميد مستخدم';
  }

  @override
  String get workoutsLbl => 'التمارين';

  @override
  String get restDaysKept => 'أيام الراحة المحفوظة';

  @override
  String get mealsLoggedLbl => 'الوجبات المسجّلة';

  @override
  String get personalBests => 'الأرقام القياسية';

  @override
  String get goalDoneNote => 'الحضور، بما فيه أيام الراحة. هكذا تبدو العادة.';

  @override
  String shareMyDays(int n) {
    return 'شارك أيامي الـ$n';
  }

  @override
  String shareGoalText(int n) {
    return '$n يومًا محفوظًا على جيمكو — كل وجبة مسجّلة وكل تمرين ويوم راحة منجز.';
  }

  @override
  String get setNextCommitment => 'حدّد التزامك التالي';

  @override
  String get writeHint =>
      '200 غ صدر دجاج، 150 غ رز و10 غ زيت زيتون\nبيضتين مع شريحتين خبز\nسكوب واي بروتين';

  @override
  String get writeEmpty =>
      'اكتب الوجبة كما تقولها. الكميات بالغرام أو بالعدد مثل «بيضتين» و«سكوب»، كلاهما يعمل.';

  @override
  String itRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'قرأ $n عنصرًا',
      few: 'قرأ $n عناصر',
      two: 'قرأ عنصرين',
      one: 'قرأ عنصرًا واحدًا',
      zero: 'لم يقرأ أي عنصر',
    );
    return '$_temp0';
  }

  @override
  String nAssumed(int n) {
    return '$n مُقدَّر';
  }

  @override
  String get assumedTag => 'مُقدَّر';

  @override
  String get notInDbYet => 'غير موجود في قاعدة البيانات بعد';

  @override
  String get searchAction => 'بحث';

  @override
  String get assumedNote =>
      'الصفوف المعلّمة «مُقدَّر» لم تُكتب لها كمية، فاستُخدمت حصة عادية. اضغط على الصف لتحديد الكمية.';

  @override
  String addN(int n) {
    return 'أضف $n';
  }

  @override
  String pcfLine(String p, String c, String f) {
    return 'ب $p · ك $c · د $f';
  }

  @override
  String writtenSub(String g, String kcal, String p) {
    return '$g غ · $kcal سعرة · $p غ بروتين';
  }

  @override
  String removeNamed(String name) {
    return 'إزالة $name';
  }

  @override
  String howMuchOf(String name) {
    return 'كم من $name؟';
  }

  @override
  String get gramsNote => 'بالغرام، كما أُكل.';

  @override
  String get voiceHold =>
      'اضغط مطولًا وقل ما أكلت. يمر عبر نفس القارئ المستخدم في الكتابة.';

  @override
  String get voiceListening => 'أستمع… اترك الزر عند الانتهاء.';

  @override
  String get voiceHeard => 'سمعتها. راجع النص قبل الإضافة.';

  @override
  String get transcriptLbl => 'النص · عدّله إن أخطأ السمع';

  @override
  String get voiceUnavailable =>
      'الإملاء غير متاح على هذا الهاتف أو الميكروفون مغلق لـ Gymco. اكتبها بدلًا من ذلك.';

  @override
  String get dictateMeal => 'أملِ الوجبة';

  @override
  String get accountTitle => 'الحساب';

  @override
  String get accountRowSub => 'النسخ الاحتياطي والتسجيل بالصور';

  @override
  String accountRowSignedIn(String email) {
    return 'مسجّل الدخول · $email';
  }

  @override
  String get accountRowOff => 'على الهاتف فقط';

  @override
  String get signInTitle => 'احفظ نسخة في حساب';

  @override
  String get signInSub => 'بريدك ورابط تسجيل دخول — بلا كلمة مرور';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get codeHint => 'رمز من 6 أرقام';

  @override
  String get sendCode => 'أرسل رابط الدخول';

  @override
  String get signInAction => 'تسجيل الدخول';

  @override
  String codeSentTo(String email) {
    return 'أرسلنا رابط تسجيل دخول إلى $email. افتحه على هذا الهاتف وسيسجّل Gymco دخولك. وإن كان في البريد رمز، اكتبه هنا.';
  }

  @override
  String get useOtherEmail => 'استخدم بريدًا آخر';

  @override
  String get accountWhy =>
      'يومياتك تبقى على هذا الهاتف في كل الأحوال. الحساب يضيف نسخة احتياطية تستعيدها على هاتف جديد، والتسجيل بالصور — 10 صور يوميًا مجانًا.';

  @override
  String get cloudNotSetUp =>
      'الحسابات غير مفعّلة في هذا الإصدار. كل شيء آخر يعمل على الهاتف.';

  @override
  String get signedInAs => 'مسجّل الدخول';

  @override
  String get backupTitle => 'النسخ الاحتياطي';

  @override
  String backedUpAt(String when) {
    return 'آخر نسخة $when';
  }

  @override
  String get notBackedUp => 'لا توجد نسخة بعد';

  @override
  String get backupAuto =>
      'يُنسخ تلقائيًا عند مغادرة التطبيق، مرة كل ست ساعات على الأكثر.';

  @override
  String get backupNow => 'انسخ الآن';

  @override
  String get backupDone => 'تم النسخ';

  @override
  String get restoreAction => 'استعادة من النسخة';

  @override
  String get restoreTitle => 'استعادة هذه النسخة؟';

  @override
  String restoreBody(String when) {
    return 'نسخة $when ستحل محل ما على هذا الهاتف الآن.';
  }

  @override
  String get foundBackupTitle => 'في حسابك نسخة احتياطية';

  @override
  String foundBackupBody(String when) {
    return 'من $when. استعدها على هذا الهاتف، أو احتفظ بما على الهاتف وانسخه بدلًا منها.';
  }

  @override
  String get restoreIt => 'استعدها';

  @override
  String get keepThisPhone => 'احتفظ ببيانات هذا الهاتف';

  @override
  String get restored => 'تمت الاستعادة';

  @override
  String get noBackupYet => 'لا توجد نسخة في هذا الحساب بعد';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutNote => 'تسجيل الخروج يبقي كل شيء على هذا الهاتف.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountSub => 'الحساب ونسخته الاحتياطية';

  @override
  String get deleteAccountBody =>
      'يُحذف الحساب ونسخته الآن. ما على هذا الهاتف يبقى؛ احذفه من «بياناتك».';

  @override
  String get deleteAccountConfirm => 'احذف الحساب والنسخة';

  @override
  String get accountDeleted => 'حُذف الحساب';

  @override
  String get errOffline => 'لا اتصال. حاول مجددًا عند الاتصال.';

  @override
  String get errBadCode => 'الرمز لم يعمل. تحقق منه أو أرسل رمزًا جديدًا.';

  @override
  String get errBusy => 'محاولات كثيرة الآن. انتظر دقيقة وحاول مجددًا.';

  @override
  String get errGeneric => 'حدث خطأ. حاول مجددًا.';

  @override
  String get photoPrompt =>
      'صوّر الطبق. يقترح Gymco ما يراه، وأنت تحدد الكمية.';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get choosePhoto => 'اختر من الصور';

  @override
  String get readingPlate => 'أنظر إلى الطبق…';

  @override
  String plateThings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n شيئًا في الطبق',
      few: '$n أشياء في الطبق',
      two: 'شيئان في الطبق',
      one: 'شيء واحد في الطبق',
      zero: 'لا شيء واضح في الطبق',
    );
    return '$_temp0';
  }

  @override
  String get tapToConfirm => 'اضغط للتأكيد';

  @override
  String get fairlyConfident => 'واثق إلى حد ما';

  @override
  String get notSureCheck => 'غير متأكد — راجع هذا';

  @override
  String get photoAmountNote =>
      'الكميات مقدّرة من الصورة ووصفك، والأطعمة غير الموجودة في قاعدة البيانات تستخدم أرقام الذكاء الاصطناعي. اضغط على أي طعام لمراجعته قبل الإضافة.';

  @override
  String get photoNeedsAccount =>
      'التسجيل بالصور يحتاج حسابًا: تُقرأ الصورة على خادمنا، 10 يوميًا مجانًا. الكتابة والبحث يعملان بدونه.';

  @override
  String get photoNotSetUp =>
      'التسجيل بالصور غير مفعّل في هذا الإصدار. اكتب أو ابحث بدلًا من ذلك.';

  @override
  String scansLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n صورة متبقية اليوم',
      few: '$n صور متبقية اليوم',
      two: 'صورتان متبقيتان اليوم',
      one: 'صورة واحدة متبقية اليوم',
      zero: 'لا صور متبقية اليوم',
    );
    return '$_temp0';
  }

  @override
  String photoCap(int n) {
    return 'انتهت صور اليوم ($n). تعود غدًا؛ اكتب أو ابحث في الأثناء.';
  }

  @override
  String get gateUpdateTitle => 'حان وقت تحديث Gymco';

  @override
  String get gateUpdateBody =>
      'لم يعد هذا الإصدار قادرًا على المزامنة أو النسخ الاحتياطي بأمان. حدّث للمتابعة؛ كل ما على هاتفك يبقى.';

  @override
  String get gateUpdateCta => 'تحديث';

  @override
  String get gateSuggest => 'إصدار أحدث من Gymco جاهز.';

  @override
  String get gateLater => 'لاحقًا';

  @override
  String get gateRestingTitle => 'Gymco في استراحة';

  @override
  String get photoPaused =>
      'تسجيل الصور في استراحة حتى الغد. الكتابة والبحث ما زالا يعملان.';

  @override
  String get photoRefused => 'تعذّرت قراءة هذه الصورة. جرّب صورة أخرى.';

  @override
  String get photoAgain => 'التقط أخرى';

  @override
  String get notInDbSearch => 'غير موجود على الهاتف — ابحث عنه';

  @override
  String get badgeTurnHint => 'اسحب أو اضغط لقلبها';

  @override
  String badgeBackLabel(String name, String date) {
    return 'ظهر الشارة: $name، نُلت في $date';
  }

  @override
  String get photoNoteHint =>
      'أضف تفاصيل (اختياري) — كم، وما المكونات. «4 بيتزا صغيرة باللحم والشيدر»';

  @override
  String get dictateNote => 'قل التفاصيل';

  @override
  String get estimateFromNote => 'قدّر من الوصف';

  @override
  String aboutGramsKcal(String g, String kcal) {
    return '≈ $g غ · $kcal سعرة';
  }

  @override
  String get aiEstimateShort => 'تقدير الذكاء الاصطناعي';

  @override
  String get aiEstimateLabel => 'تقدير الذكاء الاصطناعي · راجع الأرقام';

  @override
  String addAllKcal(int n, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'أضف الـ$n · $kcal سعرة',
      few: 'أضف الـ$n · $kcal سعرة',
      two: 'أضف الاثنين · $kcal سعرة',
      one: 'أضفه · $kcal سعرة',
    );
    return '$_temp0';
  }

  @override
  String get estimateAction => 'قدّر';

  @override
  String showPhotosOf(String name) {
    return 'عرض صور $name';
  }

  @override
  String get closePhotos => 'إغلاق';

  @override
  String get proTitle => 'جيمكو <em>برو</em>';

  @override
  String get proBadge => 'برو';

  @override
  String get proFreeTesting => 'مجاني أثناء التجربة';

  @override
  String get proSub => 'تدريب يتكيّف معك كل أسبوع.';

  @override
  String get proPoint1 => 'أهداف متكيّفة + مراجعة أسبوعية';

  @override
  String get proPoint2 => 'القوة مقابل العجز في السعرات';

  @override
  String get proPoint3 => 'الحجم لكل عضلة، والسجل الكامل';

  @override
  String get proCta => 'برو مفعّل';

  @override
  String get proCtaSub => 'كل ميزات برو مفتوحة للمختبرين';

  @override
  String get proCardLabel => 'جيمكو برو، مجاني أثناء التجربة';

  @override
  String get freeVsPro => 'المجاني مقابل برو';

  @override
  String get proHeadline => 'ادفع مقابل التدريب، لا مقابل الأساسيات';

  @override
  String get proHeadlineSub =>
      'مسح الباركود والأطعمة المخصصة والروتينات غير المحدودة تبقى مجانية. دائمًا، لا لفترة تجريبية.';

  @override
  String get freeForever => 'مجاني للأبد';

  @override
  String get freeBarcode => 'مسح الباركود';

  @override
  String get freeCustomFoods => 'أطعمة مخصصة';

  @override
  String get freeRecipes => 'وصفات';

  @override
  String get freeCopyDay => 'نسخ اليوم';

  @override
  String get freeRoutines => 'روتينات غير محدودة';

  @override
  String get freeCustomExercises => 'تمارين مخصصة';

  @override
  String get freeRestTimer => 'مؤقت الراحة';

  @override
  String get freeTrendWeight => 'اتجاه الوزن';

  @override
  String get freeExport => 'تصدير كامل';

  @override
  String get proAdds => 'برو يضيف';

  @override
  String get proAdds1Lead => 'استهلاك متكيّف';

  @override
  String get proAdds1 => 'والمراجعة الأسبوعية';

  @override
  String get proAdds2Lead => 'القوة مقابل العجز';

  @override
  String get proAdds2 => '— معلومة لا يقدّمها لك أي تطبيق آخر';

  @override
  String get proAdds3 => 'أنواع الأيام، تدوير السعرات، استراحات الحمية';

  @override
  String get proAdds4 => 'الحجم لكل عضلة، السجل الكامل، مقارنة الصور';

  @override
  String get planMonthly => 'شهري';

  @override
  String get planYearly => 'سنوي';

  @override
  String get planYearlySub => '‏3.33 € في الشهر';

  @override
  String get planLifetime => 'مدى الحياة';

  @override
  String get proTestingNote =>
      'جيمكو قيد التجربة، لذا لا شيء للبيع بعد وكل ميزات برو مفعّلة. هذه هي الأسعار المخطط لها عند الإطلاق.';

  @override
  String get proOnAction => 'فهمت — برو مفعّل';

  @override
  String get proKeepNote =>
      'إذا انتهى برو يومًا ما تحتفظ بكل ميزات القائمة المجانية، وتبقى بياناتك ملكك في كل الأحوال.';

  @override
  String confirmLogTitle(String meal) {
    return 'إضافة إلى $meal؟';
  }

  @override
  String get confirmLogAction => 'تأكيد وإضافة';

  @override
  String awardsButton(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'الجوائز، $n جائزة',
      few: 'الجوائز، $n جوائز',
      two: 'الجوائز، جائزتان',
      one: 'الجوائز، جائزة واحدة',
      zero: 'الجوائز',
    );
    return '$_temp0';
  }

  @override
  String get welcomeLogTitleEm => 'سجّل طعامك <em>بطريقتك</em>';

  @override
  String get welcomeLogBody =>
      'اكتبه أو قله أو التقط صورة أو امسح الباركود. يقرأ جيمكو الوجبة وتؤكدها قبل إضافتها.';

  @override
  String get welcomeLogAlt => 'رجل يسجّل وجبة على هاتفه';

  @override
  String get welcomeTrainTitleEm => 'تمرّن <em>بخطة</em>';

  @override
  String get welcomeTrainBody =>
      'روتينات لأسبوعك، وأكثر من 870 تمرينًا بالصور، ومؤقت راحة، وأرقام المرة الماضية في كل مجموعة.';

  @override
  String get welcomeTrainAlt => 'امرأة ترفع الدمبل فوق رأسها';

  @override
  String get welcomeProgressTitleEm => 'شاهد <em>تقدّمك</em>';

  @override
  String get welcomeProgressBody =>
      'وزن اتجاهي يتجاهل تقلبات الأيام، وقوة تحافظ عليها أثناء التنشيف، وجوائز على الالتزام.';

  @override
  String get welcomeProgressAlt => 'رياضي يحتفل بين ميداليات الجوائز';

  @override
  String get hydration => 'الترطيب';

  @override
  String ofLitres(String l) {
    return 'من $l لتر';
  }

  @override
  String get goalMet => 'تحقق الهدف';

  @override
  String get waterGlass => 'كوب';

  @override
  String get waterBottle => 'زجاجة';

  @override
  String get waterLarge => 'كبيرة';

  @override
  String get undoLastDrink => 'تراجع عن آخر شربة';

  @override
  String addWaterMl(int ml) {
    return 'أضف $ml مل من الماء';
  }

  @override
  String waterAddedMl(int ml) {
    return 'تمت إضافة $ml مل';
  }

  @override
  String get waterGoalReached => 'وصلت لهدف الماء — أحسنت';

  @override
  String get waterTrainingBonus => 'يشمل ‎+0.5 لتر لتمرين اليوم';

  @override
  String get waterToday => 'الماء اليوم';

  @override
  String get noWaterYet => 'لم يُسجّل شيء اليوم بعد.';

  @override
  String mlAmount(String ml) {
    return '$ml مل';
  }

  @override
  String get removeDrink => 'احذف هذه الشربة';

  @override
  String get otherAmount => 'كمية أخرى';

  @override
  String get dailyGoal => 'الهدف اليومي';

  @override
  String get waterGoalAuto => 'حسب وزنك، و‎+0.5 لتر في أيام التمرين';

  @override
  String get waterGoalSet => 'حددته أنت';

  @override
  String useAutoGoal(String l) {
    return 'استخدم الهدف حسب وزني ($l لتر)';
  }

  @override
  String get remindBreakfastTitle => 'هل سجّلت الفطور؟';

  @override
  String get remindLunchTitle => 'هل سجّلت الغداء؟';

  @override
  String get remindDinnerTitle => 'هل سجّلت العشاء؟';

  @override
  String get remindMealBody => 'اكتبه أو قله أو صوّره — يستغرق ثوانٍ.';

  @override
  String get remindWaterTitle => 'حان وقت شرب الماء';

  @override
  String remindWaterBody(String l) {
    return 'كوب الآن يبقيك على الطريق نحو $l لتر اليوم.';
  }

  @override
  String remindWorkoutTitle(String routine) {
    return '$routine اليوم';
  }

  @override
  String get remindWorkoutBody =>
      'خطتك فيها جلسة تمرين اليوم. جاهز متى كنت جاهزًا.';

  @override
  String get reminders => 'التذكيرات';

  @override
  String get remindMeals => 'الوجبات';

  @override
  String remindMealsSub(String b, String l, String d) {
    return 'إذا لم تُسجَّل وجبة بحلول $b أو $l أو $d';
  }

  @override
  String get remindWater => 'الماء';

  @override
  String remindWaterSub(String a, String b, String c) {
    return 'في $a و$b و$c إذا كنت متأخرًا';
  }

  @override
  String get remindWorkout => 'التمارين';

  @override
  String remindWorkoutSub(String t) {
    return 'في $t في أيام التمرين في خطتك';
  }

  @override
  String get remindersOff =>
      'الإشعارات متوقفة لجيمكو. فعّلها من إعدادات هاتفك.';

  @override
  String get newRecipe => 'وصفة جديدة';

  @override
  String get editRecipe => 'تعديل الوصفة';

  @override
  String get deleteRecipe => 'حذف الوصفة';

  @override
  String get saveRecipe => 'حفظ';

  @override
  String recipeSaved(String name) {
    return 'تم حفظ $name';
  }

  @override
  String get recipeNameHint => 'سمّها — «كاري الدجاج»';

  @override
  String get servingsLabel => 'الحصص';

  @override
  String ingredientsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n مكوّنًا',
      few: '$n مكوّنات',
      two: 'مكوّنان',
      one: 'مكوّن واحد',
      zero: 'المكونات',
    );
    return '$_temp0';
  }

  @override
  String get recipeIngredientsHint =>
      'اكتب ما يدخل فيها: «500غ صدر دجاج، 300غ أرز، ملعقتان زيت زيتون»';

  @override
  String get addIngredients => 'أضف المكوّنات';

  @override
  String recipeMissed(String items) {
    return 'غير موجود في قاعدة البيانات بعد، لذا لم يُضف: $items. أضفها كأطعمة مخصصة لتُحسب.';
  }

  @override
  String get perServing => 'لكل حصة';

  @override
  String kcalPerServing(String kcal) {
    return '$kcal سعرة للحصة';
  }

  @override
  String servingsOf(int n, String g) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n حصص من $g غ',
      one: 'حصة واحدة من $g غ',
    );
    return '$_temp0';
  }

  @override
  String recipeSub(int n, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n حصص',
      one: 'حصة واحدة',
    );
    return '$_temp0 · $kcal سعرة للحصة';
  }

  @override
  String get noRecipes =>
      'لا وصفات بعد. اصنع واحدة مما تطبخه كثيرًا، ثم سجّل حصة بلمسة واحدة.';

  @override
  String get yourRecipe => 'وصفتك';

  @override
  String get healthData => 'بيانات الصحة';

  @override
  String get healthDataSub => 'ما يقرؤه جيمكو وما يكتبه';

  @override
  String get healthOn => 'متصل';

  @override
  String get healthOff => 'غير متصل';

  @override
  String get appleHealth => 'Apple Health';

  @override
  String get healthConnect => 'Health Connect';

  @override
  String connectStore(String store) {
    return 'ربط $store';
  }

  @override
  String get healthHeadline => 'ما يقرؤه جيمكو، وما يكتبه';

  @override
  String get healthBody =>
      'يدخل وزن ميزانك وخطواتك، ويخرج تمرينك وماؤك وأوزانك. تختار كل واحد من شاشة أذونات هاتفك.';

  @override
  String get healthConnectMissing =>
      'تطبيق Health Connect غير مثبّت على هذا الهاتف. ثبّته من Google Play للربط.';

  @override
  String get installHealthConnect => 'تثبيت Health Connect';

  @override
  String get healthRefused =>
      'لم تتم مشاركة شيء. يمكنك السماح بذلك من إعدادات الصحة في هاتفك.';

  @override
  String get readsFromHealth => 'يقرأ';

  @override
  String get writesToHealth => 'يكتب';

  @override
  String get healthWeight => 'وزن الجسم';

  @override
  String get healthWeightSub => 'أوزان ميزانك تغذي خط الاتجاه';

  @override
  String get healthSteps => 'الخطوات';

  @override
  String get healthStepsSub => 'تظهر في صفحة اليوم';

  @override
  String get healthWorkouts => 'التمارين';

  @override
  String get healthWorkoutsSub => 'كل جلسة مكتملة كتمرين قوة';

  @override
  String get healthWater => 'الماء';

  @override
  String get healthWaterSub => 'كل شربة تسجّلها';

  @override
  String get healthWeighIns => 'الأوزان';

  @override
  String get healthWeighInsSub => 'التي تكتبها في جيمكو';

  @override
  String get healthNote =>
      'إيقافه يوقف القراءة والكتابة الجديدة. ما تمت مشاركته يبقى في تطبيق الصحة حتى تحذفه منه.';

  @override
  String get mEatOut => 'مطعم';

  @override
  String get eatOutTitleEm => 'الأكل <em>خارجًا</em>';

  @override
  String get eatOutSub => 'لا ملصق؟ لا مشكلة. التقدير الصادق أفضل من يوم فارغ.';

  @override
  String get eoWhat => 'ماذا تناولت';

  @override
  String get eoPortion => 'الحصة';

  @override
  String get eoSides => 'الإضافات';

  @override
  String get eoEstimate => 'التقدير';

  @override
  String get eoRange => 'هامش';

  @override
  String get eoNote => 'يُسجَّل كتقدير — ويُحسب ضمن سلسلتك.';

  @override
  String eoLogTo(String meal) {
    return 'سجّل في $meal';
  }

  @override
  String get eoBurger => 'برغر';

  @override
  String get eoPizza => 'بيتزا';

  @override
  String get eoPasta => 'باستا';

  @override
  String get eoShawarma => 'شاورما';

  @override
  String get eoSushi => 'سوشي';

  @override
  String get eoCurry => 'كاري';

  @override
  String get eoSalad => 'سلطة';

  @override
  String get eoGrill => 'طبق مشاوي';

  @override
  String get eoSmall => 'صغيرة';

  @override
  String get eoNormal => 'عادية';

  @override
  String get eoBig => 'كبيرة';

  @override
  String get eoHuge => 'ضخمة';

  @override
  String get eoFries => 'بطاطا مقلية';

  @override
  String get eoGarlic => 'ثومية';

  @override
  String get eoBread => 'خبز';

  @override
  String get eoSoda => 'مشروب غازي';

  @override
  String get catchupTitle => 'استدراك';

  @override
  String get catchupHeadEm => 'املأ <em>الفجوات</em>';

  @override
  String catchupSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يومًا بلا تسجيل.',
      few: '$n أيام بلا تسجيل.',
      two: 'يومان بلا تسجيل.',
      one: 'يوم واحد بلا تسجيل.',
    );
    return '$_temp0 املأها تقريبيًا أو استبعدها — بلا لوم في الحالتين.';
  }

  @override
  String catchupTrained(String name) {
    return 'تمرين · $name';
  }

  @override
  String catchupPlanned(String name) {
    return 'مخطط · $name';
  }

  @override
  String get catchupRest => 'راحة مخططة';

  @override
  String get catchupUsual => 'يوم معتاد';

  @override
  String get catchupRough => 'مجموع تقريبي';

  @override
  String get catchupLeave => 'استبعاد';

  @override
  String get catchupRoughLabel => 'تقريبًا كم';

  @override
  String catchupUsualNote(String kcal, String protein) {
    return 'يُملأ بمتوسط ٧ أيام: ≈ $kcal سعرة، $protein غ بروتين.';
  }

  @override
  String get catchupRoughNote => 'يتبع البروتين حصتك المعتادة من اليوم.';

  @override
  String get catchupLeaveNote =>
      'يُستبعد من متوسط الحرق. ويبقى اليوم مفتوحًا لسلسلتك.';

  @override
  String get catchupFooter => 'الأيام المملوءة تُعلَّم كتقديرات.';

  @override
  String catchupSave(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'احفظ $n يومًا',
      few: 'احفظ $n أيام',
      two: 'احفظ يومين',
      one: 'احفظ يومًا',
    );
    return '$_temp0';
  }

  @override
  String catchupSaved(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'تم استدراك $n أيام',
      one: 'تم استدراك اليوم',
    );
    return '$_temp0';
  }

  @override
  String get catchupNone => 'كل شيء محدّث.';

  @override
  String catchupCard(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يومًا بلا تسجيل طعام',
      few: '$n أيام بلا تسجيل طعام',
      two: 'يومان بلا تسجيل طعام',
      one: 'يوم بلا تسجيل طعام',
    );
    return '$_temp0';
  }

  @override
  String get catchupCardSub => 'استدرك ببضع نقرات';

  @override
  String get swapExercise => 'استبدال التمرين';

  @override
  String get swapExerciseSub => 'الجهاز مشغول، أو لا تشعر بالراحة';

  @override
  String swapTitle(String name) {
    return 'استبدال $name';
  }

  @override
  String get swapSub =>
      'نفس العضلات بحركة مختلفة. المجموعات التي أنهيتها تبقى كما هي.';

  @override
  String get swapNone => 'لا يوجد بديل قريب في المكتبة.';

  @override
  String swapped(String name) {
    return 'تم الاستبدال بـ $name';
  }

  @override
  String get flagPain => 'الإبلاغ عن ألم';

  @override
  String get flagPainSub => 'شعرت بألم في هذه المجموعة';

  @override
  String get clearPain => 'إزالة علامة الألم';

  @override
  String get painWhere => 'أين الألم؟';

  @override
  String get painNote =>
      'الحرقان في العضلة طبيعي. أما الألم في المفصل أو الألم الحاد فلا.';

  @override
  String get painShoulder => 'الكتف';

  @override
  String get painElbow => 'المرفق';

  @override
  String get painWrist => 'الرسغ';

  @override
  String get painBack => 'أسفل الظهر';

  @override
  String get painHip => 'الورك';

  @override
  String get painKnee => 'الركبة';

  @override
  String get painOther => 'مكان آخر';

  @override
  String painOnSet(String area, String set) {
    return '$area · المجموعة $set';
  }

  @override
  String get painAcheLighter => 'ألم خفيف: خفّف الوزن ١٠٪';

  @override
  String get painAcheLighterSub =>
      'تنخفض المجموعات المتبقية ١٠٪. توقف إذا ازداد الألم.';

  @override
  String get painAcheKeep => 'ألم خفيف: تابع';

  @override
  String get painAcheKeepSub => 'سيُعلَّم لتنتبه له في المرة القادمة.';

  @override
  String get painSharpStop => 'حاد: أوقف هذا التمرين';

  @override
  String get painSharpStopSub =>
      'الألم الحاد إشارة توقف. تُحذف المجموعات المتبقية.';

  @override
  String get painSharpSwap => 'حاد: استبدله';

  @override
  String get painSharpSwapSub => 'جرّب حركة لا تضغط عليه.';

  @override
  String get painLightened => 'المجموعات المتبقية أخف بـ ١٠٪';

  @override
  String get painFlagged => 'تم تسجيل الألم';

  @override
  String get painStopped => 'توقفت هنا. أرحه، وراجع مختصًا إن استمر.';

  @override
  String painFlaggedOn(String area) {
    return 'ألم مسجّل: $area';
  }

  @override
  String painLastAche(String area, String date) {
    return 'في المرة السابقة ($date) شعرت بألم خفيف في $area. ابدأ بوزن أخف.';
  }

  @override
  String painLastSharp(String area, String date) {
    return 'في المرة السابقة ($date) شعرت بألم حاد في $area. استبدله إن عاد.';
  }

  @override
  String get heroTagLeftOpen => 'لم يُغلق';

  @override
  String heroLeftOpenEm(String name) {
    return '$name <em>لم يُغلق</em>';
  }

  @override
  String heroLeftOpenBody(int n, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n مجموعة منجزة',
      few: '$n مجموعات منجزة',
      two: 'مجموعتان منجزتان',
      one: 'مجموعة واحدة منجزة',
      zero: 'لا مجموعات منجزة بعد',
    );
    return '$_temp0، آخر تعديل $time. احفظ ما أنجزته أو تابع من حيث توقفت.';
  }

  @override
  String yesterdayAt(String time) {
    return 'أمس $time';
  }

  @override
  String get saveAsDone => 'احفظه كمنجز';

  @override
  String get heroTagSkipped => 'متخطّى';

  @override
  String get heroRestChosenTitle => 'راحة <em>اليوم</em>';

  @override
  String heroRestChosenBody(String name) {
    return 'ينتقل $name إلى الغد. الراحة جزء من الخطة لا خروج عنها.';
  }

  @override
  String get heroSkippedTitle => 'تخطّي <em>اليوم</em>';

  @override
  String heroSkippedBody(String name) {
    return 'أُلغي $name هذا الأسبوع. بقية الأسبوع كما خُطط له.';
  }

  @override
  String get trainAnyway => 'تمرّن على أي حال';

  @override
  String get trainAnywaySub =>
      'اختر روتينًا، أو ابدأ فارغًا وأضف أثناء التمرين.';

  @override
  String get undoChange => 'تراجع';

  @override
  String get notToday => 'ليس اليوم';

  @override
  String get notTodayTitle => 'ليس اليوم؟';

  @override
  String get restTodayLabel => 'ارتح اليوم وتمرّن غدًا';

  @override
  String restTodaySub(String name) {
    return 'ينزاح $name وبقية الأسبوع يومًا واحدًا.';
  }

  @override
  String get skipTodayLabel => 'تخطَّه هذا الأسبوع';

  @override
  String skipTodaySub(String name) {
    return 'يُلغى $name؛ وتبقى الأيام الأخرى في مكانها.';
  }

  @override
  String get notTodayNote =>
      'في الحالتين سلسلتك بأمان: يوم الراحة المخطط لا يكسرها.';

  @override
  String routineSize(int n, int sets) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n تمرينًا',
      few: '$n تمارين',
      two: 'تمرينان',
      one: 'تمرين واحد',
    );
    return '$_temp0 · $sets مجموعة';
  }

  @override
  String get photosTab => 'الصور';

  @override
  String get poseFront => 'أمام';

  @override
  String get poseSide => 'جانب';

  @override
  String get poseBack => 'خلف';

  @override
  String photoOf(String pose) {
    return 'صورة $pose';
  }

  @override
  String addPhotoOf(String pose) {
    return 'أضف صورة $pose';
  }

  @override
  String get chooseFromLibrary => 'اختر من المعرض';

  @override
  String get photoTip =>
      'المكان نفسه والإضاءة نفسها والوقت نفسه — الصباح قبل الأكل هو الأفضل.';

  @override
  String get deletePhoto => 'احذف الصورة';

  @override
  String get todaysPhotos => 'صور اليوم';

  @override
  String get onThisPhone => 'على هذا الهاتف فقط';

  @override
  String get photosNote =>
      'لا تغادر الصور هاتفك: لا رفع ولا نسخ احتياطي. مرة كل أسبوعين إلى أربعة أسابيع تكفي.';

  @override
  String get compareLbl => 'قارن';

  @override
  String latestOn(String date) {
    return 'الأحدث · $date';
  }

  @override
  String get compareFrom => 'قارن من';

  @override
  String get compareNeedsTwo => 'التقط الوضعية نفسها في يوم آخر للمقارنة.';

  @override
  String get strengthInsightLbl => 'آخر ٨ أسابيع';

  @override
  String get strengthHeldEm => 'القوة <em>ثابتة</em>';

  @override
  String get strengthUpEm => 'القوة <em>ترتفع</em>';

  @override
  String strengthHeldBody(int held, int n) {
    return '$held من $n تمارين حافظت على قوتها أثناء التنشيف. الحفاظ على القوة مع العجز يعني أنك تحافظ على العضل.';
  }

  @override
  String strengthUpBody(int up, int n) {
    return '$up من $n تمارين أقوى مما كانت قبل ٨ أسابيع.';
  }

  @override
  String get pauseStreak => 'أوقف السلسلة مؤقتًا';

  @override
  String get pauseHint => 'مريض أو مسافر';

  @override
  String pausedUntil(String date) {
    return 'متوقفة حتى $date';
  }

  @override
  String get pauseSub =>
      'مرض أو سفر أو ظروف الحياة. أيام التوقف لا تُحسب ولا تكسر السلسلة، وتبقى أيام التجميد كما هي.';

  @override
  String get endPause => 'أنهِ التوقف';

  @override
  String streakPaused(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'أُوقفت السلسلة $n يومًا',
      few: 'أُوقفت السلسلة $n أيام',
      two: 'أُوقفت السلسلة يومين',
      one: 'أُوقفت السلسلة يومًا',
    );
    return '$_temp0';
  }

  @override
  String aiCanEstimate(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n طعامًا غير موجود على الهاتف. يمكن للذكاء الاصطناعي تقديرها.',
      few: '$n أطعمة غير موجودة على الهاتف. يمكن للذكاء الاصطناعي تقديرها.',
      two: 'طعامان غير موجودين على الهاتف. يمكن للذكاء الاصطناعي تقديرهما.',
      one: 'طعام واحد غير موجود على الهاتف. يمكن للذكاء الاصطناعي تقديره.',
    );
    return '$_temp0';
  }

  @override
  String askAiN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'اسأل الذكاء الاصطناعي عن $n أطعمة',
      one: 'اسأل الذكاء الاصطناعي',
    );
    return '$_temp0';
  }

  @override
  String get aiThinking => 'جارٍ التقدير…';

  @override
  String get aiNeedsAccount =>
      'سجّل الدخول لاستخدام الذكاء الاصطناعي — مجاني خلال فترة التجربة.';

  @override
  String aiCouldNot(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'لم يتعرف الذكاء الاصطناعي على $n أطعمة. جرّب كلمات أخرى أو ابحث.',
      one: 'لم يتعرف الذكاء الاصطناعي على طعام واحد. جرّب كلمات أخرى أو ابحث.',
    );
    return '$_temp0';
  }

  @override
  String get eoOther => 'شيء آخر';

  @override
  String get eoOtherHint => 'صفها، مثلًا: برياني دجاج مع رايتا';

  @override
  String get eoAskAi => 'اطلب من الذكاء الاصطناعي تقديرها';

  @override
  String get eoRoughGuess => 'بلا ذكاء اصطناعي؟ قدّر المجموع';

  @override
  String eoAiNote(String meal) {
    return 'وجبة مطعم بحصة مطعم عادية: $meal';
  }

  @override
  String get reminderOn => 'مفعّل';

  @override
  String get reminderOff => 'متوقف';

  @override
  String waterNudgeN(int n) {
    return 'تذكير $n';
  }

  @override
  String get remindWorkoutAt => 'الوقت';

  @override
  String get remindMealsNote =>
      'لا يصل التذكير إلا إذا كانت الوجبة ما زالت فارغة.';

  @override
  String get remindWaterNote =>
      'لا يصل التذكير إلا إذا كنت متأخرًا عن هدف الماء في ذلك الوقت.';

  @override
  String get remindWorkoutNote =>
      'فقط في أيام التمرين في خطتك، ولا يصل بعد إنهائه.';

  @override
  String toggleReminder(String name) {
    return 'تشغيل أو إيقاف تذكيرات $name';
  }

  @override
  String get plansPill => 'الخطط';

  @override
  String get plansTitleEm => 'ادفع مقابل التدريب، <em>لا الأساسيات</em>';

  @override
  String get featIconAi => 'تقدير بالذكاء الاصطناعي';

  @override
  String get featIconCoach => 'تدريب أسبوعي';

  @override
  String get featIconStrength => 'تحليل القوة';

  @override
  String get featLogging => 'التسجيل بالبحث والباركود والكتابة والصوت';

  @override
  String get featAi => 'تقديرات الذكاء الاصطناعي من الصور والكلمات';

  @override
  String get featOnce => 'ادفع مرة واحدة، لك إلى الأبد';

  @override
  String get planFree => 'مجاني';

  @override
  String get planFreeSub => 'كل ما تحتاجه للتسجيل والتمرين.';

  @override
  String get planPro => 'برو';

  @override
  String get planProSub => 'تدريب يتكيّف معك كل أسبوع.';

  @override
  String get planLifetimeSub => 'كل مزايا برو بدفعة واحدة.';

  @override
  String get priceFree => '٠ €';

  @override
  String get perMonth => '/ شهر';

  @override
  String get perYear => '/ سنة';

  @override
  String get once => 'مرة واحدة';

  @override
  String get save33 => '−٣٣٪';

  @override
  String get mostPopular => 'الأكثر طلبًا';

  @override
  String get proIsOnTesting => 'برو مفعّل — مجاني خلال التجربة';

  @override
  String get freeAlwaysBtn => 'مجاني دائمًا';

  @override
  String get healthNotOpenIos => 'لم يُفتح Apple Health';

  @override
  String get healthNotOpen => 'لم يُفتح Health Connect';

  @override
  String get healthWhyIos =>
      'لا يتخطى iPhone شاشة الأذونات إلا إذا لم يكن مسموحًا للتطبيق باستخدام Apple Health أصلًا. في نسخة تجريبية موقّعة بحساب Apple مجاني قد يُحذف إذن HealthKit أثناء التوقيع. وإن رفضت سابقًا ففعّل Gymco من Health ← الملف الشخصي ← التطبيقات ← Gymco.';

  @override
  String get healthWhyAndroid =>
      'تأكد أن Health Connect مثبت ومحدّث، ثم اسمح لـ Gymco فيه.';

  @override
  String get healthPhoneSaid => 'ما قاله الهاتف';

  @override
  String get tryAgain => 'حاول مجددًا';

  @override
  String get openHealthApp => 'افتح تطبيق Health';

  @override
  String get dayNoteMulti =>
      'اختر كل يوم يُنفَّذ فيه. إذا فاتك يوم ينتقل إلى يوم التمرين التالي مع الحفاظ على الترتيب.';

  @override
  String get createExercise => 'أنشئ تمرينًا';

  @override
  String createNamed(String name) {
    return 'أنشئ «$name»';
  }

  @override
  String get createExerciseSub => 'غير موجود في المكتبة؟ أنشئ تمرينك.';

  @override
  String get exerciseNameHint => 'اسم التمرين';

  @override
  String get mainMuscle => 'العضلة الأساسية';

  @override
  String get equipmentLbl => 'المعدات';

  @override
  String get pickMuscleFirst =>
      'اختر العضلة الأساسية ليُحسب ضمن مجموعاتك الأسبوعية.';

  @override
  String get customExerciseNote =>
      'يُحفظ على هذا الهاتف مع بقية بياناتك وفي النسخة الاحتياطية.';

  @override
  String get createAndAdd => 'أنشئ التمرين';

  @override
  String exerciseCreated(String name) {
    return 'أُضيف $name إلى مكتبتك';
  }

  @override
  String get eqBarbell => 'بار';

  @override
  String get eqDumbbell => 'دمبل';

  @override
  String get eqMachine => 'جهاز';

  @override
  String get eqCable => 'كابل';

  @override
  String get eqBody => 'وزن الجسم';

  @override
  String get eqKettlebell => 'كيتلبل';

  @override
  String get eqBands => 'أشرطة مقاومة';

  @override
  String get eqOther => 'أخرى';

  @override
  String get aiTag => 'ذكاء اصطناعي';

  @override
  String get aboutGymco => 'حول التطبيق';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get helpSupportSub => 'أسئلة، أخطاء، أفكار';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicySub => 'ما يبقى على هاتفك';

  @override
  String get termsOfUse => 'شروط الاستخدام';

  @override
  String get termsOfUseSub => 'الاشتراكات والسلامة';

  @override
  String tplPackDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n يومًا في الأسبوع',
      few: '$n أيام في الأسبوع',
      two: 'يومان في الأسبوع',
      one: 'يوم واحد في الأسبوع',
    );
    return '$_temp0';
  }

  @override
  String get tplLevelBeginner => 'مبتدئ';

  @override
  String get tplLevelIntermediate => 'متوسط';

  @override
  String get tplLevelExpert => 'متقدم';

  @override
  String get packFoodLabel => 'قائمة أطعمة جيمكو';

  @override
  String get proGrantedBadge => 'على حسابك';

  @override
  String get proGrantedSub => 'مفتوح لحسابك';

  @override
  String proGrantedUntil(String date) {
    return 'مفتوح لحسابك حتى $date';
  }

  @override
  String get proGrantedLabel => 'جيمكو برو، مفعّل لحسابك';

  @override
  String get proGrantedNote =>
      'برو مفعّل لحسابك. لا شيء للبيع بعد؛ هذه هي الأسعار المخطط لها عند الإطلاق.';

  @override
  String get proLockedBadge => 'قريبًا';

  @override
  String get proLockedCta => 'برو قادم';

  @override
  String get proLockedSub => 'اطّلع على ما سيضيفه برو';

  @override
  String get proLockedLabel => 'جيمكو برو، قريبًا';

  @override
  String get proLockedNote =>
      'برو غير معروض للبيع بعد. هذه هي الأسعار المخطط لها عند الإطلاق.';

  @override
  String get announcementDismiss => 'إخفاء';

  @override
  String get helpOnSite => 'المساعدة على الموقع';

  @override
  String get helpOnSiteSub => 'أدلة وإجابات';

  @override
  String get helpIntro =>
      'أخبرنا بما يحدث. نقرأ كل رسالة ونرد بالبريد الإلكتروني.';

  @override
  String get helpSubjectHint => 'الموضوع';

  @override
  String get helpMessageHint => 'ما الذي حدث، أو ما الذي تريده';

  @override
  String get helpDeleteSwitch => 'احذف حسابي وبياناتي';

  @override
  String get helpDeleteNote =>
      'تُعالج طلبات الحذف خلال 30 يومًا. يُحذف الحساب ونسخته الاحتياطية وأي رسائل معه.';

  @override
  String get helpSend => 'إرسال';

  @override
  String get helpSent => 'أُرسلت. سنرد بالبريد الإلكتروني.';

  @override
  String get helpTooMany => 'رسائل كثيرة اليوم. حاول مجددًا غدًا.';

  @override
  String whatsNewTitle(String version) {
    return 'الجديد في $version';
  }

  @override
  String get whatsNewOk => 'حسنًا';

  @override
  String get meSignInTitle => 'سجّل الدخول إلى Gymco';

  @override
  String get meSignInSub =>
      'احفظ نسخة احتياطية من مذكراتك لاستعادتها على هاتف جديد، واستخدم تسجيل الوجبات بالصور. بريدك فقط، بلا كلمة مرور.';

  @override
  String get meSignInCta => 'تسجيل الدخول بالبريد';

  @override
  String get emailIncomplete => 'أدخل بريدك كاملًا، مثل name@gmail.com';
}
