import 'dart:ui';

import '../../core/theme/app_colors.dart';

enum PasswordStrength { empty, weak, fair, good, strong }

class PasswordStrengthCalculator {
  static PasswordStrength calculate(String password) {
    if (password.isEmpty) return PasswordStrength.empty;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    return switch (score) {
      0 || 1 => PasswordStrength.weak,
      2 => PasswordStrength.fair,
      3 => PasswordStrength.good,
      _ => PasswordStrength.strong,
    };
  }

  static String label(PasswordStrength strength) => switch (strength) {
        PasswordStrength.empty => '',
        PasswordStrength.weak => 'Weak',
        PasswordStrength.fair => 'Fair',
        PasswordStrength.good => 'Good',
        PasswordStrength.strong => 'Strong',
      };

  static Color color(PasswordStrength strength) => switch (strength) {
        PasswordStrength.empty => AppColors.surfaceElevated,
        PasswordStrength.weak => AppColors.error,
        PasswordStrength.fair => AppColors.warning,
        PasswordStrength.good => AppColors.accentBlue,
        PasswordStrength.strong => AppColors.accent,
      };

  static double value(PasswordStrength strength) => switch (strength) {
        PasswordStrength.empty => 0.0,
        PasswordStrength.weak => 0.25,
        PasswordStrength.fair => 0.50,
        PasswordStrength.good => 0.75,
        PasswordStrength.strong => 1.00,
      };
}
