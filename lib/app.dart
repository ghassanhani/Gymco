import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/models.dart';
import 'l10n/app_localizations.dart';
import 'state/cloud_providers.dart';
import 'state/providers.dart';
import 'state/reminder_providers.dart';
import 'theme/volt.dart';
import 'ui/food/add_food_screen.dart';
import 'ui/food/meal_screen.dart';
import 'ui/food/scan_screen.dart';
import 'ui/food/recipe_screen.dart';
import 'ui/food/serving_screen.dart';
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
      GoRoute(
        path: '/routine/new',
        builder: (_, s) => BuilderScreen(
          folder: s.uri.queryParameters['folder'] == 'mine' ? RoutineFolder.mine : RoutineFolder.plan,
          seed: s.extra is Routine ? s.extra! as Routine : null,
        ),
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

class _GymcoAppState extends ConsumerState<GymcoApp> {
  // Leaving the app is the moment to back up: nothing is being typed.
  // Coming back is the moment to bring reminders up to date with the day.
  late final _lifecycle = AppLifecycleListener(
    onPause: () => ref.read(cloudActionsProvider).backupIfDue(),
    onResume: () => ref.invalidate(reminderSyncProvider),
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(settingsProvider.select((s) => s.locale));
    ref.watch(reminderSyncProvider);
    return MaterialApp.router(
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
      builder: (ctx, child) => Theme(data: Volt.theme(Localizations.localeOf(ctx)), child: child!),
      theme: Volt.theme(locale ?? const Locale('en')),
    );
  }
}
