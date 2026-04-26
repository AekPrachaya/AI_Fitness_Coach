import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SessionScreen extends StatelessWidget {
  final String workoutId;

  const SessionScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Session: $workoutId — coming in Task 4.2',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
