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
  String get obGoalTitle => 'ما هدفك؟';

  @override
  String get goalCut => 'خسارة الدهون';

  @override
  String get goalCutSub => 'حافظ على العضل واخسر الدهون';

  @override
  String get goalMaintain => 'الثبات';

  @override
  String get goalMaintainSub => 'ثبّت وزنك وابنِ القوة';

  @override
  String get goalBulk => 'بناء العضل';

  @override
  String get goalBulkSub => 'زيادة بطيئة ونظيفة';

  @override
  String get obBodyTitle => 'عنك';

  @override
  String get obBodyBody => 'تُستخدم مرة واحدة لبدء أسبوعك الأول. بعدها تتولّى سجلاتك الأمر.';

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
  String get obTargetsBody =>
      'هذا الأسبوع الأول. في كل مراجعة يعيد جيمكو الحساب من سجلاتك واتجاه وزنك، بما لا يزيد عن 120 سعرة أسبوعيًا.';

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
}
