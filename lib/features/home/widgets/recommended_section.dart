import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/exercise_card.dart';
import '../home_provider.dart';

// ── RecommendedSection ────────────────────────────────────────────────────────

class RecommendedSection extends ConsumerWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final workoutsAsync = ref.watch(recommendedWorkoutsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Text('Recommended for You', style: tt.titleLarge),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(RouteNames.workout),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See all',
                  style: tt.labelLarge?.copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Card list
        workoutsAsync.when(
          loading: () => const _RecommendedSkeleton(),
          error: (_, _) => const _RecommendedError(),
          data: (workouts) => SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              physics: const BouncingScrollPhysics(),
              itemCount: workouts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return SizedBox(
                  width: 160,
                  child: ExerciseCard(
                    workout: workout,
                    compact: true,
                    onTap: () => context
                        .push(RouteNames.workoutDetailPath(workout.id)),
                  ),
                )
                    .animate(delay: (index * 80).ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(
                      begin: 0.1,
                      end: 0.0,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── _RecommendedSkeleton ──────────────────────────────────────────────────────

class _RecommendedSkeleton extends StatelessWidget {
  const _RecommendedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, _) => Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceElevated,
          child: Container(
            width: 160,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
            ),
          ),
        ),
      ),
    );
  }
}

// ── _RecommendedError ─────────────────────────────────────────────────────────

class _RecommendedError extends StatelessWidget {
  const _RecommendedError();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Could not load workouts',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textDisabled),
        ),
      ),
    );
  }
}
