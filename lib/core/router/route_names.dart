abstract class RouteNames {
  static const String splash        = '/';
  static const String welcome       = '/welcome';
  static const String onboarding    = '/onboarding';
  static const String personalInfo  = '/onboarding/personal-info';
  static const String fitnessGoal   = '/onboarding/fitness-goal';
  static const String fitnessLevel      = '/onboarding/fitness-level';
  static const String equipment         = '/onboarding/equipment';
  static const String cameraPermission  = '/onboarding/camera-permission';
  static const String register          = '/register';
  static const String login             = '/login';
  static const String home          = '/home';

  // ── Main App tabs ──────────────────────────────────────────────────────────
  static const String workout        = '/workout';
  static const String progress       = '/progress';
  static const String profile        = '/profile';

  // ── Workout sub-routes ─────────────────────────────────────────────────────
  static const String workoutDetail          = '/workout/:id';
  static const String preWorkout             = '/workout/:id/pre';
  static const String session                = '/workout/:id/session';
  static const String workoutSummary         = '/workout/:id/summary';

  // ── Progress sub-routes ────────────────────────────────────────────────────
  static const String progressHistory        = '/progress/history';
  static const String progressMetrics        = '/progress/metrics';

  // ── Profile sub-routes ─────────────────────────────────────────────────────
  static const String settings               = '/profile/settings';

  // ── Path helpers ───────────────────────────────────────────────────────────
  static String workoutDetailPath(String id)  => '/workout/$id';
  static String preWorkoutPath(String id)     => '/workout/$id/pre';
  static String sessionPath(String id)        => '/workout/$id/session';
  static String workoutSummaryPath(String id) => '/workout/$id/summary';
}
