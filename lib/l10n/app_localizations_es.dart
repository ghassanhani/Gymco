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
    return 'Ya tienes una rutina llamada $name. Elige otro nombre o edita esa.';
  }

  @override
  String get deleteRoutine => 'Eliminar rutina';

  @override
  String get deleteRoutineTitle => '¿Eliminar esta rutina?';

  @override
  String get deleteRoutineBody =>
      'La rutina se elimina. Cada entreno que registraste con ella se queda en tu historial, con sus series y récords.';

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
  String get durationLbl => 'Duración';

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
  String get stWarmupSub => 'No cuenta en las series semanales';

  @override
  String get stNormal => 'Normal';

  @override
  String get stNormalSub => 'Una serie de trabajo efectiva';

  @override
  String get stFailure => 'Fallo';

  @override
  String get stFailureSub => 'Llevada al fallo técnico';

  @override
  String get stDrop => 'Serie descendente';

  @override
  String get stDropSub => 'Cuenta como media serie';

  @override
  String get removeSet => 'Quitar esta serie';

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
  String get langArabicSub => 'Árabe · de derecha a izquierda';

  @override
  String get langEnglishSub => 'Inglés';

  @override
  String get langSpanishSub => 'Español';

  @override
  String get logFirstMeal => 'Registra tu primera comida';

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
  String get noSessionPlanned => 'Sin sesión planificada';

  @override
  String get nothingInMeal => 'Aún no hay nada en esta comida';

  @override
  String get nothingYesterdayDay => 'Ayer no se registró nada';

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
  String get rateHot =>
      'Por encima del 0,85% semanal empiezas a pagar con músculo. Gymco lo dirá cada semana hasta que bajes el ritmo.';

  @override
  String get rateOkGain => 'Lo bastante lento para que casi todo sea músculo.';

  @override
  String get rateOkLose => 'En el rango que Helms et al. (2014) recomiendan para conservar músculo en déficit.';

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
  String get targetsSaved => 'Objetivos guardados — empieza a registrar';

  @override
  String get theRemainder => 'el resto';

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
  String get weightToday => 'Peso hoy';

  @override
  String get welcomeArtAlt => 'Una mujer en pleno swing con kettlebell';

  @override
  String get welcomeBody => 'Registra comida en segundos, entrena con un plan y mantén una racha que valga la pena.';

  @override
  String get welcomeTitleEm => 'Empieza hoy tu camino <em>fitness</em>';

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

  @override
  String get trainTitleEm => 'Entrena <em>duro</em>';

  @override
  String trainSub(int days, int week) {
    return '$days días a la semana · semana $week';
  }

  @override
  String get noWeeklyPlan => 'Aún sin plan semanal';

  @override
  String dayAhead(String date) {
    return '$date · próximo';
  }

  @override
  String dayClosed(String date) {
    return '$date · cerrado';
  }

  @override
  String get todayLbl => 'Hoy';

  @override
  String plannedOn(String day) {
    return 'Planificado · $day';
  }

  @override
  String movedHere(String day) {
    return 'Movido aquí · era el $day';
  }

  @override
  String loggedOfPlanned(int done, int total, int sets) {
    return '$done de $total registrados · $sets series planificadas';
  }

  @override
  String setsAbout(int sets, int min) {
    return '$sets series · unos $min min';
  }

  @override
  String get startEarly => 'Empezar antes';

  @override
  String get startAll => 'Empezar todo';

  @override
  String get startEarlyNote =>
      'Empezarla antes adelanta el resto de la semana: el bloque conserva su orden, no sus fechas.';

  @override
  String get lastTimeRan => 'La última vez que la hiciste';

  @override
  String get somethingElse => 'Otra cosa en su lugar';

  @override
  String restMissed(String name) {
    return '$name tocaba y no se registró nada. Pasó a tu siguiente día de entreno: la semana se desliza, el orden se mantiene.';
  }

  @override
  String restAhead(String day) {
    return 'Nada programado. El $day es uno de los días libres de esta semana.';
  }

  @override
  String get restPast =>
      'No se registró nada y no tocaba nada. En la recuperación la última sesión se convierte en la siguiente.';

  @override
  String get nextSession => 'Próxima sesión';

  @override
  String get sessionAfter => 'La sesión siguiente';

  @override
  String get logAnyway => 'Registrar algo de todos modos';

  @override
  String get allRoutines => 'Todas las rutinas';

  @override
  String allRoutinesSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n rutinas', one: '1 rutina');
    return '$_temp0 · tu biblioteca de ejercicios';
  }

  @override
  String weeklySetsOf(String group) {
    return 'Series semanales · $group';
  }

  @override
  String hardSetsN(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n series efectivas', one: '1 serie efectiva');
    return '$_temp0';
  }

  @override
  String get zoneIn => 'en la zona productiva';

  @override
  String get zoneUnder => 'por debajo de la zona productiva';

  @override
  String get zoneOver => 'por encima de la zona productiva';

  @override
  String get gBack => 'Espalda';

  @override
  String get gLegs => 'Piernas';

  @override
  String get gCore => 'Core';

  @override
  String get closedLbl => 'Cerrado';

  @override
  String get hardSetsLbl => 'Series efectivas';

  @override
  String get bestSetEach => 'Mejor serie de cada ejercicio';

  @override
  String runAgain(String name) {
    return 'Repetir $name';
  }

  @override
  String get trainEmptyBody => 'Aún no hay nada. Empieza con una plantilla probada o crea exactamente lo que ya haces.';

  @override
  String get startEmptyWorkout => 'Empezar un entreno vacío';

  @override
  String get startEmptySub => 'Añade ejercicios sobre la marcha; luego se convierte en rutina';

  @override
  String get buildOwn => 'Crear mi propia rutina';

  @override
  String get buildOwnSub => 'Rutinas ilimitadas, gratis';

  @override
  String get orTemplate => 'O empieza con una plantilla';

  @override
  String get tplUL => 'Torso / Pierna, 4 días';

  @override
  String get tplULSub => '12–18 series por músculo a la semana · intermedio';

  @override
  String get tplPPL => 'Empuje / Tirón / Pierna, 6 días';

  @override
  String get tplPPLSub => 'Alta frecuencia · avanzado';

  @override
  String get tplFB => 'Cuerpo completo, 3 días';

  @override
  String get tplFBSub => 'La que conviene en definición · cualquier nivel';

  @override
  String templateAdded(String name) {
    return '$name añadido a tu plan semanal';
  }

  @override
  String get tplUpperA => 'Torso A';

  @override
  String get tplUpperB => 'Torso B';

  @override
  String get tplLowerA => 'Pierna A';

  @override
  String get tplLowerB => 'Pierna B';

  @override
  String get tplPushA => 'Empuje A';

  @override
  String get tplPushB => 'Empuje B';

  @override
  String get tplPullA => 'Tirón A';

  @override
  String get tplPullB => 'Tirón B';

  @override
  String get tplLegsA => 'Pierna A';

  @override
  String get tplLegsB => 'Pierna B';

  @override
  String get tplFullA => 'Cuerpo completo A';

  @override
  String get tplFullB => 'Cuerpo completo B';

  @override
  String get tplFullC => 'Cuerpo completo C';

  @override
  String inProgressName(String name) {
    return '$name en curso';
  }

  @override
  String resumeSub(String time, int done, int total) {
    return '$time · $done de $total series';
  }

  @override
  String get discardShort => 'Descartar';

  @override
  String get workoutDiscarded => 'Entreno descartado: no se guardó nada';

  @override
  String routinesSubLib(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n rutinas', one: '1 rutina');
    return '$_temp0 · una por día, o cualquier día';
  }

  @override
  String get newShort => 'Nueva';

  @override
  String get folderPlan => 'Plan semanal';

  @override
  String get folderMine => 'Mis rutinas';

  @override
  String get anyDay => 'Cualquier día';

  @override
  String everyDay(String day) {
    return 'Cada $day';
  }

  @override
  String routineCardSub(String when, int sets) {
    return '$when · $sets series';
  }

  @override
  String get addToFolder => 'Añadir una rutina a esta carpeta';

  @override
  String get myExercises => 'Mis ejercicios';

  @override
  String myExercisesSub(int n) {
    return '$n en la biblioteca · siempre gratis';
  }

  @override
  String get exploreRoutines => 'Explorar rutinas';

  @override
  String get exploreSub => 'Plantillas con el volumen de series ya dentro del rango que respalda la evidencia';

  @override
  String optionsFor(String name) {
    return 'Opciones de $name';
  }

  @override
  String get startRoutineFull => 'Empezar rutina';

  @override
  String get editRoutineSub => 'Ejercicios, número de series, rangos de repeticiones';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get duplicateSub => 'Una copia que puedes cambiar sin tocar esta';

  @override
  String get deleteRoutineSub => 'Tu historial se conserva';

  @override
  String copyName(String name) {
    return 'Copia de $name';
  }

  @override
  String duplicated(String name) {
    return 'Copiada como $name';
  }

  @override
  String deleteNamed(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get keepIt => 'Conservarla';

  @override
  String get neverRun => 'nunca hecha';

  @override
  String doneOn(String date) {
    return 'hecha el $date';
  }

  @override
  String get estDuration => 'Duración est.';

  @override
  String get exercisesLbl => 'Ejercicios';

  @override
  String itemLine(int sets, String reps, int rir, String rest) {
    return '$sets series · $reps reps @ RIR $rir · descanso $rest';
  }

  @override
  String get weekEffect => 'Lo que esto hace a tu semana';

  @override
  String get weekIfSave => 'Series semanales si guardas esto';

  @override
  String setsWkState(String state) {
    return 'series/sem · $state';
  }

  @override
  String get inRange => 'en rango';

  @override
  String get belowRange => 'por debajo';

  @override
  String get aboveRange => 'por encima';

  @override
  String get volumeNote =>
      'Contando esta rutina sobre lo que ya hace el resto de tu semana. Entre diez y veinte series efectivas por músculo a la semana es donde la evidencia es más sólida: por debajo dejas crecimiento sobre la mesa, por encima compras sobre todo fatiga.';

  @override
  String exLineLabel(String name, int sets, String reps) {
    return '$name, $sets series de $reps';
  }

  @override
  String get loggedLbl => 'Registrado';

  @override
  String startOnItsOwn(String name) {
    return 'Empezar $name por separado';
  }

  @override
  String builderSub(int n, int sets, int min) {
    return '$n ejercicios · $sets series · unos $min min';
  }

  @override
  String get nothingYet => 'Aún vacía';

  @override
  String get nameLbl => 'Nombre';

  @override
  String get namePlaceholder => 'Empuje A, Pierna pesada, martes…';

  @override
  String get folderLbl => 'Carpeta';

  @override
  String get dayLbl => 'Día';

  @override
  String dayTakenBy(String day, String name) {
    return '$day, ocupado por $name';
  }

  @override
  String dayTaken(String name, String day) {
    return '$name ya está el $day. Al guardar, esa pasa a Cualquier día.';
  }

  @override
  String get anyDayNote => 'Hazla cuando quieras: queda fuera de la rotación semanal.';

  @override
  String get dayNote => 'Si la saltas, pasa a tu siguiente día de entreno y el bloque mantiene su orden.';

  @override
  String get builderEmpty =>
      'Aún no hay ejercicios. Añade el primero y Gymco te mostrará lo que hace a tus series semanales.';

  @override
  String repsChip(String reps) {
    return '$reps reps';
  }

  @override
  String restChip(String t) {
    return 'descanso $t';
  }

  @override
  String get oneSetFewer => 'Una serie menos';

  @override
  String get oneSetMore => 'Una serie más';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get repRangeLbl => 'Rango de repeticiones';

  @override
  String repRangeTitle(String name) {
    return 'Rango de reps · $name';
  }

  @override
  String get repRangeNote =>
      'De cinco a treinta repeticiones construyen músculo si la serie se acerca al fallo. Los rangos pesados cuestan más descanso y más articulaciones; los ligeros, más incomodidad.';

  @override
  String restBetween(String name) {
    return 'Descanso entre series · $name';
  }

  @override
  String restBetweenSub(String t) {
    return '$t entre series';
  }

  @override
  String get restBetweenNote =>
      'Es lo que sugerirá el temporizador durante el entreno. Allí podrás cambiarlo serie a serie.';

  @override
  String get removeFromRoutine => 'Quitar de la rutina';

  @override
  String get hintName => 'Ponle un nombre para guardar';

  @override
  String get hintTaken => 'Ese nombre ya existe';

  @override
  String get hintExercise => 'Añade al menos un ejercicio';

  @override
  String get saveRoutine => 'Guardar rutina';

  @override
  String routineSaved(String name) {
    return '$name guardada';
  }

  @override
  String get leaveTitle => '¿Salir sin guardar?';

  @override
  String leaveEditing(String name) {
    return 'Se perderán tus cambios en $name.';
  }

  @override
  String get leaveNew => 'Esta rutina aún no se ha guardado.';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get minimise => 'Minimizar entreno';

  @override
  String get restTimer => 'Temporizador de descanso';

  @override
  String get offLbl => 'No';

  @override
  String get notePlaceholder => 'Añade una nota: una pista, el ajuste de la máquina, cómo fue';

  @override
  String get setH => 'Serie';

  @override
  String get rirLbl => 'RIR';

  @override
  String completeSet(String n) {
    return 'Completar serie $n';
  }

  @override
  String setTypeLabel(String type) {
    return 'Tipo de serie: $type';
  }

  @override
  String get supersetBadge => 'Superserie · sin descanso entre medias';

  @override
  String get unlink => 'Separar';

  @override
  String get supersetNote =>
      'El temporizador solo empieza al terminar la pareja. Ambas cuentan como series completas para sus músculos.';

  @override
  String get emptyWorkoutBody => 'Entreno vacío. El reloj ya corre: añade el primer ejercicio cuando quieras.';

  @override
  String restAfterEachTitle(String name) {
    return 'Descanso tras cada serie · $name';
  }

  @override
  String get restNote =>
      'Tres minutos o más para los compuestos pesados: menos descanso te cuesta repeticiones, y las repeticiones son el estímulo.';

  @override
  String restAfterEach(String t) {
    return '$t tras cada serie';
  }

  @override
  String get restOffFor => 'Desactivado para este ejercicio';

  @override
  String get supersetNext => 'Superserie con el siguiente ejercicio';

  @override
  String get supersetNextSub => 'Sin descanso entre los dos';

  @override
  String get seeHistory => 'Ver historial y 1RM';

  @override
  String get removeFromWorkout => 'Quitar de este entreno';

  @override
  String removedFromWorkout(String name) {
    return '$name quitado de este entreno';
  }

  @override
  String get nothingAfter => 'No hay nada después con lo que emparejarlo';

  @override
  String get supersetted => 'Superserie hecha: el temporizador espera a los dos';

  @override
  String exAdded(String name) {
    return '$name añadido';
  }

  @override
  String get resting => 'Descansando';

  @override
  String restingFor(String t) {
    return 'Descansando, quedan $t';
  }

  @override
  String nextSetOf(String name, int n) {
    return 'Siguiente: $name, serie $n';
  }

  @override
  String get lastSetDone => 'Última serie hecha';

  @override
  String get minus15 => '−15 s';

  @override
  String get setRemoved => 'Serie quitada';

  @override
  String get rirTitle => 'Repeticiones en reserva';

  @override
  String get rirNote => 'Cuántas más podrías haber hecho con buena técnica.';

  @override
  String editSetTitle(String n, String name) {
    return 'Serie $n · $name';
  }

  @override
  String lastTimeSet(String set) {
    return 'La última vez: $set';
  }

  @override
  String get nothingTicked => 'No marcaste nada, así que no se guardó nada';

  @override
  String setsUnticked(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n series quedaron sin marcar: no están en el registro',
      one: '1 serie quedó sin marcar: no está en el registro',
    );
    return '$_temp0';
  }

  @override
  String doneTitle(String name) {
    return '$name: hecho';
  }

  @override
  String get volumeExplain =>
      'El volumen es cada serie de trabajo completada, multiplicada. Los calentamientos están en el registro, pero no en esta cifra ni en tus series semanales.';

  @override
  String get prLbl => 'Récord';

  @override
  String insightIn(String group, String sets) {
    return '$group va por $sets esta semana: dentro del rango 10–20, donde la evidencia es más sólida. Nada que cambiar.';
  }

  @override
  String insightUnder(String group, String sets) {
    return '$group va por $sets esta semana: por debajo del rango 10–20. Una o dos sesiones más lo pondrían ahí.';
  }

  @override
  String insightOver(String group, String sets) {
    return '$group va por $sets esta semana: más de 20. A partir de ahí es sobre todo fatiga.';
  }

  @override
  String get saveAsRoutine => 'Guardar como rutina';

  @override
  String get share => 'Compartir';

  @override
  String shareText(String name, String time, String volume, String sets) {
    return '$name · $time · $volume · $sets series efectivas';
  }

  @override
  String soloLogged(String name) {
    return '$name registrado: el resto del día sigue ahí';
  }

  @override
  String get est1rm => '1RM estimado';

  @override
  String trendKg(String delta, int w) {
    return '$delta kg / $w sem';
  }

  @override
  String get months6 => '6 meses';

  @override
  String get chartNeedsTwo => 'Dos entrenos con este ejercicio y empieza la línea de tendencia.';

  @override
  String get best5 => 'Mejor de 5 reps';

  @override
  String get best8 => 'Mejor de 8 reps';

  @override
  String get setsWk => 'Series / sem';

  @override
  String get exClimbing =>
      'Este ejercicio sigue subiendo. Lo que estés haciendo con el déficit es tolerable: aún no hay motivo para frenar.';

  @override
  String get exFlat => 'Estable. En déficit, mantener es ganar.';

  @override
  String get exDropping =>
      'Por debajo de hace ocho semanas. Revisa el sueño y el tamaño del déficit antes de culpar al programa.';

  @override
  String get exNoHistory => 'Aún sin historial. Regístralo una vez y su tendencia de 1RM empieza aquí.';

  @override
  String get historyLbl => 'Historial';

  @override
  String get back => 'Volver';

  @override
  String get addAnExercise => 'Añadir un ejercicio';

  @override
  String get searchLibrary => 'Buscar en la biblioteca de ejercicios';

  @override
  String get noExerciseMatch => 'Nada coincide. Prueba una palabra más corta u otro músculo.';

  @override
  String get inLbl => 'dentro';

  @override
  String get alreadyIn => 'Ya está en este entreno';

  @override
  String thenEx(String name) {
    return 'Luego: $name';
  }

  @override
  String get progressTitleEm => 'Tu <em>progreso</em>';

  @override
  String get addWeighIn => 'Añadir un pesaje';

  @override
  String get weightTab => 'Peso';

  @override
  String get measureTab => 'Medidas';

  @override
  String get strengthTab => 'Fuerza';

  @override
  String get openCheckIn => 'Abrir la revisión de esta semana';

  @override
  String get weighInToday => 'Pesaje de hoy';

  @override
  String get weighInNote =>
      'Misma hora, misma báscula, antes del desayuno. Un pesaje dice poco; lo que cuenta es la tendencia.';

  @override
  String get weighInSaved => 'Pesaje guardado';

  @override
  String get waistToday => 'Cintura de hoy';

  @override
  String get waistNote => 'A la altura del ombligo, relajado, tras espirar.';

  @override
  String get measurementSaved => 'Medida guardada';

  @override
  String get rateLbl => 'Ritmo';

  @override
  String pctWk(String v) {
    return '$v %/sem';
  }

  @override
  String get trendNeedsTwo => 'Dos pesajes con unos días de diferencia y empieza la tendencia.';

  @override
  String get sinceStart => 'Desde el inicio';

  @override
  String get waistLbl => 'Cintura';

  @override
  String get weighInsLbl => 'Pesajes';

  @override
  String get weeklyHardSets => 'Series efectivas semanales';

  @override
  String get indirectHalf => 'indirectas cuentan ½';

  @override
  String get noSetsThisWeek => 'Aún no hay series esta semana.';

  @override
  String get allInRange => 'Cada músculo que más entrenaste está en 10 series o más esta semana.';

  @override
  String underTen(String group) {
    return '$group está por debajo de las 10 series. Vale la pena revisarlo al salir del déficit; no se arregla añadiendo volumen ahora.';
  }

  @override
  String get waistWhy =>
      'La cintura se mueve más despacio que la báscula, pero engaña menos: el agua y la comida apenas la afectan.';

  @override
  String get addMeasurement => 'Añadir una medida';

  @override
  String get strengthEmpty => 'Aún no hay ejercicios. Termina un entreno y aquí verás tus 1RM estimados.';

  @override
  String get strengthNote => '1RM estimado ahora y el cambio en ocho semanas. En déficit, mantener es ganar.';

  @override
  String e1rmLine(String kg) {
    return '1RM est. $kg kg';
  }

  @override
  String get yourWeek => 'Tu semana';

  @override
  String get flatWeeks => 'Un tramo plano';

  @override
  String checkInSub(String range, int week) {
    return '$range · semana $week';
  }

  @override
  String get adjustBtn => 'Ajustar';

  @override
  String get acceptTargets => 'Aceptar objetivos';

  @override
  String get laterBtn => 'Más tarde';

  @override
  String get notNow => 'Ahora no';

  @override
  String applyKcal(String n) {
    return 'Aplicar $n kcal';
  }

  @override
  String get applyChoice => 'Aplicar';

  @override
  String get startBreak => 'Empezar el descanso';

  @override
  String targetsUpdated(String kcal) {
    return 'Objetivos actualizados · $kcal kcal';
  }

  @override
  String get askedNextWeek => 'Anotado: lo volvemos a preguntar la semana que viene';

  @override
  String get needsTwoWeighIns => 'hacen falta pesajes con una semana de diferencia';

  @override
  String get onPlan => 'según el plan';

  @override
  String get fasterThanPlan => 'más rápido que el plan';

  @override
  String get slowerThanPlan => 'más lento que el plan';

  @override
  String get rateVsGoal => 'Ritmo vs objetivo';

  @override
  String get daysLogged => 'Días registrados';

  @override
  String nOfSeven(int n) {
    return '$n de 7';
  }

  @override
  String get allSevenDays => 'todos los días';

  @override
  String get fullDaysOnly => 'solo días completos';

  @override
  String get measuredExpenditure => 'Gasto medido';

  @override
  String get notMeasuredYet => 'Aún sin medir';

  @override
  String notEnoughBody(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días más registrados completos y Gymco podrá medir lo que gastas de verdad.',
      one: 'Un día más registrado completo y Gymco podrá medir lo que gastas de verdad.',
    );
    return '$_temp0 Hasta entonces, tus objetivos iniciales se mantienen.';
  }

  @override
  String expenditureShort(String kcal) {
    return 'Según tus registros y tu tendencia, gastas unas $kcal kcal al día.';
  }

  @override
  String expenditureFell(String intake, String kg, String kcal) {
    return 'Comiste de media $intake kcal y la tendencia bajó $kg kg. Eso solo cuadra si gastas unas $kcal.';
  }

  @override
  String expenditureRose(String intake, String kg, String kcal) {
    return 'Comiste de media $intake kcal y la tendencia subió $kg kg. Eso solo cuadra si gastas unas $kcal.';
  }

  @override
  String get nextWeekTargets => 'Objetivos de la próxima semana';

  @override
  String get noChange => 'sin cambios';

  @override
  String kcalChange(String n) {
    return '$n kcal';
  }

  @override
  String get targetsMoveNote =>
      'La proteína y la grasa se quedan; el cambio va a los carbohidratos, donde ayuda a tus sesiones. Los cambios semanales tienen un tope de 120 kcal para que una semana rara no altere tu dieta.';

  @override
  String get targetsHoldNote => 'Nada cambia hasta medir el gasto. Sigue registrando días completos y pesándote.';

  @override
  String get dietMeetsTraining => 'Dieta y entreno';

  @override
  String get strengthHolding =>
      'Tus ejercicios principales se mantienen o suben mientras pierdes peso. El músculo aguanta: este déficit se tolera bien. No hace falta cambiar nada.';

  @override
  String get strengthSlipping =>
      'Uno de tus ejercicios principales ha bajado. Vigílalo la semana que viene; si le siguen otros, frena la definición.';

  @override
  String get fasterThanPlanned => 'Esto va más rápido de lo planeado';

  @override
  String get perWeekLbl => 'por semana';

  @override
  String fastBody(String goal) {
    return 'Pediste un $goal%. A este ritmo, buena parte de lo que pierdes probablemente sea músculo.';
  }

  @override
  String get intakeLbl => 'Ingesta';

  @override
  String floorIs(String n) {
    return 'el mínimo es $n';
  }

  @override
  String get measuredShort => 'Gasto';

  @override
  String get whatToDo => '¿Qué quieres hacer?';

  @override
  String eatMore(String n) {
    return 'Comer $n más al día';
  }

  @override
  String eatMoreSub(String goal) {
    return 'Volver hacia un $goal% semanal. Recomendado.';
  }

  @override
  String get twoWeeksMaintenance => 'Dos semanas en mantenimiento';

  @override
  String get maintenanceThenResume => 'Un descanso y luego volver al ritmo planeado';

  @override
  String get keepGoingAsIAm => 'Seguir como voy';

  @override
  String get askedAgain => 'Gymco lo volverá a plantear la semana que viene';

  @override
  String floorWarnNote(String n) {
    return 'Los objetivos nunca bajan de $n kcal. Si quieres ir por debajo puedes, pero escribirás el número tú mismo tras leer este mensaje.';
  }

  @override
  String stallBody(int weeks) {
    return 'Tras $weeks semanas, la tendencia apenas se ha movido en dos. El gasto baja en una dieta larga: es normal y parte de por qué se ha parado.';
  }

  @override
  String get threeOptions => 'Tres opciones honestas';

  @override
  String maintenanceSub(String kcal) {
    return '$kcal kcal, sin déficit. Sobre todo te da un respiro de la dieta.';
  }

  @override
  String get checkLogging => 'Revisar primero el registro';

  @override
  String get checkLoggingSub => 'Los fines de semana y los picoteos suelen ser donde empiezan las semanas planas.';

  @override
  String get cut150 => 'Recortar 150 más al día';

  @override
  String get cut150Sub => 'Funciona, pero a estas alturas es la opción que más músculo cuesta.';

  @override
  String get dietBreakEvidence =>
      'Gymco no te promete reiniciar el metabolismo. Los descansos de dieta ayudaron en algunos estudios y en otros no. Lo que sí hacen es que las próximas semanas sean llevaderas.';

  @override
  String get awardsTitle => 'Premios';

  @override
  String get awardsTitleEm => 'Tus <em>premios</em>';

  @override
  String get editGoal => 'Editar meta';

  @override
  String commitmentDays(int n) {
    return 'Compromiso de $n días';
  }

  @override
  String keptOfGoal(int kept, int goal) {
    return '$kept de $goal días cumplidos';
  }

  @override
  String nextAwardIn(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n días', one: '1 día');
    return 'Próximo premio: $name en $_temp0';
  }

  @override
  String get allStreakAwards => 'Todos los premios de racha conseguidos';

  @override
  String ofDays(int n) {
    return '/ $n días';
  }

  @override
  String legendStreak(int n) {
    return 'Racha · faltan $n';
  }

  @override
  String legendFood(int n) {
    return 'Comida · $n de 3 comidas';
  }

  @override
  String get legendTrainDone => 'Entreno · hecho';

  @override
  String get legendRest => 'Entreno · día de descanso';

  @override
  String legendPlanned(String name) {
    return 'Entreno · $name planificado';
  }

  @override
  String dayKept(int n) {
    return 'Día $n cumplido. Hasta mañana.';
  }

  @override
  String logToKeep(String meal, int n) {
    return 'Registra la $meal para cumplir el día $n';
  }

  @override
  String trainToKeep(String name, int n) {
    return 'Termina $name para cumplir el día $n';
  }

  @override
  String get logBtn => 'Registrar';

  @override
  String get trainBtn => 'Entrenar';

  @override
  String goalReached(int n) {
    return '$n días. Compromiso cumplido.';
  }

  @override
  String get seeRecap => 'Ver resumen';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get restDaysCount => 'Los días de descanso cuentan';

  @override
  String get bestStreak => 'Mejor racha';

  @override
  String nDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n días', one: '1 día');
    return '$_temp0';
  }

  @override
  String get freezesLbl => 'Congelaciones';

  @override
  String freezesOf(int n, int max) {
    return '$n de $max';
  }

  @override
  String challengeDone(int n) {
    return 'Hecho: $n sesiones este mes';
  }

  @override
  String challengeLeft(int n, int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: 'quedan $days días', one: 'queda 1 día');
    return 'Entrena $n veces este mes · $_temp0';
  }

  @override
  String get shelfStreaks => 'Rachas';

  @override
  String get shelfFood => 'Comida';

  @override
  String get shelfTraining => 'Entreno';

  @override
  String gotOf(int got, int n) {
    return '$got de $n';
  }

  @override
  String get awardsNote => 'Ningún premio es por comer menos o perder peso. Lo que cuenta es registrar y aparecer.';

  @override
  String get earnedLbl => 'Conseguido';

  @override
  String earnedOn(String date) {
    return 'Conseguido el $date';
  }

  @override
  String get earnedLabel => 'conseguido';

  @override
  String get lockedLabel => 'bloqueado';

  @override
  String get restartAfterBreak => 'Volver tras una pausa';

  @override
  String nToGo(int n) {
    return 'faltan $n';
  }

  @override
  String get progressLbl => 'Progreso';

  @override
  String nextNamed(String name) {
    return 'Siguiente · $name';
  }

  @override
  String get shareAward => 'Compartir';

  @override
  String shareAwardText(String name) {
    return 'He conseguido «$name» en Gymco.';
  }

  @override
  String get backToAwards => 'Volver a premios';

  @override
  String get mdDays => 'DÍAS';

  @override
  String get mdMeals => 'COMIDAS';

  @override
  String get mdProtein => 'PROTEÍNA';

  @override
  String get mdWorkouts => 'ENTRENOS';

  @override
  String get mdBests => 'RÉCORDS';

  @override
  String get awFirstWeek => 'Primera semana';

  @override
  String get awFirstWeekD =>
      'Siete días seguidos con todas las comidas registradas y cada entreno o descanso planificado cumplido.';

  @override
  String get awTwoWeeks => 'Dos semanas';

  @override
  String get awTwoWeeksD => 'Catorce días seguidos cumplidos. La primera semana es novedad; la segunda, elección.';

  @override
  String get awOneMonth => 'Un mes firme';

  @override
  String get awOneMonthD =>
      'Treinta días seguidos con todas las comidas registradas y cada entreno o descanso planificado cumplido.';

  @override
  String get awHabit => 'Hábito formado';

  @override
  String get awHabitD => 'Sesenta y seis días, lo que de media tarda un hábito nuevo en ir solo.';

  @override
  String get awFull => 'Compromiso total';

  @override
  String get awFullD => 'Noventa días cumplidos. Tres meses apareciendo, días de descanso incluidos.';

  @override
  String get awComeback => 'La vuelta';

  @override
  String get awComebackD => 'Empieza una racha nueva tras perder una. Volver es lo que cuenta.';

  @override
  String get awFirstFullDay => 'Primer día completo';

  @override
  String get awFirstFullDayD => 'Desayuno, comida y cena registrados en un día.';

  @override
  String get awHundredMeals => '100 comidas registradas';

  @override
  String get awHundredMealsD =>
      'Cien comidas registradas. Las estimaciones cuentan: lo importante es que el día quede escrito.';

  @override
  String get awProteinWeek => 'Semana de proteína';

  @override
  String get awProteinWeekD =>
      'Tu objetivo de proteína cumplido los siete días de una semana. Es el número que protege el músculo en definición.';

  @override
  String get awFirstWorkout => 'Primer entreno';

  @override
  String get awFirstWorkoutD => 'Tu primera sesión registrada en Gymco.';

  @override
  String get awTwentyFive => '25 entrenos';

  @override
  String get awTwentyFiveD => 'Veinticinco sesiones registradas, serie a serie.';

  @override
  String get awTenBests => '10 récords personales';

  @override
  String get awTenBestsD =>
      'Diez nuevas mejores series. Mantener la fuerza en déficit es la señal de que la definición va bien.';

  @override
  String awMonth(String month) {
    return 'Reto de $month';
  }

  @override
  String awMonthD(int n) {
    return 'Entrena $n veces este mes.';
  }

  @override
  String get yourCommitment => 'Tu compromiso';

  @override
  String get howLong => '¿Para cuánto te apuntas?';

  @override
  String get howLongSub => 'Elige una racha de días. Cada día cumplido llena el anillo exterior.';

  @override
  String get daysWord => 'días';

  @override
  String get goal21 => 'Para empezar';

  @override
  String get goal30 => 'Un mes';

  @override
  String get goal66 => 'Hazlo hábito';

  @override
  String get goal90 => 'Compromiso total';

  @override
  String get customLbl => 'Personalizado';

  @override
  String get customRange => '7 – 365 días';

  @override
  String get useThis => 'Usar esto';

  @override
  String get dayCountsWhen => 'Un día cuenta cuando';

  @override
  String get ruleMeals => 'Registras las comidas';

  @override
  String get ruleMealsSub => 'Cuenta registrar, no comer menos';

  @override
  String get ruleTrain => 'Entrenas o descansas según el plan';

  @override
  String get ruleTrainSub => 'Los descansos de tu plan mantienen la racha';

  @override
  String freezeNote(int n, int max) {
    return 'Gana una congelación cada $n días cumplidos. Guarda hasta $max para enfermedad y viajes.';
  }

  @override
  String alreadyPast(int n) {
    return 'Ya pasaste los $n días: elige más';
  }

  @override
  String keepMyDays(int n) {
    return 'Mantener mis $n días';
  }

  @override
  String commitTo(int n) {
    return 'Comprometerme a $n días';
  }

  @override
  String carryOver(int n, String date) {
    return 'Tus $n días cumplidos cuentan · termina el $date';
  }

  @override
  String startsToday(String date) {
    return 'Empieza hoy · termina el $date';
  }

  @override
  String goalDoneTitle(int n) {
    return '$n días. Hecho.';
  }

  @override
  String goalDoneSub(String from, String to, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n congelaciones usadas',
      one: '1 congelación usada',
      zero: 'sin congelaciones',
    );
    return '$from – $to · $_temp0';
  }

  @override
  String get workoutsLbl => 'Entrenos';

  @override
  String get restDaysKept => 'Descansos cumplidos';

  @override
  String get mealsLoggedLbl => 'Comidas registradas';

  @override
  String get personalBests => 'Récords personales';

  @override
  String get goalDoneNote => 'Aparecer, días de descanso incluidos. Así es un hábito.';

  @override
  String shareMyDays(int n) {
    return 'Compartir mis $n días';
  }

  @override
  String shareGoalText(int n) {
    return '$n días cumplidos en Gymco: cada comida registrada, cada entreno y descanso hecho.';
  }

  @override
  String get setNextCommitment => 'Fija tu próximo compromiso';

  @override
  String get writeHint =>
      '200 g de pechuga de pollo, 150 g de arroz y 10 g de aceite de oliva\n2 huevos con dos rebanadas de pan\nun cazo de whey';

  @override
  String get writeEmpty =>
      'Escribe la comida como la dirías. Cantidades en gramos o recuentos como «dos huevos» y «un cazo», las dos valen.';

  @override
  String itRead(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ha leído $n alimentos',
      one: 'Ha leído 1 alimento',
    );
    return '$_temp0';
  }

  @override
  String nAssumed(int n) {
    return '$n estimados';
  }

  @override
  String get assumedTag => 'estimado';

  @override
  String get notInDbYet => 'Aún no está en la base de datos';

  @override
  String get searchAction => 'Buscar';

  @override
  String get assumedNote =>
      'Las filas marcadas como estimado no tenían cantidad, así que se usó una ración normal. Toca una fila para ajustarla.';

  @override
  String addN(int n) {
    return 'Añadir $n';
  }

  @override
  String pcfLine(String p, String c, String f) {
    return '$p P · $c C · $f G';
  }

  @override
  String writtenSub(String g, String kcal, String p) {
    return '$g g · $kcal kcal · $p g de proteína';
  }

  @override
  String removeNamed(String name) {
    return 'Quitar $name';
  }

  @override
  String howMuchOf(String name) {
    return '¿Cuánto $name?';
  }

  @override
  String get gramsNote => 'En gramos, tal como se comió.';

  @override
  String get voiceHold => 'Mantén pulsado y di lo que comiste. Pasa por el mismo lector que la escritura.';

  @override
  String get voiceListening => 'Escuchando… suelta cuando acabes.';

  @override
  String get voiceHeard => 'Entendido. Revisa la transcripción antes de añadirla.';

  @override
  String get transcriptLbl => 'Transcripción · edítala si oyó mal';

  @override
  String get voiceUnavailable =>
      'El dictado no está disponible en este móvil o el micrófono está desactivado para Gymco. Escríbelo.';

  @override
  String get dictateMeal => 'Dicta la comida';

  @override
  String get accountTitle => 'Cuenta';

  @override
  String get accountRowSub => 'Copia de seguridad y registro con fotos';

  @override
  String accountRowSignedIn(String email) {
    return 'Sesión iniciada · $email';
  }

  @override
  String get accountRowOff => 'Solo en el móvil';

  @override
  String get signInTitle => 'Guarda una copia en una cuenta';

  @override
  String get signInSub => 'Tu correo y un enlace de acceso, sin contraseña';

  @override
  String get emailHint => 'tu@ejemplo.com';

  @override
  String get codeHint => 'Código de 6 cifras';

  @override
  String get sendCode => 'Enviar enlace de acceso';

  @override
  String get signInAction => 'Iniciar sesión';

  @override
  String codeSentTo(String email) {
    return 'Hemos enviado un enlace de acceso a $email. Ábrelo en este móvil y Gymco iniciará tu sesión. Si el correo trae un código, escríbelo aquí.';
  }

  @override
  String get useOtherEmail => 'Usar otro correo';

  @override
  String get accountWhy =>
      'Tu diario se queda en este móvil en cualquier caso. La cuenta añade una copia que puedes recuperar en un móvil nuevo y el registro con fotos: 10 fotos al día, gratis.';

  @override
  String get cloudNotSetUp => 'Las cuentas no están activadas en esta versión. Todo lo demás funciona en el móvil.';

  @override
  String get signedInAs => 'Sesión iniciada';

  @override
  String get backupTitle => 'Copia de seguridad';

  @override
  String backedUpAt(String when) {
    return 'Copia hecha $when';
  }

  @override
  String get notBackedUp => 'Aún sin copia';

  @override
  String get backupAuto => 'Se copia sola al salir de la app, como mucho cada seis horas.';

  @override
  String get backupNow => 'Copiar ahora';

  @override
  String get backupDone => 'Copia hecha';

  @override
  String get restoreAction => 'Restaurar la copia';

  @override
  String get restoreTitle => '¿Restaurar esta copia?';

  @override
  String restoreBody(String when) {
    return 'La copia del $when sustituye lo que hay ahora en este móvil.';
  }

  @override
  String get foundBackupTitle => 'Tu cuenta tiene una copia';

  @override
  String foundBackupBody(String when) {
    return 'Del $when. Restáurala en este móvil o quédate con lo que tiene y cópialo en su lugar.';
  }

  @override
  String get restoreIt => 'Restaurarla';

  @override
  String get keepThisPhone => 'Quedarme con lo de este móvil';

  @override
  String get restored => 'Restaurado';

  @override
  String get noBackupYet => 'Aún no hay copia en esta cuenta';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutNote => 'Cerrar sesión deja todo en este móvil.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountSub => 'La cuenta y su copia';

  @override
  String get deleteAccountBody =>
      'La cuenta y su copia se eliminan ahora. Lo que hay en este móvil se queda; bórralo en Tus datos.';

  @override
  String get deleteAccountConfirm => 'Eliminar cuenta y copia';

  @override
  String get accountDeleted => 'Cuenta eliminada';

  @override
  String get errOffline => 'Sin conexión. Inténtalo cuando tengas internet.';

  @override
  String get errBadCode => 'Ese código no ha funcionado. Revísalo o pide otro.';

  @override
  String get errBusy => 'Demasiados intentos. Espera un minuto y vuelve a probar.';

  @override
  String get errGeneric => 'Algo ha fallado. Inténtalo de nuevo.';

  @override
  String get photoPrompt => 'Fotografía el plato. Gymco sugiere lo que ve; tú dices cuánto.';

  @override
  String get takePhoto => 'Hacer una foto';

  @override
  String get choosePhoto => 'Elegir de la galería';

  @override
  String get readingPlate => 'Mirando el plato…';

  @override
  String plateThings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cosas en el plato',
      one: 'Una cosa en el plato',
      zero: 'Nada reconocible en el plato',
    );
    return '$_temp0';
  }

  @override
  String get tapToConfirm => 'toca para confirmar';

  @override
  String get fairlyConfident => 'bastante seguro';

  @override
  String get notSureCheck => 'no estoy seguro: revisa este';

  @override
  String get photoAmountNote =>
      'Las cantidades se estiman con la foto y tu descripción, y los alimentos que no están en la base de datos usan cifras de IA. Toca cualquiera para revisarlo antes de añadirlo.';

  @override
  String get photoNeedsAccount =>
      'El registro con fotos usa una cuenta: la foto se lee en nuestro servidor, 10 al día, gratis. Escribir y buscar funcionan sin ella.';

  @override
  String get photoNotSetUp => 'El registro con fotos no está activado en esta versión. Escribe o busca.';

  @override
  String scansLeft(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Te quedan $n fotos hoy',
      one: 'Te queda 1 foto hoy',
      zero: 'No te quedan fotos hoy',
    );
    return '$_temp0';
  }

  @override
  String get photoCap => 'Ya has usado las 10 fotos de hoy. Vuelven mañana; mientras, escribe o busca.';

  @override
  String get photoRefused => 'No se ha podido leer esa foto. Prueba con otra.';

  @override
  String get photoAgain => 'Hacer otra';

  @override
  String get notInDbSearch => 'No está en el móvil: búscalo';

  @override
  String get badgeTurnHint => 'Arrastra o toca para darle la vuelta';

  @override
  String badgeBackLabel(String name, String date) {
    return 'Reverso de la insignia: $name, conseguida el $date';
  }

  @override
  String get photoNoteHint => 'Añade detalles (opcional): cuántos, qué lleva. «4 minipizzas con carne y cheddar»';

  @override
  String get dictateNote => 'Di los detalles';

  @override
  String get estimateFromNote => 'Estimar con la descripción';

  @override
  String aboutGramsKcal(String g, String kcal) {
    return '≈ $g g · $kcal kcal';
  }

  @override
  String get aiEstimateShort => 'estimación de IA';

  @override
  String get aiEstimateLabel => 'Estimado por IA · revisa las cifras';

  @override
  String addAllKcal(int n, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Añadir los $n · $kcal kcal',
      one: 'Añadirlo · $kcal kcal',
    );
    return '$_temp0';
  }

  @override
  String get estimateAction => 'Estimar';

  @override
  String showPhotosOf(String name) {
    return 'Ver fotos de $name';
  }

  @override
  String get closePhotos => 'Cerrar';

  @override
  String get proTitle => 'Gymco <em>Pro</em>';

  @override
  String get proBadge => 'PRO';

  @override
  String get proFreeTesting => 'Gratis durante las pruebas';

  @override
  String get proSub => 'Un coaching que se adapta a ti cada semana.';

  @override
  String get proPoint1 => 'Objetivos adaptativos + revisión semanal';

  @override
  String get proPoint2 => 'Fuerza frente a tu déficit';

  @override
  String get proPoint3 => 'Volumen por músculo, historial completo';

  @override
  String get proCta => 'Pro está activo';

  @override
  String get proCtaSub => 'todas las funciones Pro están abiertas para quienes prueban';

  @override
  String get proCardLabel => 'Gymco Pro, gratis durante las pruebas';

  @override
  String get freeVsPro => 'Gratis vs Pro';

  @override
  String get proHeadline => 'Paga por el coaching, no por lo básico';

  @override
  String get proHeadlineSub =>
      'El escáner de códigos, los alimentos propios y las rutinas ilimitadas siguen gratis. Para siempre, no como prueba.';

  @override
  String get freeForever => 'Gratis para siempre';

  @override
  String get freeBarcode => 'Escáner de códigos';

  @override
  String get freeCustomFoods => 'Alimentos propios';

  @override
  String get freeRecipes => 'Recetas';

  @override
  String get freeCopyDay => 'Copiar día';

  @override
  String get freeRoutines => 'Rutinas ilimitadas';

  @override
  String get freeCustomExercises => 'Ejercicios propios';

  @override
  String get freeRestTimer => 'Temporizador de descanso';

  @override
  String get freeTrendWeight => 'Tendencia de peso';

  @override
  String get freeExport => 'Exportación completa';

  @override
  String get proAdds => 'Pro añade';

  @override
  String get proAdds1Lead => 'Gasto adaptativo';

  @override
  String get proAdds1 => 'y la revisión semanal';

  @override
  String get proAdds2Lead => 'Fuerza frente al déficit';

  @override
  String get proAdds2 => '— lo que ninguna otra app te muestra';

  @override
  String get proAdds3 => 'Tipos de día, ciclado de calorías, descansos de dieta';

  @override
  String get proAdds4 => 'Volumen por músculo, historial completo, comparar fotos';

  @override
  String get planMonthly => 'Mensual';

  @override
  String get planYearly => 'Anual';

  @override
  String get planYearlySub => '3,33 € al mes';

  @override
  String get planLifetime => 'De por vida';

  @override
  String get proTestingNote =>
      'Gymco está en pruebas: aún no se vende nada y todas las funciones Pro están activas. Estos son los precios previstos para el lanzamiento.';

  @override
  String get proOnAction => 'Entendido — Pro está activo';

  @override
  String get proKeepNote =>
      'Si Pro termina, conservas todas las funciones de la lista gratuita, y tus datos siguen siendo tuyos.';

  @override
  String confirmLogTitle(String meal) {
    return '¿Añadir a $meal?';
  }

  @override
  String get confirmLogAction => 'Confirmar y añadir';

  @override
  String awardsButton(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Logros, $n conseguidos',
      one: 'Logros, 1 conseguido',
      zero: 'Logros',
    );
    return '$_temp0';
  }

  @override
  String get welcomeLogTitleEm => 'Registra la comida <em>a tu manera</em>';

  @override
  String get welcomeLogBody =>
      'Escríbela, dila, hazle una foto o escanea el código. Gymco lee la comida y tú confirmas antes de añadirla.';

  @override
  String get welcomeLogAlt => 'Un hombre registrando una comida en su móvil';

  @override
  String get welcomeTrainTitleEm => 'Entrena con <em>un plan</em>';

  @override
  String get welcomeTrainBody =>
      'Rutinas para tu semana, más de 870 ejercicios con fotos, temporizador de descanso y tus números anteriores en cada serie.';

  @override
  String get welcomeTrainAlt => 'Una mujer levantando mancuernas sobre la cabeza';

  @override
  String get welcomeProgressTitleEm => 'Mira cómo <em>suma</em>';

  @override
  String get welcomeProgressBody =>
      'Un peso de tendencia que ignora el ruido diario, fuerza durante tu definición y logros por aparecer.';

  @override
  String get welcomeProgressAlt => 'Un atleta celebrando entre medallas';

  @override
  String get hydration => 'Hidratación';

  @override
  String ofLitres(String l) {
    return 'de $l L';
  }

  @override
  String get goalMet => 'Meta cumplida';

  @override
  String get waterGlass => 'vaso';

  @override
  String get waterBottle => 'botella';

  @override
  String get waterLarge => 'grande';

  @override
  String get undoLastDrink => 'Deshacer la última bebida';

  @override
  String addWaterMl(int ml) {
    return 'Añadir $ml ml de agua';
  }

  @override
  String waterAddedMl(int ml) {
    return '$ml ml añadidos';
  }

  @override
  String get waterGoalReached => 'Meta de agua alcanzada — bien hecho';

  @override
  String get waterTrainingBonus => 'Incluye +0,5 L por el entrenamiento de hoy';

  @override
  String get waterToday => 'Agua hoy';

  @override
  String get noWaterYet => 'Aún no has registrado nada hoy.';

  @override
  String mlAmount(String ml) {
    return '$ml ml';
  }

  @override
  String get removeDrink => 'Quitar esta bebida';

  @override
  String get otherAmount => 'Otra cantidad';

  @override
  String get dailyGoal => 'Meta diaria';

  @override
  String get waterGoalAuto => 'Según tu peso, +0,5 L los días de entreno';

  @override
  String get waterGoalSet => 'Fijada por ti';

  @override
  String useAutoGoal(String l) {
    return 'Usar la meta según mi peso ($l L)';
  }

  @override
  String get remindBreakfastTitle => '¿Has registrado el desayuno?';

  @override
  String get remindLunchTitle => '¿Has registrado la comida?';

  @override
  String get remindDinnerTitle => '¿Has registrado la cena?';

  @override
  String get remindMealBody => 'Escríbela, dila o hazle una foto: son unos segundos.';

  @override
  String get remindWaterTitle => 'Hora de beber agua';

  @override
  String remindWaterBody(String l) {
    return 'Un vaso ahora te mantiene en ritmo para $l L hoy.';
  }

  @override
  String remindWorkoutTitle(String routine) {
    return '$routine hoy';
  }

  @override
  String get remindWorkoutBody => 'Tu plan tiene sesión hoy. Cuando quieras.';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get remindMeals => 'Comidas';

  @override
  String remindMealsSub(String b, String l, String d) {
    return 'Si una comida no está registrada a las $b, $l o $d';
  }

  @override
  String get remindWater => 'Agua';

  @override
  String remindWaterSub(String a, String b, String c) {
    return 'A las $a, $b y $c si vas por detrás';
  }

  @override
  String get remindWorkout => 'Entrenos';

  @override
  String remindWorkoutSub(String t) {
    return 'A las $t los días con sesión en tu plan';
  }

  @override
  String get remindersOff => 'Las notificaciones de Gymco están desactivadas. Actívalas en los ajustes del móvil.';

  @override
  String get newRecipe => 'Nueva receta';

  @override
  String get editRecipe => 'Editar receta';

  @override
  String get deleteRecipe => 'Eliminar receta';

  @override
  String get saveRecipe => 'Guardar';

  @override
  String recipeSaved(String name) {
    return '$name guardada';
  }

  @override
  String get recipeNameHint => 'Ponle nombre — «Curry de pollo»';

  @override
  String get servingsLabel => 'Raciones';

  @override
  String ingredientsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ingredientes',
      one: '1 ingrediente',
      zero: 'Ingredientes',
    );
    return '$_temp0';
  }

  @override
  String get recipeIngredientsHint =>
      'Escribe lo que lleva: «500g pechuga de pollo, 300g arroz, 2 cucharadas de aceite»';

  @override
  String get addIngredients => 'Añadir ingredientes';

  @override
  String recipeMissed(String items) {
    return 'Aún no está en la base de datos, así que se omitió: $items. Añádelo como alimento propio para incluirlo.';
  }

  @override
  String get perServing => 'Por ración';

  @override
  String kcalPerServing(String kcal) {
    return '$kcal kcal por ración';
  }

  @override
  String servingsOf(int n, String g) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n raciones de $g g', one: '1 ración de $g g');
    return '$_temp0';
  }

  @override
  String recipeSub(int n, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n raciones', one: '1 ración');
    return '$_temp0 · $kcal kcal por ración';
  }

  @override
  String get noRecipes =>
      'Aún no hay recetas. Crea una con lo que cocinas a menudo y registra una ración con un toque.';

  @override
  String get yourRecipe => 'Tu receta';

  @override
  String get healthData => 'Datos de salud';

  @override
  String get healthDataSub => 'Qué lee y escribe Gymco';

  @override
  String get healthOn => 'Conectado';

  @override
  String get healthOff => 'No conectado';

  @override
  String get appleHealth => 'Salud de Apple';

  @override
  String get healthConnect => 'Health Connect';

  @override
  String connectStore(String store) {
    return 'Conectar $store';
  }

  @override
  String get healthHeadline => 'Qué lee Gymco y qué escribe';

  @override
  String get healthBody =>
      'Entran tu báscula y tus pasos; salen tus entrenos, agua y pesajes. Eliges cada uno en la pantalla de permisos del móvil.';

  @override
  String get healthConnectMissing => 'Health Connect no está en este móvil. Instálalo desde Google Play para conectar.';

  @override
  String get installHealthConnect => 'Instalar Health Connect';

  @override
  String get healthRefused => 'No se compartió nada. Puedes permitirlo en los ajustes de salud del móvil.';

  @override
  String get readsFromHealth => 'Lee';

  @override
  String get writesToHealth => 'Escribe';

  @override
  String get healthWeight => 'Peso corporal';

  @override
  String get healthWeightSub => 'Los pesajes de tu báscula alimentan la tendencia';

  @override
  String get healthSteps => 'Pasos';

  @override
  String get healthStepsSub => 'Se muestran en Hoy';

  @override
  String get healthWorkouts => 'Entrenos';

  @override
  String get healthWorkoutsSub => 'Cada sesión terminada, como fuerza';

  @override
  String get healthWater => 'Agua';

  @override
  String get healthWaterSub => 'Cada bebida que registras';

  @override
  String get healthWeighIns => 'Pesajes';

  @override
  String get healthWeighInsSub => 'Los que escribes en Gymco';

  @override
  String get healthNote =>
      'Desactivarlo detiene nuevas lecturas y escrituras. Lo ya compartido sigue en tu app de salud hasta que lo borres allí.';

  @override
  String get mEatOut => 'Fuera';

  @override
  String get eatOutTitleEm => 'Comer <em>fuera</em>';

  @override
  String get eatOutSub => 'Sin etiqueta, sin problema. Una estimación honesta es mejor que un día en blanco.';

  @override
  String get eoWhat => 'Qué tomaste';

  @override
  String get eoPortion => 'Ración';

  @override
  String get eoSides => 'Acompañamientos';

  @override
  String get eoEstimate => 'Estimación';

  @override
  String get eoRange => 'margen';

  @override
  String get eoNote => 'Se marca como estimación y sigue contando para tu racha.';

  @override
  String eoLogTo(String meal) {
    return 'Registrar en $meal';
  }

  @override
  String get eoBurger => 'Hamburguesa';

  @override
  String get eoPizza => 'Pizza';

  @override
  String get eoPasta => 'Pasta';

  @override
  String get eoShawarma => 'Shawarma';

  @override
  String get eoSushi => 'Sushi';

  @override
  String get eoCurry => 'Curry';

  @override
  String get eoSalad => 'Ensalada';

  @override
  String get eoGrill => 'Parrillada';

  @override
  String get eoSmall => 'Pequeña';

  @override
  String get eoNormal => 'Normal';

  @override
  String get eoBig => 'Grande';

  @override
  String get eoHuge => 'Enorme';

  @override
  String get eoFries => 'Patatas fritas';

  @override
  String get eoGarlic => 'Salsa de ajo';

  @override
  String get eoBread => 'Pan';

  @override
  String get eoSoda => 'Refresco';

  @override
  String get catchupTitle => 'Ponerte al día';

  @override
  String get catchupHeadEm => 'Rellena los <em>huecos</em>';

  @override
  String catchupSub(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días no tienen registros.',
      one: 'Un día no tiene registros.',
    );
    return '$_temp0 Rellénalos a grandes rasgos o déjalos fuera, sin culpa.';
  }

  @override
  String catchupTrained(String name) {
    return 'Entrenaste · $name';
  }

  @override
  String catchupPlanned(String name) {
    return 'Planificado · $name';
  }

  @override
  String get catchupRest => 'Descanso planificado';

  @override
  String get catchupUsual => 'Día habitual';

  @override
  String get catchupRough => 'Total aproximado';

  @override
  String get catchupLeave => 'Dejar fuera';

  @override
  String get catchupRoughLabel => 'Más o menos';

  @override
  String catchupUsualNote(String kcal, String protein) {
    return 'Se rellena con tu media de 7 días: ≈ $kcal kcal, $protein g de proteína.';
  }

  @override
  String get catchupRoughNote => 'La proteína sigue tu proporción habitual del día.';

  @override
  String get catchupLeaveNote => 'Queda fuera de tu media de gasto. El día sigue abierto para tu racha.';

  @override
  String get catchupFooter => 'Los días rellenados se marcan como estimaciones.';

  @override
  String catchupSave(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: 'Guardar $n días', one: 'Guardar 1 día');
    return '$_temp0';
  }

  @override
  String catchupSaved(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n días al día', one: 'Día al día');
    return '$_temp0';
  }

  @override
  String get catchupNone => 'Todo al día.';

  @override
  String catchupCard(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n días sin registrar comida',
      one: '1 día sin registrar comida',
    );
    return '$_temp0';
  }

  @override
  String get catchupCardSub => 'Ponte al día en unos toques';

  @override
  String get swapExercise => 'Cambiar ejercicio';

  @override
  String get swapExerciseSub => 'Máquina ocupada, o no se siente bien';

  @override
  String swapTitle(String name) {
    return 'Cambiar $name';
  }

  @override
  String get swapSub => 'Mismos músculos, otro movimiento. Las series que ya hiciste se quedan donde están.';

  @override
  String get swapNone => 'No hay una alternativa cercana en la biblioteca.';

  @override
  String swapped(String name) {
    return 'Cambiado a $name';
  }

  @override
  String get flagPain => 'Marcar dolor';

  @override
  String get flagPainSub => 'Algo dolió en esta serie';

  @override
  String get clearPain => 'Quitar marca de dolor';

  @override
  String get painWhere => '¿Dónde duele?';

  @override
  String get painNote => 'El ardor muscular es normal. El dolor en una articulación, o un dolor agudo, no.';

  @override
  String get painShoulder => 'Hombro';

  @override
  String get painElbow => 'Codo';

  @override
  String get painWrist => 'Muñeca';

  @override
  String get painBack => 'Lumbar';

  @override
  String get painHip => 'Cadera';

  @override
  String get painKnee => 'Rodilla';

  @override
  String get painOther => 'Otro sitio';

  @override
  String painOnSet(String area, String set) {
    return '$area · serie $set';
  }

  @override
  String get painAcheLighter => 'Molestia: baja un 10%';

  @override
  String get painAcheLighterSub => 'Las series restantes bajan un 10%. Para si empeora.';

  @override
  String get painAcheKeep => 'Molestia: sigue';

  @override
  String get painAcheKeepSub => 'Queda marcado para vigilarlo la próxima vez.';

  @override
  String get painSharpStop => 'Agudo: para este ejercicio';

  @override
  String get painSharpStopSub => 'El dolor agudo es una señal de parar. Las series restantes se quitan.';

  @override
  String get painSharpSwap => 'Agudo: cámbialo';

  @override
  String get painSharpSwapSub => 'Prueba un movimiento que no lo cargue.';

  @override
  String get painLightened => 'Las series restantes pesan un 10% menos';

  @override
  String get painFlagged => 'Dolor marcado';

  @override
  String get painStopped => 'Paras aquí. Descansa y consulta a alguien si continúa.';

  @override
  String painFlaggedOn(String area) {
    return 'Dolor marcado: $area';
  }

  @override
  String painLastAche(String area, String date) {
    return 'La última vez ($date) notaste molestia aquí ($area). Empieza más ligero.';
  }

  @override
  String painLastSharp(String area, String date) {
    return 'La última vez ($date) tuviste dolor agudo aquí ($area). Cámbialo si vuelve.';
  }

  @override
  String get heroTagLeftOpen => 'Sin cerrar';

  @override
  String heroLeftOpenEm(String name) {
    return '$name quedó <em>abierto</em>';
  }

  @override
  String heroLeftOpenBody(int n, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n series hechas',
      one: '1 serie hecha',
      zero: 'Nada marcado aún',
    );
    return '$_temp0, último cambio $time. Guarda lo que hiciste o retómalo.';
  }

  @override
  String yesterdayAt(String time) {
    return 'ayer $time';
  }

  @override
  String get saveAsDone => 'Guardar como hecho';

  @override
  String get heroTagSkipped => 'Saltado';

  @override
  String get heroRestChosenTitle => 'Descanso <em>hoy</em>';

  @override
  String heroRestChosenBody(String name) {
    return '$name pasa a mañana. Descansar es parte del plan, no salirse de él.';
  }

  @override
  String get heroSkippedTitle => 'Saltado <em>hoy</em>';

  @override
  String heroSkippedBody(String name) {
    return '$name queda fuera esta semana. El resto sigue como estaba.';
  }

  @override
  String get trainAnyway => 'Entrenar igualmente';

  @override
  String get trainAnywaySub => 'Elige una rutina, o empieza vacío y añade sobre la marcha.';

  @override
  String get undoChange => 'Deshacer';

  @override
  String get notToday => 'Hoy no';

  @override
  String get notTodayTitle => '¿Hoy no?';

  @override
  String get restTodayLabel => 'Descansa hoy, entrena mañana';

  @override
  String restTodaySub(String name) {
    return '$name y el resto de la semana se mueven un día.';
  }

  @override
  String get skipTodayLabel => 'Sáltalo esta semana';

  @override
  String skipTodaySub(String name) {
    return '$name se quita; los demás días se quedan donde están.';
  }

  @override
  String get notTodayNote => 'En ambos casos tu racha está a salvo: un descanso planificado nunca la rompe.';

  @override
  String routineSize(int n, int sets) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n ejercicios', one: '1 ejercicio');
    return '$_temp0 · $sets series';
  }

  @override
  String get photosTab => 'Fotos';

  @override
  String get poseFront => 'Frente';

  @override
  String get poseSide => 'Perfil';

  @override
  String get poseBack => 'Espalda';

  @override
  String photoOf(String pose) {
    return 'Foto de $pose';
  }

  @override
  String addPhotoOf(String pose) {
    return 'Añadir foto de $pose';
  }

  @override
  String get chooseFromLibrary => 'Elegir de la galería';

  @override
  String get photoTip => 'Mismo sitio, misma luz, misma hora: por la mañana, antes de comer, es lo mejor.';

  @override
  String get deletePhoto => 'Borrar foto';

  @override
  String get todaysPhotos => 'Fotos de hoy';

  @override
  String get onThisPhone => 'Solo en este móvil';

  @override
  String get photosNote => 'Las fotos no salen de tu móvil: sin subidas ni copias. Cada dos a cuatro semanas basta.';

  @override
  String get compareLbl => 'Comparar';

  @override
  String latestOn(String date) {
    return 'Última · $date';
  }

  @override
  String get compareFrom => 'Comparar desde';

  @override
  String get compareNeedsTwo => 'Haz la misma pose otro día para comparar.';

  @override
  String get strengthInsightLbl => 'Últimas 8 semanas';

  @override
  String get strengthHeldEm => 'Fuerza <em>mantenida</em>';

  @override
  String get strengthUpEm => 'Fuerza <em>en subida</em>';

  @override
  String strengthHeldBody(int held, int n) {
    return '$held de $n ejercicios mantuvieron su fuerza durante la definición. Mantener fuerza en déficit significa que conservas músculo.';
  }

  @override
  String strengthUpBody(int up, int n) {
    return '$up de $n ejercicios están más fuertes que hace 8 semanas.';
  }

  @override
  String get pauseStreak => 'Pausar la racha';

  @override
  String get pauseHint => 'Enfermo o fuera';

  @override
  String pausedUntil(String date) {
    return 'En pausa hasta el $date';
  }

  @override
  String get pauseSub =>
      'Enfermedad, viajes, la vida. Los días en pausa no cuentan ni rompen la racha, y tus congelaciones se quedan.';

  @override
  String get endPause => 'Terminar pausa';

  @override
  String streakPaused(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Racha en pausa $n días',
      one: 'Racha en pausa 1 día',
    );
    return '$_temp0';
  }

  @override
  String aiCanEstimate(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n alimentos no están en el móvil. La IA puede estimarlos.',
      one: '1 alimento no está en el móvil. La IA puede estimarlo.',
    );
    return '$_temp0';
  }

  @override
  String askAiN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Preguntar a la IA por $n alimentos',
      one: 'Preguntar a la IA',
    );
    return '$_temp0';
  }

  @override
  String get aiThinking => 'Estimando…';

  @override
  String get aiNeedsAccount => 'Inicia sesión para usar la IA: es gratis durante las pruebas.';

  @override
  String aiCouldNot(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'La IA no reconoció $n alimentos. Prueba otras palabras o busca.',
      one: 'La IA no reconoció 1 alimento. Prueba otras palabras o busca.',
    );
    return '$_temp0';
  }

  @override
  String get eoOther => 'Otra cosa';

  @override
  String get eoOtherHint => 'Descríbelo, p. ej. biryani de pollo con raita';

  @override
  String get eoAskAi => 'Pedir a la IA que lo estime';

  @override
  String get eoRoughGuess => '¿Sin IA? Calcula el total';

  @override
  String eoAiNote(String meal) {
    return 'Comida de restaurante, ración normal: $meal';
  }

  @override
  String get reminderOn => 'Activado';

  @override
  String get reminderOff => 'Desactivado';

  @override
  String waterNudgeN(int n) {
    return 'Aviso $n';
  }

  @override
  String get remindWorkoutAt => 'Hora';

  @override
  String get remindMealsNote => 'Cada aviso solo suena si esa comida sigue vacía.';

  @override
  String get remindWaterNote => 'Cada aviso solo suena si vas por detrás con el agua a esa hora.';

  @override
  String get remindWorkoutNote => 'Solo los días con sesión en tu plan, y no si ya la hiciste.';

  @override
  String toggleReminder(String name) {
    return 'Activar o desactivar avisos de $name';
  }
}
