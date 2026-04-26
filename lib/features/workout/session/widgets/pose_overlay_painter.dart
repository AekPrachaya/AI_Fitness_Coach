import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../../core/theme/app_colors.dart';

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

    final scaleX = size.width / absoluteImageSize.width;
    final scaleY = size.height / absoluteImageSize.height;

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
          _point(a, scaleX, scaleY, size.width),
          _point(b, scaleX, scaleY, size.width),
          bonePaint,
        );
      }

      // Landmark dots
      for (final lm in pose.landmarks.values) {
        if (lm.likelihood < 0.5) continue;
        final pt = _point(lm, scaleX, scaleY, size.width);
        // Outer white ring
        canvas.drawCircle(pt, 6.0, dotPaint);
        // Inner accent fill
        canvas.drawCircle(pt, 4.0, activeDotPaint);
      }
    }
  }

  Offset _point(PoseLandmark lm, double sx, double sy, double canvasWidth) {
    return Offset(lm.x * sx, lm.y * sy);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.poses != poses || old.absoluteImageSize != absoluteImageSize;
}
