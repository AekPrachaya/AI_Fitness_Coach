import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PreWorkoutScreen extends StatelessWidget {
  final String workoutId;

  const PreWorkoutScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Pre-Workout: $workoutId — coming in Task 4.1',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
