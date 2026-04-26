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
// Level data model
// ─────────────────────────────────────────────────────────────────────────────

class _LevelData {
  const _LevelData({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
}

const _levels = [
  _LevelData(
    id: 'beginner',
    emoji: '🌱',
    title: 'Beginner',
    subtitle: 'Less than 6 months of training',
    description: 'Building foundational strength and habits.',
  ),
  _LevelData(
    id: 'intermediate',
    emoji: '🔥',
    title: 'Intermediate',
    subtitle: '6 months to 2 years',
    description: 'Ready to push harder and refine technique.',
  ),
  _LevelData(
    id: 'advanced',
    emoji: '🏆',
    title: 'Advanced',
    subtitle: 'More than 2 years',
    description: 'Optimizing performance and targeting goals.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// FitnessLevelScreen
// ─────────────────────────────────────────────────────────────────────────────

class FitnessLevelScreen extends ConsumerWidget {
  const FitnessLevelScreen({super.key});

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
                onPressed: () => context.go(RouteNames.fitnessGoal),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),

              // ── Step dots ─────────────────────────────────────────────────
              const SizedBox(height: AppSpacing.sm),
              const Center(
                child: OnboardingStepDots(currentStep: 3, totalSteps: 5),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                "What's your\nexperience level?",
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
                'This helps us calibrate workout intensity for you.',
                style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 300.ms),

              const SizedBox(height: AppSpacing.xl),

              // ── Level cards ───────────────────────────────────────────────
              for (int i = 0; i < _levels.length; i++) ...[
                _LevelCard(
                  data: _levels[i],
                  isSelected: state.fitnessLevel == _levels[i].id,
                  onTap: () => notifier.setFitnessLevel(_levels[i].id),
                )
                    .animate(
                      key: ValueKey('level_anim_${_levels[i].id}'),
                      delay: (i * 60).ms,
                    )
                    .fadeIn(duration: 300.ms)
                    .slideY(
                      begin: 0.1,
                      end: 0.0,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
                if (i < _levels.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],

              const Spacer(),

              // ── Next button ───────────────────────────────────────────────
              AppPrimaryButton(
                label: 'Next',
                onTap: state.step3Complete
                    ? () => context.go(RouteNames.equipment)
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
// _LevelCard
// ─────────────────────────────────────────────────────────────────────────────

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _LevelData data;
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
                  // ── Emoji + title column ──────────────────────────────────
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        data.title,
                        style: tt.titleMedium?.copyWith(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // ── Subtitle + description ────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.subtitle,
                          style: tt.bodyMedium?.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
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
