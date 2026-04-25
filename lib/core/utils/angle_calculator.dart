import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Returns the angle (degrees) at [middle], formed by the rays
/// middle→[a] and middle→[c].  Always in [0, 180].
double calculateAngle(PoseLandmark a, PoseLandmark middle, PoseLandmark c) {
  final radians = math.atan2(c.y - middle.y, c.x - middle.x) -
      math.atan2(a.y - middle.y, a.x - middle.x);
  double deg = radians.abs() * (180.0 / math.pi);
  if (deg > 180.0) deg = 360.0 - deg;
  return deg;
}
