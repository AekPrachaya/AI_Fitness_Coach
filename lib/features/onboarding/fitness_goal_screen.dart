import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';
import 'onboarding_notifier.dart';
import 'widgets/onboarding_step_dots.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Goal data model
// ─────────────────────────────────────────────────────────────────────────────

class _GoalData {
  const _GoalData({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
}

const _goals = [
  _GoalData(
    id: 'lose_weight',
    emoji: '🏃',
    title: 'Lose Weight',
    description: 'Burn fat and improve cardiovascular health',
  ),
  _GoalData(
    id: 'build_muscle',
    emoji: '💪',
    title: 'Build Muscle',
    description: 'Increase strength and lean muscle mass',
  ),
  _GoalData(
    id: 'improve_flexibility',
    emoji: '🧘',
    title: 'Improve Flexibility',
    description: 'Enhance mobility and reduce injury risk',
  ),
  _GoalData(
    id: 'boost_endurance',
    emoji: '⚡',
    title: 'Boost Endurance',
    description: 'Build stamina for sustained performance',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// FitnessGoalScreen
// ─────────────────────────────────────────────────────────────────────────────

class FitnessGoalScreen extends ConsumerWidget {
  const FitnessGoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ───────────────────────────────────────────────
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.go(RouteNames.personalInfo),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              // ── Step dots ─────────────────────────────────────────────────
              const SizedBox(height: AppSpacing.sm),
              const Center(
                child: OnboardingStepDots(currentStep: 2, totalSteps: 5),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                "What's your\nmain goal?",
                style: tt.headlineLarge?.copyWith(height: 1.15),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(
                    begin: 0.12,
                    end: 0.0,
                    duration: 300.ms,
                    curve: Curves.easeOut,
                  ),

              const SizedBox(height: AppSpacing.sm),

              // ── Subtitle ──────────────────────────────────────────────────
              Text(
                'Choose one — you can always change this later.',
                style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // ── Goal cards ────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (int i = 0; i < _goals.length; i++) ...[
                        _GoalCard(
                          data: _goals[i],
                          isSelected: state.fitnessGoal == _goals[i].id,
                          onTap: () =>
                              notifier.setFitnessGoal(_goals[i].id),
                        )
                            .animate(
                              key: ValueKey('goal_anim_${_goals[i].id}'),
                              delay: (i * 50).ms,
                            )
                            .fadeIn(duration: 300.ms)
                            .slideY(
                              begin: 0.12,
                              end: 0.0,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            ),
                        if (i < _goals.length - 1)
                          const SizedBox(height: AppSpacing.md),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Next button ───────────────────────────────────────────────
              AppPrimaryButton(
                label: 'Next',
                onTap: state.step2Complete
                    ? () => context.go(RouteNames.fitnessLevel)
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GoalCard
// ─────────────────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _GoalData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.98,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.accent.withValues(alpha: 0.06),
            highlightColor: AppColors.accent.withValues(alpha: 0.04),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(
                  color:
                      isSelected ? AppColors.accent : AppColors.borderSubtle,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // ── Emoji circle ─────────────────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadius.circleAll,
                    ),
                    child: Center(
                      child: Text(
                        data.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // ── Title + description ───────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: tt.titleLarge?.copyWith(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          data.description,
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // ── Checkmark ─────────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
