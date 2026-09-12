import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import 'workout_detail_provider.dart';

// ── Muscle group helpers ──────────────────────────────────────────────────────

List<Color> _heroGradient(String g) => switch (g) {
      'upper_body' => [const Color(0xFF0E2E52), const Color(0xFF0B4A3E)],
      'lower_body' => [const Color(0xFF2E0E52), const Color(0xFF4A0B3E)],
      'full_body' => [const Color(0xFF1E4A0E), const Color(0xFF0E1E4A)],
      'core' => [const Color(0xFF4A1E0E), const Color(0xFF4A2E0E)],
      _ => [AppColors.surface, AppColors.surfaceElevated],
    };

IconData _muscleIcon(String g) => switch (g) {
      'upper_body' => Icons.fitness_center_rounded,
      'lower_body' => Icons.directions_run_rounded,
      'full_body' => Icons.accessibility_new_rounded,
      'core' => Icons.rotate_90_degrees_ccw_rounded,
      _ => Icons.sports_gymnastics_rounded,
    };

// ── WorkoutDetailScreen ───────────────────────────────────────────────────────

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutAsync =
        ref.watch(workoutDetailProvider(widget.workoutId));

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      body: workoutAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (err, _) => _DetailError(
          onRetry: () =>
              ref.invalidate(workoutDetailProvider(widget.workoutId)),
        ),
        data: (workout) => workout == null
            ? const _NotFound()
            : _DetailContent(
                workout: workout,
                tabController: _tabController,
                workoutId: widget.workoutId,
              ),
      ),
      bottomNavigationBar: _StickyBottomCTA(workoutId: widget.workoutId),
    );
  }
}

// ── _DetailContent ────────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.workout,
    required this.tabController,
    required this.workoutId,
  });

  final Workout workout;
  final TabController tabController;
  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return CustomScrollView(
      slivers: [
        // ── Hero ────────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: screenH * 0.42,
          pinned: true,
          floating: false,
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: AppIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => context.pop(),
              backgroundColor: Colors.black.withValues(alpha: 0.4),
              iconColor: Colors.white,
              size: 40,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: AppIconButton(
                icon: Icons.bookmark_border_rounded,
                onTap: () {},
                backgroundColor: Colors.black.withValues(alpha: 0.4),
                iconColor: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroBackground(workout: workout),
          ),
        ),

        // ── Info section ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _InfoSection(workout: workout),
        ),

        // ── Sticky tab bar ────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppColors.background,
          toolbarHeight: 0,
          bottom: _TabBarWidget(controller: tabController),
        ),

        // ── Tab content ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: AnimatedBuilder(
            animation: tabController,
            builder: (context2, _) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: tabController.index == 0
                  ? _InstructionsTab(
                      key: const ValueKey('instructions'),
                      workout: workout,
                    )
                  : _MistakesTab(
                      key: const ValueKey('mistakes'),
                      workout: workout,
                    ),
            ),
          ),
        ),

        // ── Your Plan ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _PlanSection(workoutId: workoutId),
        ),

        // ── Bottom breathing room ─────────────────────────────────────────────
        const SliverPadding(
          padding: EdgeInsets.only(bottom: AppSpacing.xxl),
        ),
      ],
    );
  }
}

// ── _HeroBackground ───────────────────────────────────────────────────────────

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _heroGradient(workout.muscleGroup),
            ),
          ),
        ),

        // Layer 2: large decorative icon (watermark)
        Center(
          child: Icon(
            _muscleIcon(workout.muscleGroup),
            size: 140,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),

        // Layer 3: breathing animated icon
        Center(
          child: Icon(
            _muscleIcon(workout.muscleGroup),
            size: 80,
            color: Colors.white.withValues(alpha: 0.9),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms,
                curve: Curves.easeInOut,
              ),
        ),

        // Layer 4: play button overlay
        Center(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video demo — coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Layer 5: bottom gradient fade into background
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
                colors: [Colors.transparent, AppColors.background],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── _InfoSection ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name (Bebas Neue via displaySmall)
          Text(
            workout.name.toUpperCase(),
            style: tt.displaySmall?.copyWith(
              letterSpacing: 1.5,
              height: 1.0,
            ),
          )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.08, duration: 350.ms, curve: Curves.easeOut),

          const SizedBox(height: AppSpacing.sm),

          // Badges row: difficulty + muscle group chips
          Row(
            children: [
              DifficultyBadge(difficulty: workout.difficulty),
              const SizedBox(width: AppSpacing.sm),
              ...workout.muscleGroupTags.take(3).map((tag) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: _MuscleChip(label: tag),
                  )),
            ],
          )
              .animate(delay: 80.ms)
              .fadeIn(duration: 300.ms),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            workout.description,
            style: tt.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          )
              .animate(delay: 140.ms)
              .fadeIn(duration: 280.ms),

          const SizedBox(height: AppSpacing.md),

          // Quick stats row
          _QuickStatRow(workout: workout),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── _MuscleChip ───────────────────────────────────────────────────────────────

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

// ── _QuickStatRow ─────────────────────────────────────────────────────────────

class _QuickStatRow extends StatelessWidget {
  const _QuickStatRow({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.timer_outlined,
            label: '${workout.durationMinutes} min',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: Icons.repeat_rounded,
            label: '${workout.defaultSets}×${workout.defaultReps}',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatChip(
            icon: Icons.category_rounded,
            label: '${workout.muscleGroupTags.length} muscles',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _TabBarWidget ─────────────────────────────────────────────────────────────

class _TabBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const _TabBarWidget({required this.controller});

  final TabController controller;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: controller,
        indicatorColor: AppColors.accent,
        indicatorWeight: 2,
        dividerHeight: 0,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: tt.titleSmall,
        dividerColor: AppColors.divider,
        tabs: const [
          Tab(text: 'Instructions'),
          Tab(text: 'Common Mistakes'),
        ],
      ),
    );
  }
}

// ── _InstructionsTab ──────────────────────────────────────────────────────────

class _InstructionsTab extends StatelessWidget {
  const _InstructionsTab({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: workout.instructions.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NumberedCircle(number: entry.key + 1, color: AppColors.accent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    entry.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.65,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── _MistakesTab ──────────────────────────────────────────────────────────────

class _MistakesTab extends StatelessWidget {
  const _MistakesTab({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: workout.commonMistakes.map((mistake) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ErrorCircle(),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    mistake,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.65,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Circle indicators ─────────────────────────────────────────────────────────

class _NumberedCircle extends StatelessWidget {
  const _NumberedCircle({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          '$number',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _ErrorCircle extends StatelessWidget {
  const _ErrorCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.error.withValues(alpha: 0.12),
      ),
      child: const Center(
        child: Icon(Icons.close_rounded, size: 14, color: AppColors.error),
      ),
    );
  }
}

// ── _PlanSection ──────────────────────────────────────────────────────────────

class _PlanSection extends ConsumerWidget {
  const _PlanSection({required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final plan = ref.watch(workoutPlanProvider(workoutId));
    final notifier = ref.read(workoutPlanProvider(workoutId).notifier);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Plan', style: tt.titleLarge),
            const SizedBox(height: AppSpacing.lg),

            // Sets × Reps selectors
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _PlanSelector(
                      label: 'Sets',
                      value: plan.sets,
                      onIncrement: notifier.incrementSets,
                      onDecrement: notifier.decrementSets,
                      min: 1,
                      max: 10,
                    ),
                  ),
                  Container(
                    width: 1,
                    color: AppColors.divider,
                  ),
                  Expanded(
                    child: _PlanSelector(
                      label: 'Reps',
                      value: plan.reps,
                      onIncrement: notifier.incrementReps,
                      onDecrement: notifier.decrementReps,
                      min: 1,
                      max: 50,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Text('Mode', style: tt.titleSmall),
            const SizedBox(height: AppSpacing.sm),

            // Mode toggle
            AppSegmentedControl(
              options: const ['Beginner', 'Pro'],
              selectedIndex: plan.mode == 'beginner' ? 0 : 1,
              onChanged: (i) => notifier.setMode(i == 0 ? 'beginner' : 'pro'),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Mode description
            Text(
              plan.mode == 'beginner'
                  ? 'Focus on form and controlled movement.'
                  : 'Increase tempo, add resistance, push your limits.',
              style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── _PlanSelector ─────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
    required this.min,
    required this.max,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: tt.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIconButton(
              icon: Icons.remove_rounded,
              onTap: value > min ? onDecrement : null,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.md),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                '$value',
                key: ValueKey(value),
                style: tt.displaySmall?.copyWith(color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppIconButton(
              icon: Icons.add_rounded,
              onTap: value < max ? onIncrement : null,
              size: 36,
            ),
          ],
        ),
      ],
    );
  }
}

// ── _StickyBottomCTA ──────────────────────────────────────────────────────────

class _StickyBottomCTA extends ConsumerWidget {
  const _StickyBottomCTA({required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final plan = ref.watch(workoutPlanProvider(workoutId));

    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live plan summary
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${plan.sets} sets × ${plan.reps} reps  •  ',
                    style:
                        tt.labelLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    plan.mode == 'beginner' ? 'Beginner Mode' : 'Pro Mode',
                    style: tt.labelLarge?.copyWith(color: AppColors.accent),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              AppPrimaryButton(
                label: 'Start Exercise',
                onTap: () =>
                    context.go(RouteNames.preWorkoutPath(workoutId)),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 100.ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.1, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── _DetailSkeleton ───────────────────────────────────────────────────────────

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: screenH * 0.42,
          pinned: true,
          backgroundColor: AppColors.surface,
          flexibleSpace: FlexibleSpaceBar(
            background: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.surfaceElevated,
              child: const SizedBox.expand(),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const AppCard.skeleton(height: 48),
              const SizedBox(height: AppSpacing.md),
              const AppCard.skeleton(height: 32),
              const SizedBox(height: AppSpacing.md),
              const AppCard.skeleton(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── _DetailError ──────────────────────────────────────────────────────────────

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.warning, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text('Could not load exercise', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppGhostButton(label: 'Retry', onTap: onRetry),
        ],
      ),
    );
  }
}

// ── _NotFound ─────────────────────────────────────────────────────────────────

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text('Exercise not found', style: tt.titleMedium),
          const SizedBox(height: AppSpacing.md),
          AppGhostButton(label: 'Go back', onTap: () => context.pop()),
        ],
      ),
    );
  }
}
