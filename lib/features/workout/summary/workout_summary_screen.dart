import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final String workoutId;

  const WorkoutSummaryScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Workout Summary: $workoutId — coming in Task 4.12',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
