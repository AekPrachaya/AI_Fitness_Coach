import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'onboarding_notifier.dart';
import 'widgets/age_picker_widget.dart';
import 'widgets/bmi_result_widget.dart';
import 'widgets/height_picker_widget.dart';
import 'widgets/onboarding_step_dots.dart';
import 'widgets/weight_picker_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PersonalInfoScreen — Onboarding Step 1 of 5
// ─────────────────────────────────────────────────────────────────────────────

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top section (fixed) ─────────────────────────────────────
            _TopSection(currentStep: 1),

            // ── Scrollable form ─────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Age ─────────────────────────────────────────────
                    Text('Age', style: tt.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    AgePickerWidget(
                      value: state.age,
                      onChanged: notifier.setAge,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Gender ──────────────────────────────────────────
                    Text('Gender', style: tt.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    AppSegmentedControl(
                      options: const ['Male', 'Female', 'Prefer not to say'],
                      selectedIndex: _genderIndex(state.gender),
                      onChanged: (i) => notifier.setGender(_genderFromIndex(i)),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Height ──────────────────────────────────────────
                    Row(
                      children: [
                        Text('Height', style: tt.titleSmall),
                        const Spacer(),
                        SizedBox(
                          width: 130,
                          child: AppSegmentedControl(
                            options: const ['cm', 'ft'],
                            selectedIndex: state.heightInFeet ? 1 : 0,
                            onChanged: (_) => notifier.toggleHeightUnit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    HeightPickerWidget(
                      value: state.heightCm,
                      inFeet: state.heightInFeet,
                      onChanged: notifier.setHeightCm,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Weight ──────────────────────────────────────────
                    Row(
                      children: [
                        Text('Weight', style: tt.titleSmall),
                        const Spacer(),
                        SizedBox(
                          width: 130,
                          child: AppSegmentedControl(
                            options: const ['kg', 'lbs'],
                            selectedIndex: state.weightInLbs ? 1 : 0,
                            onChanged: (_) => notifier.toggleWeightUnit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    WeightPickerWidget(
                      value: state.weightKg,
                      inLbs: state.weightInLbs,
                      onChanged: notifier.setWeightKg,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── BMI result (animated in when all fields filled) ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: state.bmi != null
                          ? BmiResultWidget(
                              key: const ValueKey('bmi'),
                              bmi: state.bmi!,
                              category: state.bmiCategory!,
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // ── Bottom CTA (always visible) ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: AppPrimaryButton(
                label: 'Next',
                onTap: state.step1Complete
                    ? () => context.go(RouteNames.fitnessGoal)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopSection — back button + step dots + title/subtitle
// ─────────────────────────────────────────────────────────────────────────────

class _TopSection extends StatelessWidget {
  const _TopSection({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.go(RouteNames.welcome),
        ),

        // Step dots
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Center(
            child: OnboardingStepDots(
              currentStep: currentStep,
              totalSteps: 5,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Tell us about yourself', style: tt.headlineMedium),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            "We'll use this to personalize your workout plan.",
            style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers — gender string ↔ segmented control index
// ─────────────────────────────────────────────────────────────────────────────

int _genderIndex(String? gender) {
  switch (gender) {
    case 'male':
      return 0;
    case 'female':
      return 1;
    case 'prefer_not_to_say':
      return 2;
    default:
      return -1; // nothing selected
  }
}

String _genderFromIndex(int index) {
  switch (index) {
    case 0:
      return 'male';
    case 1:
      return 'female';
    default:
      return 'prefer_not_to_say';
  }
}
