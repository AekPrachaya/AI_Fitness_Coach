import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/mock_data.dart';
import '../../shared/widgets/app_badge.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _progressController;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _progressAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // ── Glow pulse — breathes 0.3 ↔ 1.0 every 1500ms ──────────────────────
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);

    // ── Progress bar — 0.0 → 1.0 over 2000ms ──────────────────────────────
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController.forward();

    // ── Navigate after 2200ms (200ms after progress bar completes) ─────────
    Future.delayed(const Duration(milliseconds: 2200), _navigateNext);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    bool onboardingComplete = false;
    bool isLoggedIn = false;
    try {
      final box = Hive.box(MockData.boxUserProfile);
      onboardingComplete =
          box.get(MockData.prefOnboardingComplete) as bool? ?? false;
      isLoggedIn = box.get('is_logged_in', defaultValue: false) as bool;
    } catch (_) {
      // Box not accessible — default to onboarding flow
      onboardingComplete = false;
    }

    if (!mounted) return;
    if (!onboardingComplete) {
      context.go(RouteNames.welcome);
    } else if (!isLoggedIn) {
      context.go(RouteNames.login);
    } else {
      context.go(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Center content ─────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with animated glow border
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(
                              color: AppColors.accent
                                  .withValues(alpha: _glowAnimation.value),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGlow
                                    .withValues(alpha: _glowAnimation.value * 0.6),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: AppColors.accent,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 300.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: AppSpacing.lg),

                    // App name
                    Text(
                      'FORMAI',
                      style: textTheme.displayMedium,
                    )
                        .animate(delay: 150.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0.0,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: AppSpacing.sm),

                    // Tagline
                    Text(
                      'Train Smarter. Move Better.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ).animate(delay: 350.ms).fadeIn(duration: 300.ms),
                  ],
                ),
              ),
            ),

            // ── Progress bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, _) => AppProgressBar(
                  value: _progressAnimation.value,
                  height: 3.0,
                  animated: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
