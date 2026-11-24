import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/router/route_names.dart';

void main() {
  const product = [
    RouteNames.splash,
    RouteNames.welcome,
    RouteNames.onboarding,
    RouteNames.personalInfo,
    RouteNames.fitnessGoal,
    RouteNames.fitnessLevel,
    RouteNames.equipment,
    RouteNames.cameraPermission,
    RouteNames.register,
    RouteNames.login,
    RouteNames.home,
    RouteNames.workout,
    RouteNames.progress,
    RouteNames.profile,
    RouteNames.workoutDetail,
    RouteNames.preWorkout,
    RouteNames.session,
    RouteNames.workoutSummary,
    RouteNames.progressHistory,
    RouteNames.progressMetrics,
    RouteNames.settings,
  ];

  const debug = [
    DebugRoutes.typographyPreview,
    DebugRoutes.buttonPreview,
    DebugRoutes.componentsPreview,
    DebugRoutes.badgesPreview,
    DebugRoutes.mockData,
    DebugRoutes.onboarding,
  ];

  test('no two routes share a path', () {
    // GoRouter takes the first match, so a duplicate silently shadows a screen.
    final all = [...product, ...debug];
    expect(all.toSet().length, all.length);
  });

  test('every path is rooted and has no trailing slash', () {
    for (final path in [...product, ...debug]) {
      expect(path, startsWith('/'), reason: path);
      expect(path == '/' || !path.endsWith('/'), isTrue, reason: path);
      expect(path.trim(), path, reason: 'stray whitespace in "$path"');
    }
  });

  group('workoutSummaryPath', () {
    test('without a session id points at the plain summary route', () {
      expect(RouteNames.workoutSummaryPath('squats'), '/workout/squats/summary');
    });

    test('with a session id adds it as a query parameter', () {
      final path = RouteNames.workoutSummaryPath('squats', sessionId: 'a b&c');
      final uri = Uri.parse(path);
      expect(uri.path, '/workout/squats/summary');
      expect(uri.queryParameters['session'], 'a b&c');
    });
  });

  test('exerciseTransitionPath points at the up-next screen of an exercise',
      () {
    expect(RouteNames.exerciseTransitionPath('squats'), '/workout/squats/next');
    expect(RouteNames.exerciseTransition, '/workout/:id/next');
  });
}
