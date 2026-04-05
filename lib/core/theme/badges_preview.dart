import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import '../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BadgesPreview
// Visual test screen for Task 1.7 badge and status widgets.
// Route: /badges-preview
// ─────────────────────────────────────────────────────────────────────────────

class BadgesPreview extends StatefulWidget {
  const BadgesPreview({super.key});

  @override
  State<BadgesPreview> createState() => _BadgesPreviewState();
}

class _BadgesPreviewState extends State<BadgesPreview> {
  double _progressValue = 0.65;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Badges Preview',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── FormScoreBadge ──────────────────────────────────────────────
            _SectionHeader('FormScoreBadge'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: const [
                FormScoreBadge(score: 94),
                FormScoreBadge(score: 76),
                FormScoreBadge(score: 55),
                FormScoreBadge(score: 88, showLabel: false),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── DifficultyBadge ─────────────────────────────────────────────
            _SectionHeader('DifficultyBadge'),
            const SizedBox(height: AppSpacing.sm),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                DifficultyBadge(difficulty: 'beginner'),
                DifficultyBadge(difficulty: 'intermediate'),
                DifficultyBadge(difficulty: 'advanced'),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── StreakBadge ─────────────────────────────────────────────────
            _SectionHeader('StreakBadge'),
            const SizedBox(height: AppSpacing.sm),
            const Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StreakBadge(streakCount: 7),
                StreakBadge(streakCount: 21, compact: true),
                StreakBadge(streakCount: 0),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── AppProgressBar ──────────────────────────────────────────────
            _SectionHeader('AppProgressBar'),
            const SizedBox(height: AppSpacing.sm),
            const AppProgressBar(value: 1.0),
            const SizedBox(height: AppSpacing.sm),
            const AppProgressBar(value: 0.65),
            const SizedBox(height: AppSpacing.sm),
            const AppProgressBar(value: 0.0),
            const SizedBox(height: AppSpacing.sm),

            // Interactive slider to test animated value change
            Row(
              children: [
                Text(
                  'Drag to animate:',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Slider(
                    value: _progressValue,
                    onChanged: (v) => setState(() => _progressValue = v),
                    activeColor: AppColors.accent,
                    inactiveColor: AppColors.surfaceElevated,
                  ),
                ),
              ],
            ),
            AppProgressBar(value: _progressValue),

            const SizedBox(height: AppSpacing.xl),

            // ── PoseFeedbackToast ───────────────────────────────────────────
            _SectionHeader('PoseFeedbackToast (triggered)'),
            const SizedBox(height: AppSpacing.sm),
            _ToastButtons(),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// Stateful child so buttons have a valid BuildContext with Overlay ancestor.
class _ToastButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _ToastButton(
          label: 'Good Toast',
          level: FeedbackLevel.good,
          message: 'Good Form!',
          context: context,
        ),
        _ToastButton(
          label: 'Warning Toast',
          level: FeedbackLevel.warning,
          message: 'Keep knees aligned',
          context: context,
        ),
        _ToastButton(
          label: 'Error Toast',
          level: FeedbackLevel.error,
          message: 'Back too curved',
          context: context,
        ),
      ],
    );
  }
}

class _ToastButton extends StatelessWidget {
  const _ToastButton({
    required this.label,
    required this.level,
    required this.message,
    required this.context,
  });

  final String label;
  final FeedbackLevel level;
  final String message;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final color = level.color;
    return GestureDetector(
      onTap: () => PoseFeedbackToast.show(
        context,
        message: message,
        level: level,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.smAll,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Text(
          'Show $label',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionHeader — internal helper, not exported
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(color: AppColors.accent),
    );
  }
}
