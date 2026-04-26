import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/mock_data.dart';
import '../../features/auth/auth_notifier.dart';
import '../../features/workout/data/workout_repository.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_card.dart';

final _workoutsProvider = FutureProvider<List<Workout>>(
  (ref) => MockData.loadWorkouts(),
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final name = auth.userName ?? 'Athlete';
    final workoutsAsync = ref.watch(_workoutsProvider);
    final repo = ref.watch(workoutRepositoryProvider);
    final recentSessions = repo.getRealSessions();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(name: name, sessionCount: recentSessions.length),
              const SizedBox(height: AppSpacing.xl),

              if (recentSessions.isNotEmpty) ...[
                _RecentSessionCard(session: recentSessions.first),
                const SizedBox(height: AppSpacing.xl),
              ],

              Text(
                'เลือกท่าออกกำลังกาย',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),

              workoutsAsync.when(
                data: (workouts) => Column(
                  children: workouts
                      .map((w) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _ExerciseCard(workout: w),
                          ))
                      .toList(),
                ),
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard.skeleton(height: 130),
                    ),
                  ),
                ),
                error: (error, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.sessionCount});

  final String name;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สวัสดี, $name', style: tt.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'พร้อมออกกำลังกายแล้วหรือยัง?',
                style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (sessionCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$sessionCount',
                  style: tt.titleLarge?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sessions',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Recent session card ───────────────────────────────────────────────────────

class _RecentSessionCard extends StatelessWidget {
  const _RecentSessionCard({required this.session});

  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final name = session['workout_name'] as String? ?? '';
    final reps = session['total_reps'] as int? ?? 0;
    final raw = session['completed_at'] as String? ?? '';
    final when = raw.isNotEmpty ? _formatDate(raw) : '';

    final exercises = session['exercises'] as List<dynamic>? ?? [];
    final sets = exercises.isNotEmpty
        ? (exercises.first as Map<dynamic, dynamic>)['sets_completed'] as int? ??
            0
        : 0;

    return AppCard(
      border: Border(
        left: BorderSide(color: AppColors.accent, width: 3),
        top: BorderSide(color: AppColors.borderSubtle),
        right: BorderSide(color: AppColors.borderSubtle),
        bottom: BorderSide(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ออกกำลังกายล่าสุด',
                  style: tt.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(name, style: tt.titleSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sets sets · $reps reps',
                style: tt.bodySmall?.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                when,
                style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
      if (diff.inHours < 24) return '${diff.inHours} ชม.ที่แล้ว';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

// ── Exercise card ─────────────────────────────────────────────────────────────

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.workout});

  final Workout workout;

  static const _activeId = 'squats';

  bool get _isActive => workout.id == _activeId;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final diffColor = AppColors.difficultyColor(workout.difficulty);
    final diffLabel = _diffLabel(workout.difficulty);

    return AppCard(
      onTap: _isActive
          ? () => context.push(RouteNames.workoutSession,
                extra: {'exerciseId': workout.id})
          : null,
      backgroundColor:
          _isActive ? null : AppColors.surface.withValues(alpha: 0.6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (_isActive ? AppColors.accent : AppColors.textSecondary)
                  .withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              _iconFor(workout.id),
              color: _isActive ? AppColors.accent : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        workout.name,
                        style: tt.titleSmall?.copyWith(
                          color: _isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _chip(diffLabel, diffColor),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${workout.defaultSets} sets × ${workout.defaultReps} reps',
                  style: tt.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: workout.muscleGroupTags
                      .take(3)
                      .map((tag) => _chip(tag, AppColors.accentBlue))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Action
          if (_isActive)
            const Icon(
              Icons.play_circle_filled_rounded,
              color: AppColors.accent,
              size: 32,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.smAll,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                'เร็วๆ นี้',
                style: tt.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _diffLabel(String d) => switch (d) {
        'beginner' => 'มือใหม่',
        'intermediate' => 'กลาง',
        'advanced' => 'ขั้นสูง',
        _ => d,
      };

  IconData _iconFor(String id) => switch (id) {
        'squats' => Icons.accessibility_new_rounded,
        'push_ups' => Icons.sports_gymnastics,
        'deadlifts' => Icons.fitness_center,
        'bicep_curls' => Icons.sports_martial_arts,
        _ => Icons.directions_run_rounded,
      };
}
