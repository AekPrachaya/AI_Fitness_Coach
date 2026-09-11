import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/app_colors.dart';
import 'preview_transform.dart';

class PoseOverlayPainter extends CustomPainter {
  PoseOverlayPainter({
    required this.poses,
    required this.absoluteImageSize,
    required this.isFrontCamera,
  });

  final List<Pose> poses;

  /// Size of the camera image in its upright (portrait) orientation.
  /// For 90°/270° rotations: Size(rawHeight, rawWidth).
  final Size absoluteImageSize;

  final bool isFrontCamera;

  static const _connections = [
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    // Same cover-fit the preview widget uses; anything else and the bones sit
    // beside the body rather than on it.
    final transform = PreviewTransform.cover(
      image: absoluteImageSize,
      canvas: size,
    );

    final bonePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    final activeDotPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      // Bones
      for (final conn in _connections) {
        final a = pose.landmarks[conn[0]];
        final b = pose.landmarks[conn[1]];
        if (a == null || b == null) continue;
        if (a.likelihood < 0.5 || b.likelihood < 0.5) continue;
        canvas.drawLine(
          transform.map(a.x, a.y),
          transform.map(b.x, b.y),
          bonePaint,
        );
      }

      // Landmark dots
      for (final lm in pose.landmarks.values) {
        if (lm.likelihood < 0.5) continue;
        final pt = transform.map(lm.x, lm.y);
        // Outer white ring
        canvas.drawCircle(pt, 6.0, dotPaint);
        // Inner accent fill
        canvas.drawCircle(pt, 4.0, activeDotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.poses != poses || old.absoluteImageSize != absoluteImageSize;
}
