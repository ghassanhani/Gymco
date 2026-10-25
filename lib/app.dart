import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/models.dart';
import 'l10n/app_localizations.dart';
import 'state/cloud_providers.dart';
import 'state/providers.dart';
import 'state/health_providers.dart';
import 'state/reminder_providers.dart';
import 'theme/volt.dart';
import 'ui/common/app_gate.dart';
import 'ui/common/celebrations.dart';
import 'ui/common/splash.dart';
import 'ui/common/copy.dart';
import 'ui/food/add_food_screen.dart';
import 'ui/food/meal_screen.dart';
import 'ui/food/scan_screen.dart';
import 'ui/food/recipe_screen.dart';
import 'ui/today/catchup_screen.dart';
import 'ui/food/serving_screen.dart';
import 'ui/me/health_screen.dart';
import 'ui/me/help_screen.dart';
import 'ui/me/pro_screen.dart';
import 'ui/me/account_screen.dart';
import 'ui/me/data_screen.dart';
import 'ui/me/me_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/progress/awards_screen.dart';
import 'ui/progress/checkin_screen.dart';
import 'ui/progress/progress_screen.dart';
import 'ui/shell.dart';
import 'ui/today/today_screen.dart';
import 'data/training.dart';
import 'state/training_providers.dart';
import 'ui/train/ai_routine_screen.dart';
import 'ui/train/builder_screen.dart';
import 'ui/train/exercise_picker_screen.dart';
import 'ui/train/exercise_screen.dart';
import 'ui/train/library_screen.dart';
import 'ui/train/routine_screen.dart';
import 'ui/train/summary_screen.dart';
import 'ui/train/train_screen.dart';
import 'ui/train/workout_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final hasProfile = ValueNotifier(ref.read(profileProvider) != null);
  ref.listen(profileProvider, (_, p) => hasProfile.value = p != null);
  ref.onDispose(hasProfile.dispose);

  return GoRouter(
    initialLocation: '/today',
    observers: [_CloseKeyboard()],
    refreshListenable: hasProfile,
    redirect: (_, state) {
      final loc = state.matchedLocation;
      if (!hasProfile.value) return loc == '/onboarding' ? null : '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/scan', builder: (_, _) => const ScanScreen()),
      GoRoute(path: '/workout', builder: (_, _) => const WorkoutScreen()),
      GoRoute(path: '/exercises/pick', builder: (_, _) => const ExercisePickerScreen()),
      GoRoute(path: '/exercises/browse', builder: (_, _) => const ExercisePickerScreen(browse: true)),
      GoRoute(
        path: '/exercise/:id',
        builder: (_, s) => ExerciseScreen(exerciseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/summary',
        redirect: (_, s) => s.extra is FinishedWorkout ? null : '/train',
        builder: (_, s) => SummaryScreen(done: s.extra! as FinishedWorkout),
      ),
      GoRoute(path: '/routine/ai', builder: (_, _) => const AiRoutineScreen()),
      GoRoute(
        path: '/routine/new',
        builder: (_, s) => BuilderScreen(seed: s.extra is Routine ? s.extra! as Routine : null),
      ),
      GoRoute(
        path: '/routine/:id/view',
        builder: (_, s) => RoutineScreen(routineId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/routine/:id',
        builder: (_, s) => BuilderScreen(routineId: int.tryParse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/add/:meal',
        builder: (_, s) => AddFoodScreen(
          meal: Meal.values.byName(s.pathParameters['meal']!),
          mode: s.uri.queryParameters['mode'] ?? 'search',
        ),
      ),
      GoRoute(
        path: '/serving/:food',
        builder: (_, s) => ServingScreen(
          foodId: s.pathParameters['food']!,
          meal: Meal.values.byName(s.uri.queryParameters['meal'] ?? Meal.lunch.name),
          entryId: int.tryParse(s.uri.queryParameters['entry'] ?? ''),
          grams: double.tryParse(s.uri.queryParameters['grams'] ?? ''),
          returnAfterAdd: s.uri.queryParameters['back'] == '1',
          confirm: s.uri.queryParameters['confirm'] == '1',
        ),
      ),
      GoRoute(
        path: '/barcode-miss/:code',
        builder: (_, s) => BarcodeMissScreen(code: s.pathParameters['code']!),
      ),
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/checkin', builder: (_, _) => const CheckInScreen()),
      GoRoute(path: '/goal', builder: (_, _) => const GoalSetScreen()),
      GoRoute(path: '/goal/done', builder: (_, _) => const GoalDoneScreen()),
      GoRoute(path: '/data', builder: (_, _) => const DataScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/pro', builder: (_, _) => const ProScreen()),
      GoRoute(path: '/health', builder: (_, _) => const HealthScreen()),
      GoRoute(path: '/help', builder: (_, _) => const HelpScreen()),
      GoRoute(path: '/catchup', builder: (_, _) => const CatchupScreen()),
      GoRoute(path: '/recipe/new', builder: (_, _) => const RecipeScreen()),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, s) => RecipeScreen(recipeId: int.tryParse(s.pathParameters['id']!)),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
              // Under the tabs, as the canvas draws it.
              GoRoute(
                path: '/meal/:meal',
                builder: (_, s) => MealScreen(meal: Meal.values.byName(s.pathParameters['meal']!)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/food',
                builder: (_, _) => AddFoodScreen(meal: mealForHour(ref.read(clockProvider)().hour), asTab: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/train',
                builder: (_, _) => const TrainScreen(),
                routes: [GoRoute(path: 'routines', builder: (_, _) => const LibraryScreen())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (_, _) => const ProgressScreen(),
                routes: [
                  GoRoute(path: 'awards', builder: (_, _) => const AwardsScreen()),
                  GoRoute(
                    path: 'award/:id',
                    builder: (_, s) => AwardDetailScreen(id: s.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/me', builder: (_, _) => const MeScreen())],
          ),
        ],
      ),
    ],
  );
});

class GymcoApp extends ConsumerStatefulWidget {
  const GymcoApp({super.key});

  @override
  ConsumerState<GymcoApp> createState() => _GymcoAppState();
}

class _GymcoAppState extends ConsumerState<GymcoApp> with WidgetsBindingObserver {
  // Leaving the app is the moment to back up: nothing is being typed.
  // Coming back is the moment to bring reminders up to date with the day.
  late final _lifecycle = AppLifecycleListener(
    onPause: () => ref.read(cloudActionsProvider).backupIfDue(),
    onResume: () {
      ref.invalidate(reminderSyncProvider);
      refreshHealth(ref);
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    super.dispose();
  }

  // "System" appearance follows the phone switching between light and dark.
  @override
  void didChangePlatformBrightness() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsProvider.select((s) => s.locale));
    final appearance = ref.watch(settingsProvider.select((s) => s.appearance));
    final brightness = switch (appearance) {
      Appearance.light => Brightness.light,
      Appearance.dark => Brightness.dark,
      Appearance.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };
    // Every colour reads the palette while building, and plenty of widgets
    // are const, so a change of palette rebuilds the whole app from here.
    Volt.use(brightness);
    ref.watch(reminderSyncProvider);
    ref.watch(healthImportProvider);
    return MaterialApp.router(
      key: ValueKey(brightness),
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
      // A tap outside any field closes the keyboard: the iPhone number pad has
      // no key of its own for that.
      builder: (ctx, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: MediaQuery(
          // All text a touch larger than the design's sizes, on top of the
          // phone's own text-size setting.
          data: MediaQuery.of(ctx).copyWith(textScaler: BoostedTextScaler(MediaQuery.textScalerOf(ctx))),
          child: PacksScope(
            child: Theme(
              data: Volt.theme(Localizations.localeOf(ctx)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppGateView(child: child!),
                  const CelebrationHost(),
                  const SplashCover(),
                ],
              ),
            ),
          ),
        ),
      ),
      theme: Volt.theme(locale ?? const Locale('en')),
    );
  }
}

/// The phone's text scale times [boost]. Wraps rather than replaces the
/// phone's scaler, so non-linear system scaling (Android 14) still applies.
class BoostedTextScaler extends TextScaler {
  const BoostedTextScaler(this.base, {this.boost = 1.08});
  final TextScaler base;
  final double boost;

  @override
  double scale(double fontSize) => base.scale(fontSize * boost);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * boost;

  @override
  bool operator ==(Object other) => other is BoostedTextScaler && other.base == base && other.boost == boost;

  @override
  int get hashCode => Object.hash(base, boost);
}

/// Closes the keyboard whenever a screen opens or closes, so a field left
/// focused on one screen can't hold the keyboard over the next.
class _CloseKeyboard extends NavigatorObserver {
  void _close() => FocusManager.instance.primaryFocus?.unfocus();
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _close();
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _close();
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _close();
}
