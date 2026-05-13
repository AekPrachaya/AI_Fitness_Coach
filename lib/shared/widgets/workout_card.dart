import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../models/models.dart';
import 'app_badge.dart';

// ── Thumbnail gradient palettes ───────────────────────────────────────────────
// Slightly brighter than ExerciseCard's gradients for the smaller 80×80 context.

List<Color> _thumbnailGradient(String muscleGroup) => switch (muscleGroup) {
      'upper_body' => [const Color(0xFF1A3D5C), const Color(0xFF0D5C3A)],
      'lower_body' => [const Color(0xFF3D1A5C), const Color(0xFF5C0D3A)],
      'full_body' => [const Color(0xFF2A4A0D), const Color(0xFF0D2A4A)],
      'core' => [const Color(0xFF4A1A0D), const Color(0xFF5C3A0D)],
      _ => [AppColors.surface, AppColors.surfaceElevated],
    };

IconData _muscleIcon(String muscleGroup) => switch (muscleGroup) {
      'upper_body' => Icons.fitness_center_rounded,
      'lower_body' => Icons.directions_run_rounded,
      'full_body' => Icons.accessibility_new_rounded,
      'core' => Icons.rotate_90_degrees_ccw_rounded,
      _ => Icons.sports_gymnastics_rounded,
    };

// ── WorkoutCard ───────────────────────────────────────────────────────────────
// Horizontal "playlist row" layout.
// Spec: "Surface color bg, 12px radius, padding 16px, subtle border"
//
// Use in: Workout Browse list mode, any future list context.
// For poster/grid use ExerciseCard instead.

class WorkoutCard extends StatefulWidget {
  const WorkoutCard({
    super.key,
    required this.workout,
    required this.onTap,
    this.showModeBadge = true,
  });

  final Workout workout;
  final VoidCallback onTap;

  /// Show the Beginner/Pro mode badge in the top-right of the content area.
  final bool showModeBadge;

  // ── Skeleton loading placeholder ──────────────────────────────────────────

  static Widget skeleton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Shimmer.fromColors(
            baseColor: AppColors.surfaceElevated,
            highlightColor: const Color(0xFF2A2A3A),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.smAll,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Content placeholder
          Expanded(
            child: Shimmer.fromColors(
              baseColor: AppColors.surfaceElevated,
              highlightColor: const Color(0xFF2A2A3A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    height: 12,
                    width: 140,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadius.smAll,
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

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  bool _isPressed = false;

  Workout get _w => widget.workout;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: thumbnail
              _Thumbnail(muscleGroup: _w.muscleGroup),

              const SizedBox(width: AppSpacing.md),

              // Center: content
              Expanded(
                child: _Content(
                  workout: _w,
                  showModeBadge: widget.showModeBadge,
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // Right: chevron
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _Thumbnail ────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.muscleGroup});

  final String muscleGroup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: AppRadius.smAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _thumbnailGradient(muscleGroup),
        ),
      ),
      child: Center(
        child: Icon(
          _muscleIcon(muscleGroup),
          size: 32,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

// ── _Content ──────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  const _Content({required this.workout, required this.showModeBadge});

  final Workout workout;
  final bool showModeBadge;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name + mode badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                workout.name,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showModeBadge) ...[
              const SizedBox(width: AppSpacing.xs),
              _ModeBadge(difficulty: workout.difficulty),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        // Description (1 line)
        Text(
          workout.description,
          style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Badges row: difficulty + timer + reps
        Row(
          children: [
            DifficultyBadge(difficulty: workout.difficulty),
            const SizedBox(width: AppSpacing.xs),
            _MetaChip(
              icon: Icons.timer_outlined,
              label: '${workout.durationMinutes} min',
            ),
            const SizedBox(width: AppSpacing.xs),
            _MetaChip(
              icon: Icons.repeat_rounded,
              label: '${workout.defaultSets}×${workout.defaultReps}',
            ),
          ],
        ),

        if (workout.muscleGroupTags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),

          // Muscle group tags (max 3)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: workout.muscleGroupTags
                .take(3)
                .map((tag) => _MuscleTag(label: tag))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ── _ModeBadge ────────────────────────────────────────────────────────────────

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.difficulty});

  final String difficulty;

  bool get _isBeginner => difficulty == 'beginner';

  Color get _color =>
      _isBeginner ? AppColors.diffBeginner : AppColors.accentBlue;

  String get _label => _isBeginner ? 'Beginner' : 'Pro';

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: AppRadius.circleAll,
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: tt.labelSmall?.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── _MetaChip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── _MuscleTag ────────────────────────────────────────────────────────────────

class _MuscleTag extends StatelessWidget {
  const _MuscleTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
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
