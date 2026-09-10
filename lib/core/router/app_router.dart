import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/typography_preview.dart';
import '../theme/button_preview.dart';
import '../theme/badges_preview.dart';
import '../theme/components_preview.dart';
import '../utils/exercise_display.dart';
import '../utils/mock_data_test.dart';
import '../utils/onboarding_debug_screen.dart';
import '../../features/onboarding/camera_permission_screen.dart';
import '../../features/onboarding/equipment_screen.dart';
import '../../features/onboarding/fitness_goal_screen.dart';
import '../../features/onboarding/fitness_level_screen.dart';
import '../../features/onboarding/personal_info_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/workout/session/workout_session_screen.dart';
import '../../features/workout/session/workout_summary_screen.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      // ── Production routes ───────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: RouteNames.personalInfo,
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: RouteNames.fitnessGoal,
        builder: (context, state) => const FitnessGoalScreen(),
      ),
      GoRoute(
        path: RouteNames.fitnessLevel,
        builder: (context, state) => const FitnessLevelScreen(),
      ),
      GoRoute(
        path: RouteNames.equipment,
        builder: (context, state) => const EquipmentScreen(),
      ),
      GoRoute(
        path: RouteNames.cameraPermission,
        builder: (context, state) => const CameraPermissionScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.workoutSession,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final exerciseId = extra?['exerciseId'] as String? ?? 'squats';
          return WorkoutSessionScreen(
            exerciseId: exerciseId,
            exerciseName:
                extra?['exerciseName'] as String? ?? displayNameFor(exerciseId),
            targetSets: extra?['targetSets'] as int?,
            targetReps: extra?['targetReps'] as int?,
          );
        },
      ),
      GoRoute(
        path: RouteNames.workoutSummary,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final exerciseId = extra['exerciseId'] as String? ?? 'squats';
          return WorkoutSummaryScreen(
            exerciseId: exerciseId,
            exerciseName:
                extra['exerciseName'] as String? ?? displayNameFor(exerciseId),
            setsCompleted: extra['setsCompleted'] as int,
            targetSets: extra['targetSets'] as int,
            totalReps: extra['totalReps'] as int,
            durationSeconds: extra['durationSeconds'] as int? ?? 0,
            avgFormScore: (extra['avgFormScore'] as num?)?.toDouble() ?? 0,
            mostCommonError: extra['mostCommonError'] as String? ?? '',
          );
        },
      ),

      // ── Development / debug routes ──────────────────────────────────────
      GoRoute(
        path: DebugRoutes.typographyPreview,
        builder: (context, state) => const TypographyPreview(),
      ),
      GoRoute(
        path: DebugRoutes.buttonPreview,
        builder: (context, state) => const ButtonPreview(),
      ),
      GoRoute(
        path: DebugRoutes.componentsPreview,
        builder: (context, state) => const ComponentsPreview(),
      ),
      GoRoute(
        path: DebugRoutes.badgesPreview,
        builder: (context, state) => const BadgesPreview(),
      ),
      GoRoute(
        path: DebugRoutes.mockData,
        builder: (context, state) => const MockDataDebugScreen(),
      ),
      GoRoute(
        path: DebugRoutes.onboarding,
        builder: (context, state) => const OnboardingDebugScreen(),
      ),
    ],
  );
});
