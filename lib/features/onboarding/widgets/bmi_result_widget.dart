import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BmiResultWidget
// Shows the calculated BMI score and category in an AppCard.
// ─────────────────────────────────────────────────────────────────────────────

class BmiResultWidget extends StatelessWidget {
  const BmiResultWidget({
    super.key,
    required this.bmi,
    required this.category,
  });

  final double bmi;
  final String category; // 'Underweight' | 'Normal' | 'Overweight' | 'Obese'

  Color _bmiColor() {
    switch (category) {
      case 'Underweight':
        return AppColors.accentBlue;
      case 'Normal':
        return AppColors.accent;
      case 'Overweight':
        return AppColors.warning;
      case 'Obese':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _advice() {
    switch (category) {
      case 'Underweight':
        return 'Consider building lean muscle';
      case 'Normal':
        return 'Great! Maintain with regular exercise';
      case 'Overweight':
        return 'Cardio + strength training recommended';
      case 'Obese':
        return 'Start with low-impact exercises';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = _bmiColor();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // ── Left: BMI value ───────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('BMI', style: tt.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                bmi.toStringAsFixed(1),
                style: tt.displaySmall?.copyWith(color: color),
              ),
            ],
          ),
          const Spacer(),
          // ── Right: Category + advice ──────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category,
                style: tt.titleMedium?.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _advice(),
                style: tt.bodySmall,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
