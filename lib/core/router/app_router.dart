import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/typography_preview.dart';
import '../theme/button_preview.dart';
import '../theme/badges_preview.dart';
import '../theme/components_preview.dart';
import '../utils/mock_data_test.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/mock-data-debug',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold()),
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
