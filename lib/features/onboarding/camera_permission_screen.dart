import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'onboarding_notifier.dart';
import 'widgets/onboarding_step_dots.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CameraPermissionScreen — Step 5 of 5
// Uses ConsumerStatefulWidget for the pulsing ring AnimationController.
// ─────────────────────────────────────────────────────────────────────────────

class CameraPermissionScreen extends ConsumerStatefulWidget {
  const CameraPermissionScreen({super.key});

  @override
  ConsumerState<CameraPermissionScreen> createState() =>
      _CameraPermissionScreenState();
}

class _CameraPermissionScreenState
    extends ConsumerState<CameraPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Permission handling ─────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    final granted = status == PermissionStatus.granted;

    ref.read(onboardingNotifierProvider.notifier).setCameraGranted(granted);
    await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();

    if (!mounted) return;

    if (granted) {
      context.go(RouteNames.register);
    } else if (status == PermissionStatus.permanentlyDenied) {
      _showSettingsDialog();
    } else {
      context.go(RouteNames.register);
    }
  }

  Future<void> _skipAndComplete() async {
    ref.read(onboardingNotifierProvider.notifier).setCameraGranted(false);
    await ref.read(onboardingNotifierProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go(RouteNames.register);
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text(
          'Camera Access Required',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Camera permission was denied. To enable pose detection, '
          'please allow camera access in your device settings.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RouteNames.register);
            },
            child: Text(
              'Skip',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              if (!mounted) return;
              context.go(RouteNames.register);
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              // ── Back button ───────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => context.go(RouteNames.equipment),
                  padding: EdgeInsets.zero,
                ),
              ),

              // ── Step dots ─────────────────────────────────────────────
              const SizedBox(height: AppSpacing.sm),
              const OnboardingStepDots(currentStep: 5, totalSteps: 5),

              const Spacer(flex: 1),

              // ── Pulsing camera icon ───────────────────────────────────
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulsing ring
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, _) => Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(
                              alpha: 0.15 + (_pulseAnimation.value * 0.25),
                            ),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    // Middle pulsing ring
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, _) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(
                              alpha: 0.2 + (_pulseAnimation.value * 0.3),
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    // Inner static circle with camera icon
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceElevated,
                        border: Border.all(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.xl),

              // ── Title ─────────────────────────────────────────────────
              Text(
                'Enable Camera\nfor Pose Detection',
                style: tt.headlineLarge?.copyWith(height: 1.15),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0.0,
                    duration: 350.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.md),

              // ── Description ───────────────────────────────────────────
              Text(
                'FormAI uses your camera in real time to analyze your\n'
                'exercise form and count reps accurately.',
                style: tt.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // ── Privacy bullet points ─────────────────────────────────
              const _PrivacyPoint(
                icon: Icons.check_circle_outline,
                color: AppColors.accent,
                positive: true,
                text: 'Camera is used only during active workout sessions',
                index: 0,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PrivacyPoint(
                icon: Icons.check_circle_outline,
                color: AppColors.accent,
                positive: true,
                text: 'Video is processed on-device — never uploaded or stored',
                index: 1,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PrivacyPoint(
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                positive: false,
                text: 'We never record or save any video footage',
                index: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              const _PrivacyPoint(
                icon: Icons.cancel_outlined,
                color: AppColors.error,
                positive: false,
                text: 'Camera is never accessed outside of workout mode',
                index: 3,
              ),

              const Spacer(flex: 2),

              // ── CTA buttons ───────────────────────────────────────────
              AppPrimaryButton(
                label: 'Allow Camera Access',
                onTap: _requestPermission,
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(
                    begin: 0.1,
                    end: 0.0,
                    duration: 300.ms,
                  ),

              const SizedBox(height: AppSpacing.md),

              AppGhostButton(
                label: 'Skip for now',
                onTap: _skipAndComplete,
              )
                  .animate(delay: 700.ms)
                  .fadeIn(duration: 250.ms),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PrivacyPoint
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyPoint extends StatelessWidget {
  const _PrivacyPoint({
    required this.icon,
    required this.color,
    required this.positive,
    required this.text,
    required this.index,
  });

  final IconData icon;
  final Color color;
  final bool positive;
  final String text;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: tt.bodySmall?.copyWith(
              color: positive ? AppColors.textPrimary : AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    )
        .animate(delay: (350 + index * 60).ms)
        .fadeIn(duration: 250.ms)
        .slideX(
          begin: -0.08,
          end: 0.0,
          duration: 250.ms,
          curve: Curves.easeOut,
        );
  }
}
