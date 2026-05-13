import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ── Mock achievement data ─────────────────────────────────────────────────────

class _Achievement {
  final String emoji;
  final String title;
  final bool unlocked;
  const _Achievement({
    required this.emoji,
    required this.title,
    required this.unlocked,
  });
}

const _mockAchievements = [
  _Achievement(emoji: '🏃', title: 'First Rep', unlocked: true),
  _Achievement(emoji: '🔥', title: '3-Day Streak', unlocked: true),
  _Achievement(emoji: '💪', title: 'Form Master', unlocked: false),
  _Achievement(emoji: '🏆', title: '7-Day Streak', unlocked: false),
  _Achievement(emoji: '⚡', title: 'Speed Demon', unlocked: false),
];

// ── AchievementsSection ───────────────────────────────────────────────────────

class AchievementsSection extends StatelessWidget {
  const AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final unlocked =
        _mockAchievements.where((a) => a.unlocked).toList();

    if (unlocked.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('Achievements', style: tt.titleLarge),
        ),

        const SizedBox(height: AppSpacing.md),

        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            physics: const BouncingScrollPhysics(),
            itemCount: _mockAchievements.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final a = _mockAchievements[index];
              return _AchievementBadge(achievement: a)
                  .animate(delay: (index * 60).ms)
                  .fadeIn(duration: 250.ms)
                  .scale(
                    begin: const Offset(0.85, 0.85),
                    duration: 250.ms,
                    curve: Curves.easeOut,
                  );
            },
          ),
        ),
      ],
    );
  }
}

// ── _AchievementBadge ─────────────────────────────────────────────────────────

class _AchievementBadge extends StatelessWidget {
  final _Achievement achievement;
  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Opacity(
      opacity: achievement.unlocked ? 1.0 : 0.3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: achievement.unlocked
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.surfaceElevated,
              border: Border.all(
                color: achievement.unlocked
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : AppColors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          SizedBox(
            width: 64,
            child: Text(
              achievement.title,
              style: tt.labelSmall?.copyWith(
                color: achievement.unlocked
                    ? AppColors.textSecondary
                    : AppColors.textDisabled,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
