# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Analyze only project code (avoids errors from the vendored flutter/ SDK directory)
dart analyze lib/

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/foo_test.dart

# Build APK (debug)
flutter build apk --debug

# Get dependencies
flutter pub get
```

## Architecture

**FormAI** is a Flutter 3.x / Dart 3.x AI Fitness Coach app (frontend-only phase — no backend, no HTTP, no Firebase).

### Entry points
- `lib/main.dart` — initialises Hive, wraps the tree in `ProviderScope`
- `lib/app.dart` — `FitnessApp` (`ConsumerWidget`), mounts `AppTheme.dark`/`AppTheme.light` and `ThemeMode.dark`, reads `routerProvider`

### Core systems
| Path | Purpose |
|---|---|
| `lib/core/router/app_router.dart` | `routerProvider` — single `Provider<GoRouter>`; all routes live here |
| `lib/core/theme/app_colors.dart` | `AppColors.*` — every color constant; **never use raw hex in widgets** |
| `lib/core/theme/app_spacing.dart` | `AppSpacing.*` (4–64 dp) and `AppRadius.*` — **never use raw numbers** |
| `lib/core/theme/app_typography.dart` | `AppTypography.textTheme` — Bebas Neue / DM Sans / JetBrains Mono |
| `lib/core/theme/app_theme.dart` | `AppTheme.dark` / `AppTheme.light` |
| `lib/core/theme/app_shadows.dart` | `AppShadows.low/medium/high/glow` |
| `lib/core/utils/mock_data.dart` | Stub — to be filled in Phase 1 |

### Shared widgets
`lib/shared/widgets/app_button.dart` exports five button types:
`AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton`, `AppIconButton`, `AppFAB`.
All buttons are `StatefulWidget` (they own only the press-animation bool `_isPressed`); that is intentional.

### Feature folders (to be built)
`lib/features/{onboarding,auth,home,workout/browse,workout/detail,workout/session,workout/summary,progress,profile}/`

### PoC file
`lib/features/workout/session/pose_test_screen.dart` is a throwaway proof-of-concept for ML Kit pose detection. It is **not** wired into the router and does not follow design-system rules — treat it as reference material only.

## Non-negotiable rules

1. **Colors** — always `AppColors.*`; never `Color(0xFF...)` or `Colors.*` in widget code
2. **Spacing / radius** — always `AppSpacing.*` / `AppRadius.*`; never raw numbers in `EdgeInsets`, `SizedBox`, or `BorderRadius`
3. **Typography** — always `context.textTheme.*`; never inline `TextStyle(fontSize: ...)`
4. **Navigation** — always `context.go()` / `context.push()`; never `Navigator.push()`
5. **State** — prefer `ConsumerWidget` + Riverpod provider over `StatefulWidget` for business state
6. **Mock only** — no HTTP calls, no Firebase, no real auth during Phase 1–5
7. **Dark theme** — `ThemeMode.dark` is default; scaffold background is always `AppColors.background`
8. **File naming** — `snake_case.dart`; class names `PascalCase`
9. **Provider naming** — `<feature>NotifierProvider` / `<feature>Provider`
10. **Route paths** — define in `RouteNames.*` constants, not inline strings

## Session state machine

The workout session notifier must implement these states in order:

```
idle → initializing → tracking → repComplete → setComplete → resting → tracking
                                                            → finished (last set)
tracking ↔ paused
tracking ↔ error (body lost / poor lighting)
```

## Dependencies (key versions)
- `go_router: ^12.0.0`
- `flutter_riverpod: ^2.0.0`
- `hive_flutter: ^1.1.0`
- `camera: ^0.10.0`
- `fl_chart: ^0.65.0`
- `flutter_animate: ^4.0.0`
- `google_mlkit_pose_detection: ^0.12.0`
