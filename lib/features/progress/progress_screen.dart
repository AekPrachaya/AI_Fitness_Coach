import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Progress — coming in Task 5.1',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
