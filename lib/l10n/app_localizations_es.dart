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
  String get obGoalTitle => '¿Para qué entrenas?';

  @override
  String get goalCut => 'Definición';

  @override
  String get goalCutSub => 'Pierde grasa y conserva músculo y fuerza';

  @override
  String get goalMaintain => 'Mantener';

  @override
  String get goalMaintainSub => 'Mantén el peso y sigue registrando con honestidad';

  @override
  String get goalBulk => 'Volumen limpio';

  @override
  String get goalBulkSub => 'Gana tamaño al 0,25–0,5% del peso corporal por semana';

  @override
  String get obBodyTitle => 'Sobre ti';

  @override
  String get obBodyBody => 'Solo para arrancar la primera semana. A los 14 días manda tu gasto real.';

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
      'Una estimación, no un veredicto. Tras dos o tres semanas de registro, Gymco la sustituye por tu gasto medido.';

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

  @override
  String trainTitleTpl(String accent) {
    return 'Entrena $accent';
  }

  @override
  String get trainAccent => 'fuerte';

  @override
  String get routines => 'Rutinas';

  @override
  String get newRoutine => 'Nueva rutina';

  @override
  String get editRoutine => 'Editar rutina';

  @override
  String get emptyWorkout => 'Entreno vacío';

  @override
  String get startRoutine => 'Empezar';

  @override
  String get resumeWorkout => 'Seguir';

  @override
  String inProgress(String time) {
    return 'Entreno en curso · $time';
  }

  @override
  String get noRoutinesTitle => 'Aún no hay rutinas';

  @override
  String get noRoutinesBody => 'Crea una, o empieza un entreno vacío y añade ejercicios sobre la marcha.';

  @override
  String get history => 'Historial';

  @override
  String get noHistory => 'Aquí aparecen los entrenos terminados.';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count series', one: '1 serie');
    return '$_temp0';
  }

  @override
  String exercisesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ejercicios', one: '1 ejercicio');
    return '$_temp0';
  }

  @override
  String get routineName => 'Nombre de la rutina';

  @override
  String get addExercise => 'Añadir ejercicio';

  @override
  String get save => 'Guardar';

  @override
  String nameTaken(String name) {
    return 'Ya tienes una rutina llamada «$name».';
  }

  @override
  String get deleteRoutine => 'Eliminar rutina';

  @override
  String get deleteRoutineTitle => '¿Eliminar esta rutina?';

  @override
  String get deleteRoutineBody => 'Los entrenos que ya hiciste se quedan en tu historial.';

  @override
  String get edit => 'Editar';

  @override
  String get setsLabel => 'Series';

  @override
  String get repsLabel => 'Repeticiones';

  @override
  String get restLabel => 'Descanso';

  @override
  String repRange(int lo, int hi) {
    return '$lo–$hi reps';
  }

  @override
  String restSeconds(int s) {
    return '$s s de descanso';
  }

  @override
  String get searchExercises => 'Buscar ejercicios';

  @override
  String get allMuscles => 'Todos';

  @override
  String addCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Añadir $count ejercicios',
      one: 'Añadir 1 ejercicio',
    );
    return '$_temp0';
  }

  @override
  String get m_chest => 'Pecho';

  @override
  String get m_shoulders => 'Hombros';

  @override
  String get m_triceps => 'Tríceps';

  @override
  String get m_biceps => 'Bíceps';

  @override
  String get m_forearms => 'Antebrazos';

  @override
  String get m_lats => 'Dorsales';

  @override
  String get m_middle_back => 'Espalda media';

  @override
  String get m_lower_back => 'Lumbar';

  @override
  String get m_traps => 'Trapecios';

  @override
  String get m_abdominals => 'Abdomen';

  @override
  String get m_quadriceps => 'Cuádriceps';

  @override
  String get m_hamstrings => 'Isquios';

  @override
  String get m_glutes => 'Glúteos';

  @override
  String get m_calves => 'Gemelos';

  @override
  String get m_adductors => 'Aductores';

  @override
  String get m_abductors => 'Abductores';

  @override
  String get m_neck => 'Cuello';

  @override
  String get finish => 'Terminar';

  @override
  String get discard => 'Descartar entreno';

  @override
  String get discardTitle => '¿Descartar este entreno?';

  @override
  String get discardBody => 'No se guardará nada.';

  @override
  String get unfinishedTitle => 'Hay series sin marcar';

  @override
  String get unfinishedBody => 'Solo se guardan las series marcadas.';

  @override
  String get finishAnyway => 'Terminar';

  @override
  String get keepGoing => 'Seguir';

  @override
  String get durationLbl => 'Tiempo';

  @override
  String get volumeLbl => 'Volumen';

  @override
  String get setsDoneLbl => 'Series';

  @override
  String get addSet => 'Añadir serie';

  @override
  String get previous => 'Anterior';

  @override
  String get kgLbl => 'kg';

  @override
  String get repsLbl => 'reps';

  @override
  String get restRunning => 'Descanso';

  @override
  String get skip => 'Saltar';

  @override
  String get setTypeTitle => 'Tipo de serie';

  @override
  String get stWarmup => 'Calentamiento';

  @override
  String get stWarmupSub => 'Prepara el ejercicio. No cuenta en las series semanales.';

  @override
  String get stNormal => 'Serie efectiva';

  @override
  String get stNormalSub => 'Cuenta como una serie dura.';

  @override
  String get stFailure => 'Al fallo';

  @override
  String get stFailureSub => 'Cuenta como una serie dura.';

  @override
  String get stDrop => 'Serie descendente';

  @override
  String get stDropSub => 'Cuenta como media serie.';

  @override
  String get removeSet => 'Quitar serie';

  @override
  String get removeExercise => 'Quitar ejercicio';

  @override
  String get summaryTitle => 'Entreno terminado';

  @override
  String newBest(String exercise) {
    return 'Nueva marca: $exercise';
  }

  @override
  String estOneRm(String kg) {
    return '1RM estimado $kg kg';
  }

  @override
  String get doneBtn => 'Listo';

  @override
  String get instructions => 'Cómo hacerlo';

  @override
  String get primaryMuscles => 'Músculos principales';

  @override
  String get secondaryMuscles => 'También trabaja';

  @override
  String get photoUnavailable => 'Foto no disponible sin conexión';

  @override
  String get workoutDefaultName => 'Entreno';

  @override
  String get startWorkoutHint => 'Añade un ejercicio para empezar.';

  @override
  String minutesShort(String m) {
    return '$m min';
  }

  @override
  String get tickSetHint => 'Marcar serie';

  @override
  String get about => 'unos';

  @override
  String get actSitting => 'Casi siempre sentado';

  @override
  String get actSittingSub => 'Trabajo de oficina, menos de 5.000 pasos';

  @override
  String get actFeet => 'De pie';

  @override
  String get actFeetSub => 'Caminando mucho, 5.000–10.000 pasos';

  @override
  String get actPhysical => 'Trabajo físico';

  @override
  String get actPhysicalSub => 'Levantando o cargando casi todo el día';

  @override
  String get actVery => 'Muy activo';

  @override
  String get actVerySub => 'Más de 12.000 pasos o un segundo deporte';

  @override
  String get addFoodToMeal => 'Añadir alimento a esta comida';

  @override
  String get addNoWeighing => 'Añade lo que comiste — sin pesar';

  @override
  String get addWater => 'Añadir 250 ml de agua';

  @override
  String get agreeToContinue => 'Acepta para continuar';

  @override
  String get backToToday => 'Volver a hoy';

  @override
  String get calorieFloor => 'Mínimo de calorías';

  @override
  String get cheatAllowanceNote =>
      'Nunca se compensa con cardio. Una comida reservada resta un poco a los días anteriores; una libre simplemente no se registra.';

  @override
  String get chooseRoutine => 'Elegir una rutina';

  @override
  String get cm => 'cm';

  @override
  String get consentHealth =>
      'Acepto que Gymco guarde mi peso, medidas y registros de comida como datos de salud en este teléfono para calcular mis objetivos.';

  @override
  String get copiedToToday => 'Copiado a hoy';

  @override
  String get copyToToday => 'Copiar a hoy';

  @override
  String get createdByYou => 'creado por ti';

  @override
  String get custom => 'Personalizados';

  @override
  String get customFood => 'Alimento personalizado';

  @override
  String get deleteDigit => 'Borrar el último dígito';

  @override
  String get emptyMeal => 'Comida vacía';

  @override
  String get firstRunTip =>
      'La mayoría registra las mismas ocho o diez cosas. Créalas una vez y un día lleva unos veinte segundos.';

  @override
  String get floorBody =>
      'Los objetivos nunca bajan de aquí. Bajar más exige escribir el número tú mismo, tras un aviso.';

  @override
  String get floorSub => 'kcal · tu mínimo';

  @override
  String get followsPhone => 'Sigue a tu teléfono';

  @override
  String get freeAlways => 'gratis, siempre';

  @override
  String get genericUsda => 'Genérico · USDA';

  @override
  String get genericUsdaVerified => 'Genérico · USDA · verificado';

  @override
  String get goalAndTargets => 'Objetivo y metas';

  @override
  String get goalRecomp => 'Recomposición';

  @override
  String get goalRecompSub => 'Quédate cerca del mantenimiento; mira la cintura, no la báscula';

  @override
  String get goalPrep => 'Preparación de competición';

  @override
  String get goalPrepSub => 'Planifica hacia atrás desde la fecha';

  @override
  String get goalShortCut => 'definición';

  @override
  String get goalShortBulk => 'volumen';

  @override
  String get goalShortRecomp => 'recomposición';

  @override
  String get goalShortMaintain => 'mantenimiento';

  @override
  String get goalShortPrep => 'preparación';

  @override
  String get habitMealsNone => 'Comidas registradas, ninguna saltada';

  @override
  String get habitProteinEach => 'Una fuente de proteína en cada una';

  @override
  String get habitTrained => 'Entrenaste hoy';

  @override
  String get habitsHiddenBody =>
      'Tus registros se siguen guardando. Nada se puntúa y no hay objetivo que se mida contra ti.';

  @override
  String get habitsHiddenTitle => 'Calorías, macros y peso están ocultos';

  @override
  String get heightLbl => 'Altura';

  @override
  String get heroDoneBody => 'Registrado y guardado. La recuperación lo convierte en el siguiente.';

  @override
  String get heroExercises => 'ejercicios';

  @override
  String get heroMin => 'min';

  @override
  String get heroMuscles => 'músculos';

  @override
  String get heroRestBody => 'Nada programado hoy. La recuperación convierte la última sesión en la siguiente.';

  @override
  String get heroRestTitle => 'Día de <em>descanso</em>';

  @override
  String get heroSets => 'series';

  @override
  String get heroSetupBody => 'Elige una rutina o crea la tuya. Gymco la programa y sigue cada serie.';

  @override
  String get heroSetupTitle => 'Prepara tu <em>entreno</em>';

  @override
  String get heroTagDone => 'Hecho hoy';

  @override
  String get heroTagInProgress => 'En curso';

  @override
  String get heroTagToday => 'Entreno de hoy';

  @override
  String get howTodayWent => 'Cómo fue hoy';

  @override
  String get inThisMeal => 'En esta comida';

  @override
  String get kcalADay => 'kcal al día';

  @override
  String get kcalLeftLabel => 'kcal restantes';

  @override
  String get kcalLoggedLabel => 'kcal registradas';

  @override
  String get kcalOverLabel => 'kcal sobre el objetivo';

  @override
  String get kcalToLog => 'kcal por registrar';

  @override
  String get keepThemHidden => 'Mantenerlos ocultos';

  @override
  String get langArabicSub => 'Árabe · de derecha a izquierda';

  @override
  String get langEnglishSub => 'Inglés';

  @override
  String get langSpanishSub => 'Español';

  @override
  String get logFirstMeal => 'Registra tu primera comida';

  @override
  String get logNoWeighing => 'Registra lo que comiste — sin pesar';

  @override
  String get mBarcode => 'Código';

  @override
  String get mPhoto => 'Foto';

  @override
  String get mSearch => 'Buscar';

  @override
  String get mVoice => 'Voz';

  @override
  String get mWrite => 'Escribir';

  @override
  String get mealDetailTip => 'Toca un alimento para cambiar la ración. Lo que quites sale de hoy al momento.';

  @override
  String get mealLabel => 'Comida';

  @override
  String get myMeals => 'Mis comidas';

  @override
  String get noMatchBody => 'La cocina casera rara vez lo está. Escanea el envase o prueba otra palabra.';

  @override
  String get noMatchTitle => 'Sin coincidencias en la base de datos';

  @override
  String get noNumbersOfferLine =>
      '¿Prefieres no ver números? El modo sin números oculta calorías, macros y peso, y sigue hábitos.';

  @override
  String get noNumbersOn => 'Activado — calorías y peso ocultos';

  @override
  String get noSessionPlanned => 'Sin sesión planificada';

  @override
  String get nothingInMeal => 'Aún no hay nada en esta comida';

  @override
  String get nothingYesterdayDay => 'Ayer no se registró nada';

  @override
  String get numbersHidden => 'Números ocultos';

  @override
  String get obActivityTitleEm => '¿Cómo te <em>mueves</em> en un día normal?';

  @override
  String get obBodyTitleEm => 'Un poco sobre <em>ti</em>';

  @override
  String get obGoalBody =>
      'Esto fija tu ritmo, tu mínimo de proteína y cómo se leen tus datos. Puedes cambiarlo cualquier semana.';

  @override
  String get obRateBodyGain =>
      'Lento es limpio. Un cuarto a medio por ciento del peso por semana mantiene la ganancia sobre todo en músculo.';

  @override
  String get obRateBodyLose =>
      'Más rápido no es mejor. Entre el 0,5 y el 1% del peso por semana se conserva el músculo.';

  @override
  String get obRateTitleGain => '¿A qué ritmo quieres ganar?';

  @override
  String get obRateTitleLose => '¿A qué ritmo quieres perder?';

  @override
  String get pastNoteWithin => 'A menos de cien del objetivo. Días así son los que mueven la tendencia.';

  @override
  String get pctPerWeek => '% / semana';

  @override
  String get photoComing =>
      'Fotografía el plato y Gymco sugiere lo que ve; tú dices cuánto. Llega con el registro con IA.';

  @override
  String get rateHot =>
      'Por encima del 0,85% semanal empiezas a pagar con músculo. Gymco lo dirá cada semana hasta que bajes el ritmo.';

  @override
  String get rateOkGain => 'Lo bastante lento para que casi todo sea músculo.';

  @override
  String get rateOkLose => 'En el rango que Helms et al. (2014) recomiendan para conservar músculo en déficit.';

  @override
  String get readyToLog => 'listo para registrar';

  @override
  String get recipes => 'Recetas';

  @override
  String get restDay => 'Día de descanso';

  @override
  String get ringEmptyBody => 'Aún no hay nada. Tus objetivos están listos — el anillo se llena según avanzas.';

  @override
  String get rtlNote => 'El árabe pone toda la app de derecha a izquierda, incluida la tira de la semana y los gestos.';

  @override
  String get safeguards => 'Salvaguardas';

  @override
  String get savedSeeTrain => 'Guardado · míralo en Entrenar';

  @override
  String get scanABarcode => 'Escanear un código';

  @override
  String get scanBarcodeSub => 'Lo envasado va directo a los números del envase';

  @override
  String get searchDatabase => 'Buscar en la base de datos';

  @override
  String get searchOtherLanguage =>
      'Buscar en otro idioma suele encontrar más — Gymco guarda cada nombre que aprende en el mismo alimento.';

  @override
  String get seeTheWeek => 'Ver la semana';

  @override
  String get settings => 'Ajustes';

  @override
  String get sexForEquation => 'Sexo para la ecuación de energía';

  @override
  String get startLogging => 'Empezar a registrar';

  @override
  String get startWorkout => 'Empezar entreno';

  @override
  String get supportBody => 'Líneas de ayuda y servicios cerca de ti';

  @override
  String get supportTitle => 'Hablar con alguien ayuda';

  @override
  String get swipeToStart => 'Desliza para empezar';

  @override
  String get targetsSaved => 'Objetivos guardados — empieza a registrar';

  @override
  String get theRemainder => 'el resto';

  @override
  String get todayPlain => 'Hoy';

  @override
  String get todayTitleEm => 'Haz que <em>cuente</em>';

  @override
  String get training => 'Entreno';

  @override
  String get trainingCountedSeparately => 'El entreno se cuenta aparte. No incluyas el gimnasio aquí.';

  @override
  String get trendNeedsDays => 'Una tendencia necesita unos siete días';

  @override
  String get trendWeight => 'Peso de tendencia';

  @override
  String get unitsLanguage => 'Unidades e idioma';

  @override
  String get usuallyNow => 'Sueles comer a esta hora';

  @override
  String get voiceComing =>
      'Mantén pulsado y di lo que comiste. Pasa por el mismo lector que la escritura. Llega con el registro con IA.';

  @override
  String get water => 'Agua';

  @override
  String get waterAdded => '250 ml añadidos';

  @override
  String get weightToday => 'Peso hoy';

  @override
  String get welcomeArtAlt => 'Una mujer en pleno swing con kettlebell';

  @override
  String get welcomeBody => 'Registra comida en segundos, entrena con un plan y mantén una racha que valga la pena.';

  @override
  String get welcomeTitleEm => 'Empieza hoy tu camino <em>fitness</em>';

  @override
  String get writeComing =>
      'Escribe la comida como la dirías — «dos huevos, 150 g de arroz». Llega con el registro con IA.';

  @override
  String get yesterdayCopied => 'Ayer copiado';

  @override
  String get yrs => 'años';

  @override
  String addKcal(String kcal) {
    return 'Añadir $kcal kcal';
  }

  @override
  String saveKcal(String kcal) {
    return 'Guardar · $kcal kcal';
  }

  @override
  String addToMeal(String meal) {
    return 'Añadir a $meal';
  }

  @override
  String closedDay(String date) {
    return '$date · día cerrado';
  }

  @override
  String floorNote(String kcal) {
    return 'Tus objetivos nunca bajarán de $kcal kcal.';
  }

  @override
  String foodAdded(String food) {
    return '$food añadido';
  }

  @override
  String foodRemoved(String food) {
    return '$food quitado';
  }

  @override
  String removeFood(String food) {
    return 'Quitar $food';
  }

  @override
  String gPerKg(String g) {
    return '$g g/kg';
  }

  @override
  String heroDoneTitle(String name) {
    return '$name <em>hecho</em>';
  }

  @override
  String heroWeekTag(int n) {
    return 'Semana $n';
  }

  @override
  String itemsLoggedTo(int count, String meal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos registrados en $meal',
      one: '1 alimento registrado en $meal',
    );
    return '$_temp0';
  }

  @override
  String itemsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alimentos seleccionados',
      one: '1 alimento seleccionado',
    );
    return '$_temp0';
  }

  @override
  String kcalAndProtein(String kcal, String p) {
    return '$kcal kcal · $p g de proteína';
  }

  @override
  String leftToday(String kcal, String p) {
    return 'Quedan hoy $kcal kcal y $p g de proteína';
  }

  @override
  String litres(String l) {
    return '$l L';
  }

  @override
  String logN(int n) {
    return 'Registrar $n';
  }

  @override
  String maxPct(String pct) {
    return '$pct máx.';
  }

  @override
  String meSub(String goal, int week) {
    return '$goal, semana $week';
  }

  @override
  String moreCount(int n) {
    return '+$n más';
  }

  @override
  String ofTarget(String n) {
    return '/ $n g';
  }

  @override
  String oneServing(String g) {
    return '1 ración · $g g';
  }

  @override
  String pastNoteOver(String n) {
    return '$n sobre el objetivo — un día, y lo que cuenta es la media semanal.';
  }

  @override
  String pastNoteUnder(String n) {
    return '$n bajo el objetivo. Una vez vale; como hábito pierdes más que grasa.';
  }

  @override
  String ratePerWeekShort(String pct) {
    return '$pct %/sem';
  }

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count resultados', one: '1 resultado');
    return '$_temp0';
  }

  @override
  String resumeAt(String time) {
    return 'Seguir · $time';
  }

  @override
  String setTo(String food, String g) {
    return '$food ajustado a $g g';
  }

  @override
  String shareOfToday(int pct) {
    return '$pct% de hoy';
  }

  @override
  String targetsHow(String mult, String rate) {
    return 'Mifflin-St Jeor × $mult, y luego tu ritmo de $rate%/semana. Todo es editable.';
  }

  @override
  String targetsHowMaintain(String mult) {
    return 'Mifflin-St Jeor × $mult, en mantenimiento. Todo es editable.';
  }

  @override
  String targetsLine(String p, String c, String f) {
    return 'Proteína $p g · Carbohidratos $c g · Grasa $f g';
  }

  @override
  String todaySub(String date, String goal, int week) {
    return '$date · $goal, semana $week';
  }

  @override
  String todaySubDayOne(String date) {
    return '$date · día 1';
  }

  @override
  String weighInsSoFar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pesajes por ahora',
      one: 'Un pesaje por ahora',
      zero: 'Aún sin pesajes',
    );
    return '$_temp0';
  }

  @override
  String whatDidYouHave(String meal) {
    return '¿Qué tomaste en $meal?';
  }

  @override
  String get mealOptions => 'Opciones de la comida';

  @override
  String get saveAsMeal => 'Guardar como comida';

  @override
  String get savedToMyMeals => 'Guardada — está en Mis comidas';

  @override
  String get copyToTomorrow => 'Copiar a mañana';

  @override
  String get copiedToTomorrow => 'Copiada a mañana';

  @override
  String get clearMeal => 'Vaciar esta comida';

  @override
  String lastLogged(String time) {
    return 'Último registro $time';
  }

  @override
  String get saveToFavourites => 'Guardar en favoritos';

  @override
  String get savedToFavourites => 'Guardado en favoritos';

  @override
  String get removedFromFavourites => 'Quitado de favoritos';

  @override
  String get saveAsCustom => 'Guardar como propio';

  @override
  String get savedAsCustom => 'Guardado como alimento propio';

  @override
  String labelVerifiedOff(String brand) {
    return '$brand · etiqueta verificada · Open Food Facts';
  }

  @override
  String get noSavedMeals => 'Aún no hay comidas guardadas. Abre una comida que repitas y pulsa Guardar como comida.';

  @override
  String get noCustomFoods =>
      'Aún no hay alimentos propios. Abre cualquiera y pulsa Guardar como propio para tener tu copia.';

  @override
  String get recipesSoon => 'Las recetas llegan pronto: créala con ingredientes, divídela en raciones y registra una.';

  @override
  String savedMealSub(int count, String kcal) {
    return '$count elementos · $kcal kcal';
  }

  @override
  String loggedSavedMeal(String name) {
    return '$name registrada';
  }

  @override
  String get yourData => 'Tus datos';

  @override
  String get yourDataSub => 'Exportar, consentimientos, borrarlo todo';

  @override
  String get takeEverything => 'Llévatelo todo';

  @override
  String get takeEverythingSub => 'CSV y JSON, todas las tablas';

  @override
  String foodLogRows(String n) {
    return 'Registro · $n filas';
  }

  @override
  String weighInsCount(String n) {
    return 'Pesajes · $n';
  }

  @override
  String get exportNow => 'Exportar ahora';

  @override
  String get exportFailed => 'No se pudo exportar — inténtalo de nuevo';

  @override
  String get whatYouAgreed => 'Lo que aceptaste y cuándo';

  @override
  String get consentHealthRow => 'Tratamiento de datos de salud · v1';

  @override
  String get consentAnalyticsRow => 'Analítica anónima · no se recoge';

  @override
  String get onPhoneNote =>
      'Todo vive en este teléfono. No hay cuenta ni servidor, así que nada sale salvo que lo exportes.';

  @override
  String get deleteEverything => 'Borrarlo todo';

  @override
  String get deleteEverythingSub => 'Un toque y una confirmación';

  @override
  String get deleteEverythingBody =>
      'Tu registro, entrenos, rutinas, pesajes y objetivos se borran al momento. Exporta antes si quieres tu historial: no se puede recuperar.';

  @override
  String get deleteAllData => 'Borrar todos los datos';

  @override
  String get deleteConfirmTitle => '¿Borrarlo todo?';

  @override
  String get deleteConfirm => 'Sí, borrarlo todo';

  @override
  String get keepMyData => 'Conservar mis datos';

  @override
  String dataSetsCount(String n) {
    return 'Series · $n';
  }

  @override
  String get setMacrosManually => 'Fijar mis macros a mano';

  @override
  String get useTheseMacros => 'Usar estos macros';

  @override
  String get backToCalculated => 'Volver al reparto calculado';

  @override
  String manualKcal(String kcal) {
    return 'Suma $kcal kcal al día.';
  }

  @override
  String manualBelowFloor(String kcal, String floor) {
    return 'Suma $kcal kcal, por debajo del mínimo de $floor. Solo con alguien cualificado supervisando.';
  }

  @override
  String projectedKg(String kg) {
    return 'Previsto $kg kg';
  }

  @override
  String aroundDate(String date) {
    return 'hacia el $date';
  }

  @override
  String inWeeks(int n) {
    return 'en $n semanas';
  }

  @override
  String moreOf(String what) {
    return 'Más $what';
  }

  @override
  String lessOf(String what) {
    return 'Menos $what';
  }
}
