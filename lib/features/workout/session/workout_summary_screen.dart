import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/workout_repository.dart';

class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.setsCompleted,
    required this.targetSets,
    required this.totalReps,
    required this.exerciseName,
  });

  final int setsCompleted;
  final int targetSets;
  final int totalReps;
  final String exerciseName;

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
    final exerciseId =
        widget.exerciseName.toLowerCase().replaceAll(' ', '_');
    repo.saveSession({
      'id': id,
      'workout_id': exerciseId,
      'workout_name': widget.exerciseName,
      'completed_at': DateTime.now().toIso8601String(),
      'duration_seconds': 0,
      'total_reps': widget.totalReps,
      'avg_form_score': 0.0,
      'estimated_calories': 0,
      'most_common_error': '',
      'ai_tip': '',
      'exercises': [
        {
          'exercise_id': exerciseId,
          'exercise_name': widget.exerciseName,
          'sets_completed': widget.setsCompleted,
          'total_reps': widget.totalReps,
          'avg_form_score': 0.0,
          'most_common_error': '',
        }
      ],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.exerciseName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accent,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statItem(
                      context,
                      'Set สำเร็จ',
                      '${widget.setsCompleted}/${widget.targetSets}',
                    ),
                    Container(width: 1, height: 52, color: AppColors.divider),
                    _statItem(
                      context,
                      'Rep ทั้งหมด',
                      '${widget.totalReps}',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'กลับหน้าหลัก',
                onTap: () => context.go(RouteNames.home),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
