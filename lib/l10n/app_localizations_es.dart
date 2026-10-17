// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Gymco';

  @override
  String get tabToday => 'Hoy';

  @override
  String get tabFood => 'Comida';

  @override
  String get tabTrain => 'Entrenar';

  @override
  String get tabProgress => 'Progreso';

  @override
  String get tabMe => 'Yo';

  @override
  String todayTitle(String accent) {
    return 'Haz que $accent';
  }

  @override
  String get todayAccent => 'cuente';

  @override
  String kcalLeft(String n) {
    return 'Quedan $n kcal';
  }

  @override
  String kcalOver(String n) {
    return '$n kcal sobre el objetivo';
  }

  @override
  String ofGrams(String a, String b) {
    return '$a / $b g';
  }

  @override
  String get protein => 'Proteína';

  @override
  String get carbs => 'Carbohidratos';

  @override
  String get fat => 'Grasa';

  @override
  String get kcal => 'kcal';

  @override
  String get meals => 'Comidas';

  @override
  String get breakfast => 'Desayuno';

  @override
  String get lunch => 'Almuerzo';

  @override
  String get dinner => 'Cena';

  @override
  String get snack => 'Tentempié';

  @override
  String get nothingLogged => 'Nada registrado todavía';

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count alimentos', one: '1 alimento');
    return '$_temp0';
  }

  @override
  String get emptyDayTitle => 'Un día nuevo';

  @override
  String get emptyDayBody => 'Empieza por lo primero que comiste. Una comida ya es un buen comienzo.';

  @override
  String get habitsTitle => 'Hábitos de hoy';

  @override
  String get habitProtein => 'Proteína en cada comida';

  @override
  String habitMealsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comidas registradas',
      one: '1 comida registrada',
      zero: 'Ninguna comida registrada',
    );
    return '$_temp0';
  }

  @override
  String get addFood => 'Añadir alimento';

  @override
  String addTo(String meal) {
    return 'Añadir a $meal';
  }

  @override
  String get searchFoods => 'Buscar alimentos';

  @override
  String get scanBarcode => 'Escanear código';

  @override
  String get recent => 'Recientes';

  @override
  String noResults(String q) {
    return 'Nada para \"$q\"';
  }

  @override
  String get noResultsBody => 'Prueba una palabra más corta o escanea el envase.';

  @override
  String get barcodeMiss => 'Aún no conocemos este producto';

  @override
  String get barcodeMissBody => 'Añádelo a Open Food Facts en unos 30 segundos y estará para todos la próxima vez.';

  @override
  String get contributeOff => 'Añadir a Open Food Facts';

  @override
  String get searchingOnline => 'Buscando en línea…';

  @override
  String get offlineSearch => 'Sin conexión — alimentos guardados en este teléfono';

  @override
  String get amount => 'Cantidad';

  @override
  String get grams => 'g';

  @override
  String get per100g => 'por 100 g';

  @override
  String get log => 'Registrar';

  @override
  String get delete => 'Eliminar';

  @override
  String logged(String food) {
    return '$food registrado';
  }

  @override
  String get cameraPermission => 'Permite la cámara para escanear códigos.';

  @override
  String obWelcomeTitle(String accent) {
    return 'Dieta y entreno, $accent';
  }

  @override
  String get obWelcomeAccent => 'juntos';

  @override
  String get obWelcomeBody => 'Objetivos que se adaptan a lo que de verdad comes y pesas. Sin adivinar, sin castigos.';

  @override
  String get getStarted => 'Empezar';

  @override
  String get obGoalTitle => '¿Cuál es tu objetivo?';

  @override
  String get goalCut => 'Perder grasa';

  @override
  String get goalCutSub => 'Mantén el músculo, pierde la grasa';

  @override
  String get goalMaintain => 'Mantener';

  @override
  String get goalMaintainSub => 'Mantén tu peso, gana fuerza';

  @override
  String get goalBulk => 'Ganar músculo';

  @override
  String get goalBulkSub => 'Una subida lenta y limpia';

  @override
  String get obBodyTitle => 'Sobre ti';

  @override
  String get obBodyBody => 'Se usa una vez para tu primera semana. Después, mandan tus registros.';

  @override
  String get sexMale => 'Hombre';

  @override
  String get sexFemale => 'Mujer';

  @override
  String get age => 'Edad';

  @override
  String get heightCm => 'Altura (cm)';

  @override
  String get weightKg => 'Peso (kg)';

  @override
  String get obActivityTitle => '¿Qué tan activo es un día normal?';

  @override
  String get actSedentary => 'Casi siempre sentado';

  @override
  String get actLight => 'De pie parte del día';

  @override
  String get actModerate => 'Trabajo activo o paseos diarios';

  @override
  String get actHigh => 'Trabajo físico';

  @override
  String get actAthlete => 'Entreno duro dos veces al día';

  @override
  String get obRateTitle => '¿A qué ritmo?';

  @override
  String ratePerWeek(String pct) {
    return '$pct% del peso corporal por semana';
  }

  @override
  String rateKgPerWeek(String kg) {
    return '≈ $kg kg por semana';
  }

  @override
  String get rateWarning =>
      'Más de 0,85% por semana suele costar músculo y sueño. Puedes hacerlo, pero haremos revisiones más a menudo.';

  @override
  String get rateCapNote => 'Límite: 1% por semana.';

  @override
  String get obTargetsTitle => 'Tus objetivos iniciales';

  @override
  String get obTargetsBody =>
      'Esta es la semana uno. En cada revisión, Gymco recalcula a partir de tus registros y tu peso de tendencia, como mucho 120 kcal por semana.';

  @override
  String get dailyTarget => 'Objetivo diario';

  @override
  String get noNumbersOffer => '¿Prefieres no ver números?';

  @override
  String get noNumbersOfferBody => 'El modo sin números oculta calorías, macros y peso, y sigue hábitos en su lugar.';

  @override
  String get continueBtn => 'Continuar';

  @override
  String get startBtn => 'Empezar';

  @override
  String get meTitle => 'Yo';

  @override
  String get language => 'Idioma';

  @override
  String get systemLanguage => 'Idioma del teléfono';

  @override
  String get noNumbersMode => 'Modo sin números';

  @override
  String get noNumbersModeSub => 'Ocultar calorías, macros y peso';

  @override
  String get leaveNoNumbersTitle => '¿Mostrar los números otra vez?';

  @override
  String get leaveNoNumbersBody => 'Calorías, macros y peso se verán en todas las pantallas.';

  @override
  String get leaveNoNumbersConfirm => 'Mostrar números';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cheatAllowance => 'Comidas libres';

  @override
  String get cheatOff => 'No';

  @override
  String get cheatOnce => '1 por semana';

  @override
  String get cheatTwice => '2 por semana';

  @override
  String get targets => 'Objetivos';

  @override
  String get redoOnboarding => 'Cambiar objetivo y metas';

  @override
  String get trainTitle => 'Entrenar';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get nextBuild => 'Esta parte de Gymco está diseñada y se construye a continuación.';

  @override
  String get repeatYesterday => 'Repetir ayer';

  @override
  String get nothingYesterday => 'Ayer no registraste nada en esta comida';
}
