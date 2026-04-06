import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/typography_preview.dart';
import '../theme/button_preview.dart';
import '../theme/badges_preview.dart';
import '../theme/components_preview.dart';
import '../utils/mock_data_test.dart';
import '../../features/onboarding/splash_screen.dart';
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
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Welcome — TODO: Task 2.2')),
        ),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home — TODO')),
        ),
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
    ],
  );
});
