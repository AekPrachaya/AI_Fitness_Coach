import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';
import 'browse_provider.dart';

// ── Filter data ───────────────────────────────────────────────────────────────

typedef _Filter = ({String label, String? value});

const _muscleFilters = <_Filter>[
  (label: 'All', value: null),
  (label: 'Upper Body', value: 'upper_body'),
  (label: 'Lower Body', value: 'lower_body'),
  (label: 'Full Body', value: 'full_body'),
  (label: 'Core', value: 'core'),
  (label: 'Cardio', value: 'cardio'),
];

const _difficultyValues = <String?>[null, 'beginner', 'intermediate', 'advanced'];

int _difficultyIndex(String? d) => switch (d) {
      'beginner' => 1,
      'intermediate' => 2,
      'advanced' => 3,
      _ => 0,
    };

// ── WorkoutBrowseScreen ───────────────────────────────────────────────────────

class WorkoutBrowseScreen extends ConsumerStatefulWidget {
  const WorkoutBrowseScreen({super.key});

  @override
  ConsumerState<WorkoutBrowseScreen> createState() =>
      _WorkoutBrowseScreenState();
}

class _WorkoutBrowseScreenState extends ConsumerState<WorkoutBrowseScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  var _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _searchFocus.addListener(_onFocusChanged);
  }

  void _onSearchChanged() {
    ref.read(searchQueryProvider.notifier).state = _searchCtrl.text;
  }

  void _onFocusChanged() {
    setState(() => _hasFocus = _searchFocus.hasFocus);
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _clearAll() {
    ref.read(muscleGroupFilterProvider.notifier).state = null;
    ref.read(difficultyFilterProvider.notifier).state = null;
    ref.read(searchQueryProvider.notifier).state = '';
    _searchCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            toolbarHeight: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(200),
              child: _BrowseTopBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                hasFocus: _hasFocus,
              ),
            ),
          ),
          _BrowseResults(onClearAll: _clearAll),
        ],
      ),
    );
  }
}

// ── _BrowseTopBar ─────────────────────────────────────────────────────────────

class _BrowseTopBar extends ConsumerWidget {
  const _BrowseTopBar({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    final count = ref
        .watch(filteredWorkoutsProvider)
        .whenOrNull(data: (w) => w.length);
    final countLabel = count == null ? '...' : '$count';

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse',
                      style: tt.displaySmall?.copyWith(letterSpacing: 1.0),
                    ),
                    Text(
                      '$countLabel exercises',
                      style: tt.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const _ViewToggle(),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _SearchBar(
              controller: controller,
              focusNode: focusNode,
              hasFocus: hasFocus,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Muscle group chips ───────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: _muscleFilters.map((f) {
                final selected = ref.watch(muscleGroupFilterProvider);
                final isActive = f.value == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => ref
                        .read(muscleGroupFilterProvider.notifier)
                        .state = f.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent.withValues(alpha: 0.12)
                            : AppColors.surfaceElevated,
                        borderRadius: AppRadius.circleAll,
                        border: Border.all(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.borderSubtle,
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: tt.labelLarge?.copyWith(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ── _SearchBar ────────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hasFocus,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.circleAll,
        border: Border.all(
          color: hasFocus
              ? AppColors.accent.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
          width: 1.5,
        ),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: tt.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search exercises...',
            hintStyle:
                tt.bodyMedium?.copyWith(color: AppColors.textDisabled),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: ListenableBuilder(
              listenable: controller,
              builder: (context2, w) => controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        controller.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : const SizedBox.shrink(),
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}

// ── _ViewToggle ───────────────────────────────────────────────────────────────

class _ViewToggle extends ConsumerWidget {
  const _ViewToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(browseViewModeProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewBtn(
            icon: Icons.view_list_rounded,
            active: mode == BrowseViewMode.list,
            onTap: () => ref.read(browseViewModeProvider.notifier).state =
                BrowseViewMode.list,
          ),
          _ViewBtn(
            icon: Icons.grid_view_rounded,
            active: mode == BrowseViewMode.grid,
            onTap: () => ref.read(browseViewModeProvider.notifier).state =
                BrowseViewMode.grid,
          ),
        ],
      ),
    );
  }
}

class _ViewBtn extends StatelessWidget {
  const _ViewBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppRadius.smAll,
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── _BrowseResults (sliver) ───────────────────────────────────────────────────

class _BrowseResults extends ConsumerWidget {
  const _BrowseResults({required this.onClearAll});

  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final workoutsAsync = ref.watch(filteredWorkoutsProvider);
    final viewMode = ref.watch(browseViewModeProvider);
    final muscleGroup = ref.watch(muscleGroupFilterProvider);
    final difficulty = ref.watch(difficultyFilterProvider);
    final query = ref.watch(searchQueryProvider);
    final hasFilters =
        query.isNotEmpty || muscleGroup != null || difficulty != null;

    return workoutsAsync.when(
      loading: () => _buildSkeletons(viewMode),
      error: (err, _) => SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.warning, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text('Could not load exercises', style: tt.titleMedium),
              const SizedBox(height: AppSpacing.md),
              AppGhostButton(
                label: 'Retry',
                onTap: () => ref.invalidate(filteredWorkoutsProvider),
              ),
            ],
          ),
        ),
      ),
      data: (workouts) {
        if (workouts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 48, color: AppColors.textDisabled),
                  const SizedBox(height: AppSpacing.md),
                  Text('No exercises found', style: tt.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Try a different search or filter',
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  if (hasFilters) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppGhostButton(
                        label: 'Clear filters', onTap: onClearAll),
                  ],
                ],
              ),
            ),
          );
        }

        return viewMode == BrowseViewMode.list
            ? _ListResults(workouts: workouts, hasFilters: hasFilters)
            : _GridResults(workouts: workouts);
      },
    );
  }

  Widget _buildSkeletons(BrowseViewMode viewMode) {
    if (viewMode == BrowseViewMode.list) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context2, i) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard.skeleton(height: 220),
            ),
            childCount: 4,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context2, i) => const AppCard.skeleton(height: 200),
          childCount: 4,
        ),
      ),
    );
  }
}

// ── _ListResults ──────────────────────────────────────────────────────────────

class _ListResults extends ConsumerWidget {
  const _ListResults({
    required this.workouts,
    required this.hasFilters,
  });

  final List workouts;
  final bool hasFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diff = ref.watch(difficultyFilterProvider);

    const placeholders = [
      (name: 'Lunges', muscleGroupLabel: 'Lower Body'),
      (name: 'Pull-ups', muscleGroupLabel: 'Upper Body'),
    ];
    final showPlaceholders = !hasFilters;
    final totalCount =
        workouts.length + (showPlaceholders ? placeholders.length : 0);

    return SliverMainAxisGroup(
      slivers: [
        // Difficulty filter row
        SliverToBoxAdapter(child: _DifficultyRow(diff: diff, ref: ref)),

        // Workout cards + optional placeholders
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < workouts.length) {
                  final workout = workouts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ExerciseCard(
                      workout: workout,
                      compact: false,
                      onTap: () => context
                          .go(RouteNames.workoutDetailPath(workout.id)),
                    )
                        .animate(delay: (index * 60).ms)
                        .fadeIn(duration: 280.ms)
                        .slideY(begin: 0.04, duration: 280.ms),
                  );
                }
                final p = placeholders[index - workouts.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _PlaceholderCard(
                    name: p.name,
                    muscleGroupLabel: p.muscleGroupLabel,
                  ),
                );
              },
              childCount: totalCount,
            ),
          ),
        ),
      ],
    );
  }
}

// ── _GridResults ──────────────────────────────────────────────────────────────

class _GridResults extends ConsumerWidget {
  const _GridResults({required this.workouts});

  final List workouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diff = ref.watch(difficultyFilterProvider);

    return SliverMainAxisGroup(
      slivers: [
        // Difficulty filter row
        SliverToBoxAdapter(child: _DifficultyRow(diff: diff, ref: ref)),

        // Workout grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final workout = workouts[index];
                return ExerciseCard(
                  workout: workout,
                  compact: true,
                  onTap: () =>
                      context.go(RouteNames.workoutDetailPath(workout.id)),
                )
                    .animate(delay: (index * 50).ms)
                    .fadeIn(duration: 260.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      duration: 260.ms,
                      curve: Curves.easeOut,
                    );
              },
              childCount: workouts.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── _DifficultyRow ────────────────────────────────────────────────────────────

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({required this.diff, required this.ref});

  final String? diff;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Level:',
            style: tt.labelLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppSegmentedControl(
              options: const ['All', 'Beginner', 'Intermediate', 'Advanced'],
              selectedIndex: _difficultyIndex(diff),
              onChanged: (i) => ref
                  .read(difficultyFilterProvider.notifier)
                  .state = _difficultyValues[i],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _PlaceholderCard ──────────────────────────────────────────────────────────

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.name,
    required this.muscleGroupLabel,
  });

  final String name;
  final String muscleGroupLabel;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Opacity(
      opacity: 0.4,
      child: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    name,
                    style: tt.titleLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    muscleGroupLabel,
                    style: tt.bodySmall
                        ?.copyWith(color: AppColors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: AppRadius.circleAll,
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Coming Soon',
                style: tt.labelSmall?.copyWith(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
