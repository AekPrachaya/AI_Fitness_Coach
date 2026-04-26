import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/typography_preview.dart';
import '../theme/button_preview.dart';
import '../theme/badges_preview.dart';
import '../theme/components_preview.dart';
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
          return WorkoutSessionScreen(exerciseId: exerciseId);
        },
      ),
      GoRoute(
        path: RouteNames.workoutSummary,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WorkoutSummaryScreen(
            setsCompleted: extra['setsCompleted'] as int,
            targetSets: extra['targetSets'] as int,
            totalReps: extra['totalReps'] as int,
            exerciseName: extra['exerciseName'] as String,
          );
        },
      ),

      // ── Development / debug routes ──────────────────────────────────────
      GoRoute(
        path: '/typography-preview',
        builder: (context, state) => const TypographyPreview(),
      ),
      GoRoute(
        path: '/button-preview',
        builder: (context, state) => const ButtonPreview(),
      ),
      GoRoute(
        path: '/components-preview',
        builder: (context, state) => const ComponentsPreview(),
      ),
      GoRoute(
        path: '/badges-preview',
        builder: (context, state) => const BadgesPreview(),
      ),
      GoRoute(
        path: '/mock-data-debug',
        builder: (context, state) => const MockDataDebugScreen(),
      ),
      GoRoute(
        path: '/debug/onboarding',
        builder: (context, state) => const OnboardingDebugScreen(),
      ),
    ],
  );
});
