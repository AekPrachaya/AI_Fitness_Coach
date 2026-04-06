// TODO: Replace HeroFallbackAnimation with Lottie.asset() once
// assets/animations/hero_fitness.json is added to the project.
// Usage: Lottie.asset('assets/animations/hero_fitness.json', repeat: true)

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Layer 1: Radial gradient background ──────────────────────────
          const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.85,
                  colors: [
                    AppColors.surfaceElevated, // lighter center
                    AppColors.background,      // near-black edges
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 2: Content ─────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  // Hero area — top ~50%
                  const Expanded(
                    flex: 5,
                    child: Center(child: HeroFallbackAnimation()),
                  ),

                  // Content area — bottom ~50%
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        // Headline
                        Text(
                          'YOUR AI\nPERSONAL TRAINER',
                          style: textTheme.displayMedium?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(delay: 200.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(
                              begin: 0.2,
                              end: 0.0,
                              duration: 400.ms,
                              curve: Curves.easeOut,
                            ),

                        const SizedBox(height: AppSpacing.md),

                        // Subtext
                        Text(
                          'Real-time pose correction and personalized\n'
                          'workout plans powered by AI.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(delay: 350.ms)
                            .fadeIn(duration: 350.ms),

                        const Spacer(),

                        // Primary CTA — Get Started
                        AppPrimaryButton(
                          label: 'Get Started',
                          onTap: () => context.go(RouteNames.onboarding),
                        )
                            .animate(delay: 500.ms)
                            .fadeIn(duration: 300.ms)
                            .slideY(
                              begin: 0.15,
                              end: 0.0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),

                        const SizedBox(height: AppSpacing.md),

                        // Secondary CTA — already have account
                        AppGhostButton(
                          label: 'I already have an account',
                          onTap: () => context.go(RouteNames.login),
                        ).animate(delay: 600.ms).fadeIn(duration: 300.ms),

                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroFallbackAnimation
// Three concentric pulsing circles in AppColors.accent representing motion.
// Replace with Lottie.asset('assets/animations/hero_fitness.json') once asset
// is available.
// ─────────────────────────────────────────────────────────────────────────────

class HeroFallbackAnimation extends StatefulWidget {
  const HeroFallbackAnimation({super.key});

  @override
  State<HeroFallbackAnimation> createState() => _HeroFallbackAnimationState();
}

class _HeroFallbackAnimationState extends State<HeroFallbackAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Three rings staggered via Interval curves on the same controller
  late final Animation<double> _innerScale;
  late final Animation<double> _middleScale;
  late final Animation<double> _outerScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _innerScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.70, curve: Curves.easeInOut),
      ),
    );
    _middleScale = Tween<double>(begin: 0.72, end: 0.90).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.85, curve: Curves.easeInOut),
      ),
    );
    _outerScale = Tween<double>(begin: 0.62, end: 0.80).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 1.00, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Use the shorter dimension so rings stay circular
            final size = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring — lowest opacity
                _Ring(
                  diameter: size * _outerScale.value,
                  color: AppColors.accent.withValues(alpha: 0.08),
                ),
                // Middle ring
                _Ring(
                  diameter: size * _middleScale.value * 0.72,
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
                // Inner ring — highest opacity + glow
                _Ring(
                  diameter: size * _innerScale.value * 0.46,
                  color: AppColors.accent.withValues(alpha: 0.25),
                  glow: true,
                ),
                // Center icon
                const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: AppColors.accent,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.diameter,
    required this.color,
    this.glow = false,
  });

  final double diameter;
  final Color color;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.accentGlow,
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
    );
  }
}
