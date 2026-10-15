import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';

/// Why a session is not currently counting reps, and the one thing to tap.
enum SessionInterruption {
  /// The OS took the camera back — a call, another app, the app switcher —
  /// and it is being opened again.
  reconnecting,

  /// Reopening the camera failed. Common right after an interruption ends,
  /// while iOS still has not handed the capture device back.
  cameraFailed,

  /// Camera is live, the session is deliberately waiting for the user to get
  /// back into position.
  paused,
}

/// Shown when a session has been interrupted.
///
/// Exists because the alternative is worse than it sounds: a session whose
/// camera has been reclaimed used to render as a bare progress spinner over
/// the whole screen, which hid the pause button along with everything else.
/// Coming back from a phone call left the user looking at a screen that was
/// not doing anything and offered nothing to tap.
class SessionInterruptedOverlay extends StatelessWidget {
  const SessionInterruptedOverlay({
    super.key,
    required this.kind,
    this.onAction,
  });

  final SessionInterruption kind;

  /// Tapped by the button. Null while [SessionInterruption.reconnecting],
  /// which resolves on its own.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body, action) = switch (kind) {
      SessionInterruption.reconnecting => (
          Icons.videocam_rounded,
          'กำลังเปิดกล้องอีกครั้ง',
          'แอปถูกขัดจังหวะ รอสักครู่',
          null,
        ),
      SessionInterruption.cameraFailed => (
          Icons.videocam_off_rounded,
          'เปิดกล้องไม่ได้',
          'เกิดขึ้นได้หลังวางสายหรือสลับแอป',
          'ลองอีกครั้ง',
        ),
      SessionInterruption.paused => (
          Icons.pause_circle_filled_rounded,
          'หยุดชั่วคราว',
          'เข้าที่ให้พร้อม แล้วกดเล่นต่อ',
          'เล่นต่อ',
        ),
    };

    return Container(
      // Not opaque: for a pause the user needs to see themselves in the
      // preview to get back into position before resuming.
      color: Colors.black.withValues(alpha: 0.62),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.accent, size: 44),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (action == null)
                const CircularProgressIndicator(color: AppColors.accent)
              else
                AppPrimaryButton(
                  label: action,
                  leadingIcon: kind == SessionInterruption.paused
                      ? Icons.play_arrow_rounded
                      : Icons.refresh_rounded,
                  onTap: onAction,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
