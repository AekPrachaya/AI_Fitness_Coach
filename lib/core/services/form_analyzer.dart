import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

enum FormScore { good, fair, poor }

class FormResult {
  const FormResult({required this.score, required this.feedback});
  final FormScore score;
  final String feedback;
}

class FormAnalyzer {
  // Analyze only when knee is bent enough to be in squat range
  static const double _analyzeThreshold = 130.0;
  // Knee must reach below this angle for good depth
  static const double _depthThreshold = 90.0;
  // Max shin-forward angle (knee over toe)
  static const double _shinForwardMax = 40.0;
  // Max torso lean angle from vertical
  static const double _torsoLeanMax = 55.0;

  FormResult analyze(Pose pose, double kneeAngle) {
    if (kneeAngle > _analyzeThreshold) {
      return const FormResult(score: FormScore.good, feedback: '');
    }

    final lms = pose.landmarks;
    final issues = <String>[];

    // 1. Squat Depth — knee angle must go below 90°
    if (kneeAngle > _depthThreshold) {
      issues.add('ลงให้ลึกกว่านี้');
    }

    // 2. Knee Over Toe — measure shin tilt angle from vertical
    final knee = _bestLandmark(lms, PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee);
    final ankle = _bestLandmark(lms, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle);
    if (knee != null && ankle != null) {
      final dx = (knee.x - ankle.x).abs();
      final dy = (knee.y - ankle.y).abs();
      if (dy > 0) {
        final shinAngle = math.atan2(dx, dy) * 180 / math.pi;
        if (shinAngle > _shinForwardMax) {
          issues.add('เข่าเกินนิ้วเท้ามากเกินไป');
        }
      }
    }

    // 3. Back Alignment — measure torso tilt angle from vertical
    final shoulder = _bestLandmark(lms, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    final hip = _bestLandmark(lms, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    if (shoulder != null && hip != null) {
      final dx = (shoulder.x - hip.x).abs();
      final dy = (shoulder.y - hip.y).abs();
      if (dy > 0) {
        final torsoLean = math.atan2(dx, dy) * 180 / math.pi;
        if (torsoLean > _torsoLeanMax) {
          issues.add('หลังเอนไปข้างหน้ามากเกินไป');
        }
      }
    }

    if (issues.isEmpty) {
      return const FormResult(score: FormScore.good, feedback: 'ท่าดีมาก!');
    }
    if (issues.length == 1) {
      return FormResult(score: FormScore.fair, feedback: issues.first);
    }
    return FormResult(score: FormScore.poor, feedback: issues.join(' · '));
  }

  /// Pick the landmark with higher confidence between left and right sides.
  PoseLandmark? _bestLandmark(
    Map<PoseLandmarkType, PoseLandmark> lms,
    PoseLandmarkType left,
    PoseLandmarkType right,
  ) {
    final l = lms[left];
    final r = lms[right];
    if (l == null && r == null) return null;
    if (l == null) return r!.likelihood > 0.5 ? r : null;
    if (r == null) return l.likelihood > 0.5 ? l : null;
    final best = l.likelihood >= r.likelihood ? l : r;
    return best.likelihood > 0.5 ? best : null;
  }
}
