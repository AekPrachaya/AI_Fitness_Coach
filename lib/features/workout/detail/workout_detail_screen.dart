import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Workout Detail: $workoutId — coming in Task 3.8',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
