import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/models.dart';
import 'app_badge.dart';

// Exercise card gradient palettes — exercise-specific, not in AppColors.
const _kUpperBodyColors = [Color(0xFF0D2B45), Color(0xFF0A4A36)];
const _kLowerBodyColors = [Color(0xFF250D4A), Color(0xFF3A0A4A)];
const _kFullBodyColors  = [Color(0xFF1A350A), Color(0xFF0A1A35)];
const _kCoreColors      = [Color(0xFF2A0A0A), Color(0xFF3A200A)];

// ── ExerciseCard ──────────────────────────────────────────────────────────────
// Shared card used in: Home Recommended row (compact), Workout Browse (full).
//
//  compact=true  → 160 × 200px  (horizontal scroll)
//  compact=false → full width × 220px  (grid / list)

class ExerciseCard extends StatefulWidget {
  const ExerciseCard({
    super.key,
    required this.workout,
    required this.onTap,
    this.compact = false,
  });

  final Workout workout;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _isPressed = false;

  List<Color> get _gradientColors {
    switch (widget.workout.muscleGroup) {
      case 'upper_body':
        return _kUpperBodyColors;
      case 'lower_body':
        return _kLowerBodyColors;
      case 'full_body':
        return _kFullBodyColors;
      case 'core':
        return _kCoreColors;
      default:
        return [AppColors.surface, AppColors.surfaceElevated];
    }
  }

  IconData get _muscleIcon {
    switch (widget.workout.muscleGroup) {
      case 'upper_body':
        return Icons.fitness_center_rounded;
      case 'lower_body':
        return Icons.directions_run_rounded;
      case 'full_body':
        return Icons.accessibility_new_rounded;
      case 'core':
        return Icons.rotate_90_degrees_ccw_rounded;
      default:
        return Icons.sports_gymnastics_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final height = widget.compact ? 200.0 : 220.0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1 — Gradient background + icon
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _gradientColors,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _muscleIcon,
                      size: widget.compact ? 48 : 64,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),

                // Layer 2 — Bottom fade overlay for text legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.4, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),

                // Layer 3 — Name + badges pinned to bottom
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.workout.name,
                        style: (widget.compact
                                ? tt.titleMedium
                                : tt.titleLarge)
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Metadata row — FittedBox prevents overflow when
                      // badge text (e.g. "Intermediate") is wide on small cards.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DifficultyBadge(
                              difficulty: widget.workout.difficulty,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            _MetaChip(
                              icon: Icons.timer_outlined,
                              label: '${widget.workout.durationMinutes}m',
                            ),
                            if (!widget.compact &&
                                widget.workout.muscleGroupTags.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.xs),
                              _MetaChip(
                                icon: Icons.label_outline_rounded,
                                label: widget.workout.muscleGroupTags
                                    .take(2)
                                    .join(', '),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── _MetaChip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: AppRadius.circleAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 3),
          Text(
            label,
            style: tt.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
