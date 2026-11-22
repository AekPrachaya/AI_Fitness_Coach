import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/rep_tempo.dart';

void main() {
  final t0 = DateTime(2026, 11, 22, 12);
  DateTime at(double s) => t0.add(Duration(milliseconds: (s * 1000).round()));

  // Angles sampled every 0.1 s.
  void feed(TempoTracker tracker, List<num> angles, {double start = 0}) {
    for (var i = 0; i < angles.length; i++) {
      tracker.update(angles[i].toDouble(), at(start + i * 0.1));
    }
  }

  test('times a rep from leaving the top to the low point and back', () {
    final tracker = TempoTracker(top: 160);
    //        0.0  0.1  0.2  0.3  0.4  0.5  0.6  0.7  0.8
    feed(tracker, [175, 170, 150, 120, 90, 100, 130, 155, 165]);
    final tempo = tracker.takeCompleted()!;
    // Last frame above 160 is at 0.1 s, the low point at 0.4 s, back above
    // 160 at 0.8 s.
    expect(tempo.descentSeconds, closeTo(0.3, 1e-9));
    expect(tempo.ascentSeconds, closeTo(0.4, 1e-9));
  });

  test('hands each rep over once', () {
    final tracker = TempoTracker(top: 160);
    feed(tracker, [170, 120, 90, 120, 170]);
    expect(tracker.takeCompleted(), isNotNull);
    expect(tracker.takeCompleted(), isNull);
  });

  test('has nothing while the rep is still in progress', () {
    final tracker = TempoTracker(top: 160);
    feed(tracker, [170, 140, 100, 95, 120]);
    expect(tracker.takeCompleted(), isNull);
  });

  test('a rep that starts mid-descent is not timed', () {
    // The session can begin with the user already half-way down: there is no
    // honest start time, so that rep goes untimed rather than short.
    final tracker = TempoTracker(top: 160);
    feed(tracker, [130, 100, 90, 120, 170]);
    expect(tracker.takeCompleted(), isNull);
    feed(tracker, [170, 120, 90, 120, 170], start: 0.5);
    expect(tracker.takeCompleted(), isNotNull);
  });

  test('times consecutive reps independently', () {
    final tracker = TempoTracker(top: 160);
    feed(tracker, [170, 120, 90, 120, 170]);
    final first = tracker.takeCompleted()!;
    feed(tracker, [170, 150, 130, 110, 95, 90, 120, 150, 170], start: 0.5);
    final second = tracker.takeCompleted()!;
    expect(second.descentSeconds, greaterThan(first.descentSeconds));
  });

  test('reset drops the rep in progress', () {
    final tracker = TempoTracker(top: 160);
    feed(tracker, [170, 120, 90]);
    tracker.reset();
    feed(tracker, [120, 170], start: 0.3);
    expect(tracker.takeCompleted(), isNull);
  });
}
