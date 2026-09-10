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
  static const String home              = '/home';
  static const String workoutSession    = '/workout/session';
  static const String workoutSummary    = '/workout/summary';
}

/// Development-only screens. Kept apart from [RouteNames] so it stays obvious
/// which paths ship as part of the product.
abstract class DebugRoutes {
  static const String typographyPreview = '/typography-preview';
  static const String buttonPreview     = '/button-preview';
  static const String componentsPreview = '/components-preview';
  static const String badgesPreview     = '/badges-preview';
  static const String mockData          = '/mock-data-debug';
  static const String onboarding        = '/debug/onboarding';
}
