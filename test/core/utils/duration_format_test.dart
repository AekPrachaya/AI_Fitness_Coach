import 'package:ai_fitness_coach/core/utils/duration_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('under an hour reads as m:ss', () {
    expect(formatClock(0), '0:00');
    expect(formatClock(9), '0:09');
    expect(formatClock(65), '1:05');
    expect(formatClock(3599), '59:59');
  });

  test('an hour or more reads as h:mm:ss', () {
    expect(formatClock(3600), '1:00:00');
    expect(formatClock(3725), '1:02:05');
  });

  test('negative input reads as zero', () {
    expect(formatClock(-5), '0:00');
  });
}
