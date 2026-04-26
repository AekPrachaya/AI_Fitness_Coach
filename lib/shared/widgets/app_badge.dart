import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FeedbackLevel
// Used by PoseFeedbackToast and the session screen's mock feedback system.
// ─────────────────────────────────────────────────────────────────────────────

enum FeedbackLevel { good, warning, error }

extension FeedbackLevelX on FeedbackLevel {
  Color get color => switch (this) {
        FeedbackLevel.good => AppColors.accent,
        FeedbackLevel.warning => AppColors.warning,
        FeedbackLevel.error => AppColors.error,
      };

  String get icon => switch (this) {
        FeedbackLevel.good => '✅',
        FeedbackLevel.warning => '⚠️',
        FeedbackLevel.error => '❌',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// FormScoreBadge
// Spec: Pill chip — Green(≥85%) | Amber(70–84%) | Red(<70%)
// ─────────────────────────────────────────────────────────────────────────────

class FormScoreBadge extends StatelessWidget {
  const FormScoreBadge({
    super.key,
    required this.score,
    this.showLabel = true,
    this.fontSize = 11.0,
  });

  final double score;
  final bool showLabel;
  final double fontSize;

  String get _tierLabel {
    if (score >= 85) return 'Good';
    if (score >= 70) return 'Fair';
    return 'Poor';
  }

  String get _displayText =>
      showLabel ? '$_tierLabel · ${score.toInt()}%' : '${score.toInt()}%';

  @override
  Widget build(BuildContext context) {
    final color = AppColors.formScoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.circleAll,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        _displayText,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontSize: fontSize,
            ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DifficultyBadge
// Spec: Color coded — Green(Beginner) | Blue(Intermediate) | Orange(Advanced)
// ─────────────────────────────────────────────────────────────────────────────

class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({
    super.key,
    required this.difficulty,
  });

  final String difficulty;

  String get _label {
    final d = difficulty.toLowerCase();
    if (d.isEmpty) return difficulty;
    return d[0].toUpperCase() + d.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.difficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StreakBadge
// Spec: Fire emoji + number, amber tint pill
// ─────────────────────────────────────────────────────────────────────────────

class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    required this.streakCount,
    this.compact = false,
  });

  final int streakCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    if (streakCount == 0) {
      return Text(
        'Start your streak!',
        style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: AppRadius.circleAll,
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$streakCount',
            style: tt.labelLarge?.copyWith(color: AppColors.warning),
          ),
          if (!compact)
            Text(
              ' days',
              style: tt.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PoseFeedbackToast
//
// Self-dismissing overlay toast for real-time pose feedback.
// Slides up from the bottom over 200ms, stays 3s, then slides back down.
//
// Usage — call the static show() method from any screen with an Overlay:
//
//   PoseFeedbackToast.show(
//     context,
//     message: 'Good Form!',
//     level: FeedbackLevel.good,
//   );
//
// The Overlay system places the toast above the camera preview during sessions.
// IgnorePointer ensures the transparent overlay area never blocks touches.
// ─────────────────────────────────────────────────────────────────────────────

class PoseFeedbackToast extends StatefulWidget {
  const PoseFeedbackToast({
    super.key,
    required this.message,
    required this.level,
    this.onDismiss,
  });

  final String message;
  final FeedbackLevel level;
  final VoidCallback? onDismiss;

  static void show(
    BuildContext context, {
    required String message,
    required FeedbackLevel level,
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => PoseFeedbackToast(
        message: message,
        level: level,
        onDismiss: () {
          entry.remove();
          onDismiss?.call();
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<PoseFeedbackToast> createState() => _PoseFeedbackToastState();
}

class _PoseFeedbackToastState extends State<PoseFeedbackToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 3000), _dismiss);
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = widget.level.color;

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: AppSpacing.xl,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: AppColors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: AppRadius.circleAll,
                      border: Border.all(
                        color: color.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.level.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          widget.message,
                          style: tt.titleMedium?.copyWith(color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppProgressBar
// Spec: Thin (4px), rounded, accent fill, surface bg track
// ─────────────────────────────────────────────────────────────────────────────

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 4.0,
    this.fillColor,
    this.trackColor,
    this.animated = true,
  });

  final double value;
  final double height;
  final Color? fillColor;
  final Color? trackColor;
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final resolvedFill = fillColor ?? AppColors.accent;
    final resolvedTrack = trackColor ?? AppColors.surfaceElevated;
    final clampedValue = value.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fillWidth = constraints.maxWidth * clampedValue;
        return ClipRRect(
          borderRadius: AppRadius.circleAll,
          child: Container(
            width: constraints.maxWidth,
            height: height,
            color: resolvedTrack,
            child: Align(
              alignment: Alignment.centerLeft,
              child: animated
                  ? AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: fillWidth,
                      height: height,
                      color: resolvedFill,
                    )
                  : Container(
                      width: fillWidth,
                      height: height,
                      color: resolvedFill,
                    ),
            ),
          ),
        );
      },
    );
  }
}
