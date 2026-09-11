import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Maps a point in camera-image space onto the on-screen preview.
///
/// The preview fills the screen with [BoxFit.cover]: scaled uniformly until it
/// covers both axes, with the overflow cropped evenly on the two sides of the
/// longer one. The skeleton overlay has to use exactly this transform, or it
/// drifts off the body — the two only agree by construction, never by accident.
@immutable
class PreviewTransform {
  const PreviewTransform._(this.scale, this.offset);

  /// Builds the transform for an [image] shown cover-fitted inside [canvas].
  ///
  /// Both sizes must be in the same orientation as what is on screen: for a
  /// portrait preview, both portrait.
  factory PreviewTransform.cover({required Size image, required Size canvas}) {
    if (image.width <= 0 || image.height <= 0) {
      return const PreviewTransform._(1, Offset.zero);
    }
    final scale = math.max(
      canvas.width / image.width,
      canvas.height / image.height,
    );
    return PreviewTransform._(
      scale,
      Offset(
        (canvas.width - image.width * scale) / 2,
        (canvas.height - image.height * scale) / 2,
      ),
    );
  }

  /// Uniform scale applied to both axes — the reason the preview no longer
  /// stretches.
  final double scale;

  /// Where the scaled image sits on the canvas. Negative on the axis that
  /// overflows, which is the half being cropped.
  final Offset offset;

  Offset map(double x, double y) =>
      Offset(x * scale + offset.dx, y * scale + offset.dy);

  @override
  bool operator ==(Object other) =>
      other is PreviewTransform &&
      other.scale == scale &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(scale, offset);
}
