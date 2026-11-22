import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'form_features.dart';
import 'squat_form_model.g.dart';

/// What the squat form model makes of one pose.
enum SquatFormClass { good, badBack, badHeel }

class SquatFormPrediction {
  const SquatFormPrediction(this.probabilities);

  /// One probability per [SquatFormClass], in enum order, summing to 1.
  final List<double> probabilities;

  SquatFormClass get best {
    var i = 0;
    for (var j = 1; j < probabilities.length; j++) {
      if (probabilities[j] > probabilities[i]) i = j;
    }
    return SquatFormClass.values[i];
  }

  double probabilityOf(SquatFormClass c) => probabilities[c.index];
}

/// A multinomial logistic regression over [FormFeatures], trained offline on
/// labelled squat images by `tool/pose_eval/train_form_classifier.py`.
///
/// Logistic rather than a forest or a network: on held-out people it scored
/// within 1.2 points of the best model tried (94.5% vs 95.7%), it is fourteen
/// weights per class that run as a few multiplications per frame with no
/// runtime to bundle, and each weight says which part of the pose pushed the
/// verdict — which a rule-based app's users and examiners can both follow.
abstract final class SquatFormClassifier {
  /// How confidently every joint the model reads — nose, then ear down to
  /// ankle on the side it uses — must be tracked before it is asked at all.
  ///
  /// The training images showed whole bodies, tracked at likelihoods mostly
  /// above 0.89. Joints ML Kit is only guessing at, like feet slipping out of
  /// frame at 0.62–0.74 in one phone test, give positions that jump between
  /// frames, and a model fed those says nothing worth hearing. 0.85 keeps
  /// 97% of the training poses.
  static const minJointLikelihood = 0.85;

  /// Null when the pose is not tracked well enough to judge.
  static SquatFormPrediction? predict(Map<PoseLandmarkType, PoseLandmark> lms) {
    final joints = FormFeatures.jointsUsed(lms);
    if (joints == null) return null;
    for (final t in joints) {
      if ((lms[t]?.likelihood ?? 0) < minJointLikelihood) return null;
    }
    final x = FormFeatures.of(lms);
    return x == null ? null : fromFeatures(x);
  }

  static SquatFormPrediction fromFeatures(List<double> x) {
    assert(x.length == SquatFormModel.mean.length);
    final z = [
      for (var c = 0; c < SquatFormModel.coef.length; c++)
        SquatFormModel.intercept[c] +
            [
              for (var i = 0; i < x.length; i++)
                SquatFormModel.coef[c][i] *
                    (x[i] - SquatFormModel.mean[i]) /
                    SquatFormModel.scale[i],
            ].fold(0.0, (a, b) => a + b),
    ];
    final top = z.reduce(math.max);
    final e = [for (final v in z) math.exp(v - top)];
    final sum = e.fold(0.0, (a, b) => a + b);
    return SquatFormPrediction([for (final v in e) v / sum]);
  }
}
