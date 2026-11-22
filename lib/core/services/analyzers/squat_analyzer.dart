import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../exercise_analyzer.dart';
import '../form_fault.dart';
import '../form_model/squat_form_classifier.dart';

class SquatAnalyzer extends ExerciseAnalyzer {
  /// [useFormModel] picks how posture is judged. Depth is a rule either way.
  ///
  /// * true — the trained form model (SquatFormClassifier) judges the back
  ///   and the heels. On held-out people it caught 85% of bad-back and 100%
  ///   of heel-lift images at [modelConfidence], where the rules below caught
  ///   47% and 53%; the app had no heel check of its own.
  /// * false — the original angle rules: torso lean and knee-over-toe.
  ///
  /// Defaults to the `FORM_MODEL` dart-define (on unless set to false), so
  /// the two can be compared on the phone without a code change:
  /// `flutter run --dart-define=FORM_MODEL=false`.
  SquatAnalyzer({bool? useFormModel})
      : useFormModel = useFormModel ??
            const bool.fromEnvironment('FORM_MODEL', defaultValue: true);

  final bool useFormModel;

  @override PoseLandmarkType get primaryA => PoseLandmarkType.leftHip;
  @override PoseLandmarkType get primaryB => PoseLandmarkType.leftKnee;
  @override PoseLandmarkType get primaryC => PoseLandmarkType.leftAnkle;
  @override PoseLandmarkType get altA     => PoseLandmarkType.rightHip;
  @override PoseLandmarkType get altB     => PoseLandmarkType.rightKnee;
  @override PoseLandmarkType get altC     => PoseLandmarkType.rightAnkle;

  // A thighs-parallel squat filmed side-on bottoms out at 98–105° in 2D, so
  // 100 (92 after hysteresis) missed most real reps: 41.9% → 79.0% on 62
  // recorded reps. Depth is still graded separately by _depthThreshold.
  @override double get downThreshold => 125.0;
  @override double get upThreshold   => 160.0;
  @override String get angleLabel    => 'เข่า (องศา)';
  @override double get met         => 5.0; // bodyweight squats, vigorous effort

  static const _analyzeThreshold = 130.0;
  static const _depthThreshold   = 90.0;
  // Lifted heels pitch the knees forward, so this also catches them. Labelled
  // still images suggested 35°, but on the phone ML Kit reads the shin of a
  // very deep squat (knee at 32–48°) past 35° with the heels down, and at 40°
  // it still flagged all three heel-lift reps of a recorded test while
  // warning on one deep normal rep in three. 40 until more footage settles it.
  static const _shinForwardMax   = 40.0;
  static const _torsoLeanMax     = 55.0;

  /// How sure the model must be before a fault is raised. At 0.5 it warned
  /// on 12.6% of good-form test images; at 0.8, 8.7%, still catching 85% of
  /// bad backs and every lifted heel. FormCoach's three-frame confirmation
  /// filters further on top.
  static const modelConfidence = 0.8;

  @override
  FormResult analyze(Pose pose, double angle) {
    if (angle > _analyzeThreshold) {
      return FormResult.notEvaluated;
    }

    final faults = <FormFault>[
      if (angle > _depthThreshold) FormFault.squatShallow,
      ...useFormModel ? _modelFaults(pose) : _ruleFaults(pose),
    ];
    return ExerciseAnalyzer.verdict(faults);
  }

  /// The model's verdict when it can see the whole leg, else the rules'.
  ///
  /// Feet out of frame are common — a phone propped close, a deep squat
  /// pushing the toes off the bottom edge — and the rules need only the
  /// shoulder, hip, knee and ankle, so they still say something useful.
  List<FormFault> _modelFaults(Pose pose) {
    final p = SquatFormClassifier.predict(pose.landmarks);
    if (p == null) return _ruleFaults(pose);
    return [
      if (p.probabilityOf(SquatFormClass.badBack) > modelConfidence)
        FormFault.squatTorsoLean,
      if (p.probabilityOf(SquatFormClass.badHeel) > modelConfidence)
        FormFault.squatHeelLift,
    ];
  }

  List<FormFault> _ruleFaults(Pose pose) {
    final lms = pose.landmarks;
    final faults = <FormFault>[];

    // Knee over toe
    final leg = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      const [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    );
    if (leg case [final knee, final ankle]) {
      final dx = (knee.x - ankle.x).abs();
      final dy = (knee.y - ankle.y).abs();
      if (dy > 0 && math.atan2(dx, dy) * 180 / math.pi > _shinForwardMax) {
        faults.add(FormFault.squatKneeOverToe);
      }
    }

    // Torso lean
    final torso = ExerciseAnalyzer.bestSide(
      lms,
      const [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      const [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    );
    if (torso case [final shoulder, final hip]) {
      final dx = (shoulder.x - hip.x).abs();
      final dy = (shoulder.y - hip.y).abs();
      if (dy > 0 && math.atan2(dx, dy) * 180 / math.pi > _torsoLeanMax) {
        faults.add(FormFault.squatTorsoLean);
      }
    }

    return faults;
  }
}
