import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Builds a landmark at ([x], [y]). The default likelihood clears
/// [ExerciseAnalyzer.minLikelihood] so tests only set it when confidence
/// is what's under test.
PoseLandmark lm(
  PoseLandmarkType type,
  double x,
  double y, {
  double likelihood = 0.9,
}) =>
    PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: likelihood);

Pose poseOf(List<PoseLandmark> landmarks) =>
    Pose(landmarks: {for (final l in landmarks) l.type: l});

/// Mirrors [landmarks] onto the opposite body side so an analyzer can find a
/// complete side no matter which one it picks. Only the joints listed in
/// [_mirror] are mapped; anything else is passed through unchanged.
List<PoseLandmark> withMirroredSide(List<PoseLandmark> landmarks) => [
      ...landmarks,
      for (final l in landmarks)
        if (_mirror[l.type] case final opposite?)
          lm(opposite, l.x, l.y, likelihood: l.likelihood),
    ];

const _mirror = <PoseLandmarkType, PoseLandmarkType>{
  PoseLandmarkType.leftShoulder: PoseLandmarkType.rightShoulder,
  PoseLandmarkType.leftElbow: PoseLandmarkType.rightElbow,
  PoseLandmarkType.leftWrist: PoseLandmarkType.rightWrist,
  PoseLandmarkType.leftHip: PoseLandmarkType.rightHip,
  PoseLandmarkType.leftKnee: PoseLandmarkType.rightKnee,
  PoseLandmarkType.leftAnkle: PoseLandmarkType.rightAnkle,
};
