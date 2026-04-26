import 'package:flutter/material.dart';
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
import '../../features/workout/browse/workout_browse_screen.dart';
import '../../features/workout/detail/workout_detail_screen.dart';
import '../../features/workout/session/pre_workout_screen.dart';
import '../../features/workout/session/session_screen.dart';
import '../../features/workout/summary/workout_summary_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'route_names.dart';

// ── Page transition helper ───────────────────────────────────────────────────
// SPEC: "Default: Fade + slight vertical slide (200ms)"

CustomTransitionPage<void> _fadePage({
  required LocalKey key,
  required Widget child,
}) =>
    CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 200),
    );

// ── Router ───────────────────────────────────────────────────────────────────

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

      // ── Main App Shell (4-tab navigation) ──────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Tab 1: Home
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),

          // Tab 2: Workout + nested sub-routes
          GoRoute(
            path: RouteNames.workout,
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const WorkoutBrowseScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _fadePage(
                  key: state.pageKey,
                  child: WorkoutDetailScreen(
                    workoutId: state.pathParameters['id']!,
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'pre',
                    pageBuilder: (context, state) => _fadePage(
                      key: state.pageKey,
                      child: PreWorkoutScreen(
                        workoutId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'session',
                    pageBuilder: (context, state) => _fadePage(
                      key: state.pageKey,
                      child: SessionScreen(
                        workoutId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'summary',
                    pageBuilder: (context, state) => _fadePage(
                      key: state.pageKey,
                      child: WorkoutSummaryScreen(
                        workoutId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 3: Progress
          GoRoute(
            path: RouteNames.progress,
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const ProgressScreen(),
            ),
          ),

          // Tab 4: Profile
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) => _fadePage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
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
