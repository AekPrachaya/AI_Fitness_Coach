import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Home — coming in Task 3.2',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
