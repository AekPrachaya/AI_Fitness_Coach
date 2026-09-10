import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Camera settings dialog — shown when camera permission is permanently denied
// and the only way back is the system settings page.
// Shared by the pre-workout and session screens.
// ─────────────────────────────────────────────────────────────────────────────

void showCameraSettingsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final tt = Theme.of(dialogContext).textTheme;

      return AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: Text('Camera Access Required', style: tt.titleLarge),
        content: Text(
          'Camera permission was denied. To track your form, please allow '
          'camera access in your device settings.',
          style: tt.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      );
    },
  );
}
