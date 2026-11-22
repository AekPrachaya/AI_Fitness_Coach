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
/// within 1.3 points of the best model tried (92.7% vs 94.0%), it is twenty
/// weights per class that run as a few multiplications per frame with no
/// runtime to bundle, and each weight says which part of the pose pushed the
/// verdict — which a rule-based app's users and examiners can both follow.
abstract final class SquatFormClassifier {
  /// How confidently every joint the model reads — ear down to toe, on the
  /// side it uses — must be tracked before it is asked at all.
  ///
  /// The training images always showed the whole body: foot likelihood had a
  /// median of 0.97 and 95% of poses sat above 0.89. On the phone, with the
  /// feet slipping off the bottom of the frame at the bottom of a squat, ML
  /// Kit kept guessing them at 0.62–0.74 and the heel angle jumped from −5°
  /// to 50° between frames — and the model, never having seen feet it could
  /// not see, called flat heels lifted. 0.85 keeps 97% of the training poses
  /// and refuses guessed feet.
  static const minJointLikelihood = 0.85;

  /// Null when the pose is not tracked well enough to judge.
  static SquatFormPrediction? predict(Map<PoseLandmarkType, PoseLandmark> lms) {
    final side = FormFeatures.sideUsed(lms);
    if (side == null) return null;
    for (final t in side) {
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
