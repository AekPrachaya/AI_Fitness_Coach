import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingStepDots
// Shared progress indicator for all 5 onboarding steps.
// Active step: accent-colored pill (24×8px). Inactive: grey circle (8×8px).
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingStepDots extends StatelessWidget {
  const OnboardingStepDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// 1-based index of the currently active step.
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index + 1 == currentStep;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isActive ? 24.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.textDisabled,
              borderRadius: AppRadius.circleAll,
            ),
          ),
        );
      }),
    );
  }
}

// Expose AppRadius so callers don't need a separate import. The class is
// defined in app_spacing.dart which is already imported here.
// Re-export via the widgets barrel if needed.
