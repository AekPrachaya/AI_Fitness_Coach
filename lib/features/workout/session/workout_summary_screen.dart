import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/exercise_analyzer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/workout_repository.dart';
import 'session_stats.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
    required this.setsCompleted,
    required this.targetSets,
    required this.totalReps,
    this.durationSeconds = 0,
    this.avgFormScore = 0,
    this.mostCommonError = '',
  });

  final String exerciseId;
  final String exerciseName;
  final int setsCompleted;
  final int targetSets;
  final int totalReps;
  final int durationSeconds;
  final double avgFormScore;
  final String mostCommonError;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  @override
  void initState() {
    super.initState();
    _persistSession();
  }

  void _persistSession() {
    final repo = ref.read(workoutRepositoryProvider);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final exerciseId = widget.exerciseId;

    repo.saveSession({
      'id': id,
      'workout_id': exerciseId,
      'workout_name': widget.exerciseName,
      'completed_at': DateTime.now().toIso8601String(),
      'duration_seconds': widget.durationSeconds,
      'total_reps': widget.totalReps,
      'avg_form_score': widget.avgFormScore,
      'estimated_calories': _estimatedCalories,
      'most_common_error': widget.mostCommonError,
      // Left to the AI backend; no coaching text is generated on-device.
      'ai_tip': '',
      'exercises': [
        {
          'exercise_id': exerciseId,
          'exercise_name': widget.exerciseName,
          'sets_completed': widget.setsCompleted,
          'total_reps': widget.totalReps,
          'avg_form_score': widget.avgFormScore,
          'most_common_error': widget.mostCommonError,
        },
      ],
    });
  }

  int get _estimatedCalories => SessionStats.estimateCalories(
    met: ExerciseAnalyzer.forId(widget.exerciseId).met,
    weightKg: ref.read(userProfileProvider).weightKg,
    durationSeconds: widget.durationSeconds,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.accent,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'ออกกำลังกายเสร็จสิ้น!',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.exerciseName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.accent),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _statPanel(context),
                      if (widget.mostCommonError.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        _mostCommonErrorCard(context),
                      ],
                      const Spacer(),
                      AppPrimaryButton(
                        label: 'กลับหน้าหลัก',
                        onTap: () => context.go(RouteNames.home),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(
                context,
                'Set สำเร็จ',
                '${widget.setsCompleted}/${widget.targetSets}',
              ),
              Container(width: 1, height: 52, color: AppColors.divider),
              _statItem(context, 'Rep ทั้งหมด', '${widget.totalReps}'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem(
                context,
                'ฟอร์มเฉลี่ย',
                widget.avgFormScore > 0
                    ? '${widget.avgFormScore.toStringAsFixed(0)}%'
                    : '--',
                valueColor: widget.avgFormScore > 0
                    ? AppColors.formScoreColor(widget.avgFormScore)
                    : AppColors.textSecondary,
                small: true,
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              _statItem(
                context,
                'เวลา',
                _formatDuration(widget.durationSeconds),
                small: true,
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              _statItem(context, 'แคลอรี่', '$_estimatedCalories', small: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mostCommonErrorCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.scoreOk.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.scoreOk.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tips_and_updates_rounded,
            color: AppColors.scoreOk,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สิ่งที่ควรแก้บ่อยที่สุด',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.mostCommonError,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.scoreOk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// mm:ss, or h:mm:ss once the session passes an hour.
  static String _formatDuration(int seconds) {
    if (seconds <= 0) return '--';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final mm = minutes.toString().padLeft(hours > 0 ? 2 : 1, '0');
    return hours > 0
        ? '$hours:$mm:${secs.toString().padLeft(2, '0')}'
        : '$mm:${secs.toString().padLeft(2, '0')}';
  }

  Widget _statItem(
    BuildContext context,
    String label,
    String value, {
    Color valueColor = AppColors.accent,
    bool small = false,
  }) {
    final tt = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: (small ? tt.titleLarge : tt.headlineLarge)?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
