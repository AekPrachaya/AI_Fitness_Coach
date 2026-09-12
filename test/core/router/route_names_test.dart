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
}
