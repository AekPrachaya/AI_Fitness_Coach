import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Profile — coming in Task 5.5',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
}
