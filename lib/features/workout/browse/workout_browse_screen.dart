import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WorkoutBrowseScreen extends StatelessWidget {
  const WorkoutBrowseScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Workout Browse — coming in Task 3.6',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
