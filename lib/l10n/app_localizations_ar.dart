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
  String get habitsTitle => 'عادات اليوم';

  @override
  String get habitProtein => 'بروتين في كل وجبة';

  @override
  String habitMealsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count وجبة مسجّلة',
      many: '$count وجبة مسجّلة',
      few: '$count وجبات مسجّلة',
      two: 'وجبتان مسجّلتان',
      one: 'وجبة واحدة مسجّلة',
      zero: 'لم تُسجَّل وجبات',
    );
    return '$_temp0';
  }

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
  String get barcodeMissBody => 'أضفه إلى Open Food Facts في نحو 30 ثانية وسيكون متاحًا للجميع في المرة القادمة.';

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
  String get obWelcomeBody => 'أهداف تتكيّف مع ما تأكله وتزنه فعلًا. بلا تخمين وبلا عقاب.';

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
  String get obBodyBody => 'تُستخدم لبدء الأسبوع الأول فقط. بعد 14 يومًا يتولّى إنفاقك الحقيقي.';

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
  String get rateWarning => 'أسرع من 0.85% أسبوعيًا غالبًا ما يكلّف العضل والنوم. يمكنك ذلك، لكننا سنتابع معك أكثر.';

  @override
  String get rateCapNote => 'الحد الأقصى 1% أسبوعيًا.';

  @override
  String get obTargetsTitle => 'أهدافك الأولى';

  @override
  String get obTargetsBody => 'تقدير لا حكم. بعد أسبوعين أو ثلاثة من التسجيل، يستبدله جيمكو بإنفاقك المقيس.';

  @override
  String get dailyTarget => 'الهدف اليومي';

  @override
  String get noNumbersOffer => 'تفضّل ألّا ترى الأرقام؟';

  @override
  String get noNumbersOfferBody => 'وضع بلا أرقام يخفي السعرات والمغذيات والوزن، ويتابع العادات بدلًا منها.';

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
  String get noNumbersMode => 'وضع بلا أرقام';

  @override
  String get noNumbersModeSub => 'إخفاء السعرات والمغذيات والوزن';

  @override
  String get leaveNoNumbersTitle => 'إظهار الأرقام مجددًا؟';

  @override
  String get leaveNoNumbersBody => 'ستظهر السعرات والمغذيات والوزن في كل الشاشات.';

  @override
  String get leaveNoNumbersConfirm => 'أظهر الأرقام';

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
  String get noRoutinesBody => 'أنشئ برنامجًا، أو ابدأ تمرينًا فارغًا وأضف التمارين أثناءه.';

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
    return 'لديك برنامج باسم «$name» بالفعل.';
  }

  @override
  String get deleteRoutine => 'احذف البرنامج';

  @override
  String get deleteRoutineTitle => 'حذف هذا البرنامج؟';

  @override
  String get deleteRoutineBody => 'التمارين التي أنجزتها تبقى في سجلك.';

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
  String get durationLbl => 'الوقت';

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
  String get stWarmupSub => 'تهيئة للرفعة. لا تُحتسب في المجموعات الأسبوعية.';

  @override
  String get stNormal => 'مجموعة عمل';

  @override
  String get stNormalSub => 'تُحتسب مجموعة واحدة.';

  @override
  String get stFailure => 'حتى الفشل';

  @override
  String get stFailureSub => 'تُحتسب مجموعة واحدة.';

  @override
  String get stDrop => 'مجموعة تنازلية';

  @override
  String get stDropSub => 'تُحتسب نصف مجموعة.';

  @override
  String get removeSet => 'احذف المجموعة';

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
  String get addNoWeighing => 'أضف ما أكلته — بلا وزن';

  @override
  String get addWater => 'أضف 250 مل من الماء';

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
  String get floorBody => 'لا تُحدَّد الأهداف تحت هذا الرقم أبدًا. النزول عنه يعني أن تكتب الرقم بنفسك، بعد تحذير.';

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
  String get habitMealsNone => 'الوجبات مسجّلة، بلا تخطٍّ';

  @override
  String get habitProteinEach => 'مصدر بروتين في كل وجبة';

  @override
  String get habitTrained => 'تمرّنت اليوم';

  @override
  String get habitsHiddenBody => 'ما تسجّله ما زال محفوظًا. لا شيء يُقيَّم، ولا هدف يُتابَع ضدك.';

  @override
  String get habitsHiddenTitle => 'السعرات والمغذيات والوزن مخفية';

  @override
  String get heightLbl => 'الطول';

  @override
  String get heroDoneBody => 'سُجّل وحُفظ. الراحة هي حيث يتحوّل إلى التمرين القادم.';

  @override
  String get heroExercises => 'تمارين';

  @override
  String get heroMin => 'دقيقة';

  @override
  String get heroMuscles => 'عضلات';

  @override
  String get heroRestBody => 'لا شيء مجدول اليوم. الراحة هي حيث يتحوّل التمرين الماضي إلى القادم.';

  @override
  String get heroRestTitle => 'يوم <em>راحة</em>';

  @override
  String get heroSets => 'مجموعات';

  @override
  String get heroSetupBody => 'اختر تقسيمًا أو ابنِ برنامجك. جيمكو يجدوله ويتابع كل مجموعة.';

  @override
  String get heroSetupTitle => 'جهّز <em>تمرينك</em>';

  @override
  String get heroTagDone => 'أُنجز اليوم';

  @override
  String get heroTagInProgress => 'جارٍ الآن';

  @override
  String get heroTagToday => 'تمرين اليوم';

  @override
  String get howTodayWent => 'كيف كان اليوم';

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
  String get keepThemHidden => 'أبقِها مخفية';

  @override
  String get langArabicSub => 'العربية · من اليمين لليسار';

  @override
  String get langEnglishSub => 'الإنجليزية';

  @override
  String get langSpanishSub => 'الإسبانية';

  @override
  String get logFirstMeal => 'سجّل وجبتك الأولى';

  @override
  String get logNoWeighing => 'سجّل ما أكلته — بلا وزن';

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
  String get mealDetailTip => 'المس عنصرًا لتغيير كميته. ما تحذفه يخرج من اليوم فورًا.';

  @override
  String get mealLabel => 'الوجبة';

  @override
  String get myMeals => 'وجباتي';

  @override
  String get noMatchBody => 'الطبخ المنزلي نادرًا ما يكون فيها. امسح العبوة، أو جرّب كلمة أخرى.';

  @override
  String get noMatchTitle => 'لا تطابق في قاعدة البيانات';

  @override
  String get noNumbersOfferLine =>
      'تفضّل ألّا ترى الأرقام؟ وضع بلا أرقام يخفي السعرات والمغذيات والوزن، ويتابع العادات بدلًا منها.';

  @override
  String get noNumbersOn => 'مفعّل — السعرات والوزن مخفية';

  @override
  String get noSessionPlanned => 'لا تمرين مخطّط';

  @override
  String get nothingInMeal => 'لا شيء في هذه الوجبة بعد';

  @override
  String get nothingYesterdayDay => 'لم يُسجَّل شيء أمس';

  @override
  String get numbersHidden => 'الأرقام مخفية';

  @override
  String get obActivityTitleEm => 'كيف <em>تتحرّك</em> في يوم عادي؟';

  @override
  String get obBodyTitleEm => 'قليلًا <em>عنك</em>';

  @override
  String get obGoalBody => 'يحدّد هذا سرعتك وحدّ البروتين وطريقة قراءة بياناتك. يمكنك تغييره أي أسبوع.';

  @override
  String get obRateBodyGain => 'البطء نظيف. ربع إلى نصف بالمئة من وزن الجسم أسبوعيًا يبقي الزيادة عضلًا في معظمها.';

  @override
  String get obRateBodyLose => 'الأسرع ليس الأفضل. بين 0.5 و1% من وزن الجسم أسبوعيًا يبقى العضل محفوظًا.';

  @override
  String get obRateTitleGain => 'بأي سرعة تريد أن تزيد؟';

  @override
  String get obRateTitleLose => 'بأي سرعة تريد أن تخسر؟';

  @override
  String get pastNoteWithin => 'ضمن مئة سعرة من الهدف. أيام كهذه هي ما يحرّك خط الاتجاه.';

  @override
  String get pctPerWeek => '% / أسبوع';

  @override
  String get photoComing => 'صوّر الطبق ويقترح جيمكو ما يراه؛ وأنت تحدّد الكمية. يصل مع التسجيل الذكي.';

  @override
  String get rateHot => 'فوق 0.85% أسبوعيًا تبدأ بخسارة العضل. سيكرّر جيمكو ذلك كل أسبوع حتى تبطئ.';

  @override
  String get rateOkGain => 'بطيء بما يكفي لتكون معظم الزيادة عضلًا.';

  @override
  String get rateOkLose =>
      'ضمن النطاق الذي يوصي به Helms وزملاؤه (2014) للرياضيين الطبيعيين للحفاظ على العضل أثناء العجز.';

  @override
  String get readyToLog => 'جاهز للتسجيل';

  @override
  String get recipes => 'وصفات';

  @override
  String get restDay => 'يوم راحة';

  @override
  String get ringEmptyBody => 'لم يُسجَّل شيء بعد. أهدافك جاهزة — تمتلئ الحلقة مع تقدّمك.';

  @override
  String get rtlNote => 'العربية تقلب التطبيق كله من اليمين لليسار، بما في ذلك شريط الأسبوع واتجاهات السحب.';

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
  String get searchOtherLanguage => 'البحث بلغة أخرى يجد أكثر غالبًا — جيمكو يحفظ كل اسم يتعلّمه على الطعام نفسه.';

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
  String get supportBody => 'خطوط دعم وخدمات قريبة منك';

  @override
  String get supportTitle => 'التحدث مع أحد يساعد';

  @override
  String get swipeToStart => 'اسحب للبدء';

  @override
  String get targetsSaved => 'حُفظت الأهداف — ابدأ التسجيل';

  @override
  String get theRemainder => 'الباقي';

  @override
  String get todayPlain => 'اليوم';

  @override
  String get todayTitleEm => 'اجعلها <em>تُحتسب</em>';

  @override
  String get training => 'التمرين';

  @override
  String get trainingCountedSeparately => 'التمرين يُحتسب منفصلًا. لا تُدخل النادي هنا.';

  @override
  String get trendNeedsDays => 'الاتجاه يحتاج نحو سبعة أيام';

  @override
  String get trendWeight => 'اتجاه الوزن';

  @override
  String get unitsLanguage => 'الوحدات واللغة';

  @override
  String get usuallyNow => 'عادةً تأكل في هذا الوقت';

  @override
  String get voiceComing => 'اضغط مطوّلًا وقل ما أكلته. يمر بالقارئ نفسه كالكتابة. يصل مع التسجيل الذكي.';

  @override
  String get water => 'الماء';

  @override
  String get waterAdded => 'أُضيف 250 مل';

  @override
  String get weightToday => 'الوزن اليوم';

  @override
  String get welcomeArtAlt => 'امرأة أثناء أرجحة كيتلبل';

  @override
  String get welcomeBody => 'سجّل طعامك في ثوانٍ، وتمرّن بخطة، وحافظ على سلسلة تستحق الحماية.';

  @override
  String get welcomeTitleEm => 'ابدأ رحلة <em>لياقتك</em> اليوم';

  @override
  String get writeComing => 'اكتب الوجبة كما تقولها — «بيضتان، 150 غ أرز». يصل مع التسجيل الذكي.';

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
  String get noSavedMeals => 'لا وجبات محفوظة بعد. افتح وجبة تأكلها كثيرًا واضغط «احفظها كوجبة».';

  @override
  String get noCustomFoods => 'لا أطعمة مخصّصة بعد. افتح أي طعام واضغط «احفظه كمخصّص» لتحتفظ بنسختك.';

  @override
  String get recipesSoon => 'الوصفات قادمة: ابنِها من المكوّنات، قسّمها إلى حصص، وسجّل حصة.';

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
  String get onPhoneNote => 'كل شيء على هذا الهاتف. لا حساب ولا خادم، فلا يخرج شيء إلا إذا صدّرته.';

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
}
