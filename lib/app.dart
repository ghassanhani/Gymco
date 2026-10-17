import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/models.dart';
import 'l10n/app_localizations.dart';
import 'state/providers.dart';
import 'theme/volt.dart';
import 'ui/food/add_food_screen.dart';
import 'ui/food/meal_screen.dart';
import 'ui/food/scan_screen.dart';
import 'ui/food/serving_screen.dart';
import 'ui/me/data_screen.dart';
import 'ui/me/me_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/shell.dart';
import 'ui/today/today_screen.dart';
import 'ui/train/exercise_picker_screen.dart';
import 'ui/train/routine_editor_screen.dart';
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
      GoRoute(
        path: '/exercise/:id',
        builder: (_, s) => ExerciseDetailScreen(exerciseId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/routine/:id',
        builder: (_, s) => RoutineEditorScreen(routineId: int.tryParse(s.pathParameters['id']!)),
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
        ),
      ),
      GoRoute(
        path: '/barcode-miss/:code',
        builder: (_, s) => BarcodeMissScreen(code: s.pathParameters['code']!),
      ),
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/data', builder: (_, _) => const DataScreen()),
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
                builder: (_, _) => AddFoodScreen(meal: mealForHour(DateTime.now().hour), asTab: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/train', builder: (_, _) => const TrainScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (ctx, _) => NextBuildScreen(title: AppLocalizations.of(ctx).progressTitle),
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

class GymcoApp extends ConsumerWidget {
  const GymcoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(settingsProvider.select((s) => s.locale));
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
