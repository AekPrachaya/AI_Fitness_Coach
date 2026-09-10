import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/features/workout/session/widgets/preview_transform.dart';

void main() {
  // A 3:4 camera frame on a tall phone — the case that used to squeeze.
  const image = Size(480, 640);
  const tallPhone = Size(390, 844);

  test('scales both axes by the same factor', () {
    final t = PreviewTransform.cover(image: image, canvas: tallPhone);
    // Height is the binding axis here: 844/640 = 1.319 beats 390/480 = 0.8125.
    expect(t.scale, closeTo(844 / 640, 0.0001));
  });

  test('covers the canvas on both axes', () {
    final t = PreviewTransform.cover(image: image, canvas: tallPhone);
    expect(image.width * t.scale, greaterThanOrEqualTo(tallPhone.width));
    expect(image.height * t.scale, greaterThanOrEqualTo(tallPhone.height));
  });

  test('crops the overflow evenly, so the frame stays centred', () {
    final t = PreviewTransform.cover(image: image, canvas: tallPhone);
    final overflowX = image.width * t.scale - tallPhone.width;
    expect(t.offset.dx, closeTo(-overflowX / 2, 0.0001));
    expect(t.offset.dy, 0, reason: 'height is the binding axis, nothing to crop');
  });

  test('maps the image centre to the canvas centre', () {
    final t = PreviewTransform.cover(image: image, canvas: tallPhone);
    final centre = t.map(image.width / 2, image.height / 2);
    expect(centre.dx, closeTo(tallPhone.width / 2, 0.0001));
    expect(centre.dy, closeTo(tallPhone.height / 2, 0.0001));
  });

  test('keeps a square in the image square on screen', () {
    // The whole point: a 100x100 box must not come out as a rectangle.
    final t = PreviewTransform.cover(image: image, canvas: tallPhone);
    final a = t.map(100, 100);
    final b = t.map(200, 200);
    expect(b.dx - a.dx, closeTo(b.dy - a.dy, 0.0001));
  });

  test('crops the other axis when the canvas is the wider shape', () {
    const wide = Size(800, 400);
    final t = PreviewTransform.cover(image: image, canvas: wide);
    expect(t.scale, closeTo(800 / 480, 0.0001));
    expect(t.offset.dx, 0);
    expect(t.offset.dy, lessThan(0), reason: 'height overflows and is cropped');
  });

  test('is the identity when the shapes already match', () {
    final t = PreviewTransform.cover(image: image, canvas: image);
    expect(t.scale, 1);
    expect(t.offset, Offset.zero);
    expect(t.map(123, 456), const Offset(123, 456));
  });

  test('degrades safely before the first frame has arrived', () {
    // absoluteImageSize is Size.zero until a frame lands.
    final t = PreviewTransform.cover(image: Size.zero, canvas: tallPhone);
    expect(t.scale, 1);
    expect(t.offset, Offset.zero);
    expect(t.map(10, 20), const Offset(10, 20));
  });

  test('two transforms built the same way compare equal', () {
    expect(
      PreviewTransform.cover(image: image, canvas: tallPhone),
      PreviewTransform.cover(image: image, canvas: tallPhone),
    );
  });
}
