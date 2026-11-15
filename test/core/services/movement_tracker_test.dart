import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/movement_tracker.dart';

void main() {
  late MovementTracker tracker;
  setUp(() => tracker = MovementTracker(noiseFloor: 1.5));

  /// Feeds a run of angles and returns the frames that read as a turnaround.
  List<double> bottomsIn(List<double> angles) {
    final hits = <double>[];
    for (final a in angles) {
      tracker.update(a);
      if (tracker.bottomedOut) hits.add(a);
    }
    return hits;
  }

  test('knows nothing from a single frame', () {
    tracker.update(120);
    expect(tracker.phase, MovementPhase.still);
    expect(tracker.bottomedOut, isFalse);
  });

  test('reads a falling angle as a descent', () {
    bottomsIn([160, 140, 120]);
    expect(tracker.phase, MovementPhase.descending);
  });

  test('finds the bottom of a rep exactly once', () {
    // One squat: down to 85, back up to 165.
    final hits = bottomsIn([160, 140, 110, 85, 100, 130, 165]);
    expect(hits, [100], reason: 'the first frame of the ascent');
    expect(tracker.phase, MovementPhase.ascending);
  });

  test('finds one bottom per rep across several reps', () {
    final hits = bottomsIn([
      160, 120, 85, 120, 160, // rep 1
      160, 120, 80, 120, 160, // rep 2
      160, 110, 90, 140, 165, // rep 3
    ]);
    expect(hits, hasLength(3));
  });

  test('a pause at the bottom does not read as a turnaround', () {
    // The user holds the bottom position while the landmarks wobble by a
    // degree. Without a noise floor every wobble would look like a new rep
    // bottoming out, and depth would be reported over and over.
    final hits = bottomsIn([140, 100, 85, 85.6, 84.8, 85.4, 84.9, 85.5]);
    expect(hits, isEmpty);
    expect(tracker.phase, MovementPhase.descending);
  });

  test('a slow ascent still registers once it clears the noise floor', () {
    // Half a degree per frame: each step is under the floor, but the drift
    // accumulates against the last committed angle rather than being lost.
    final hits = bottomsIn([140, 100, 85, 85.5, 86.0, 86.5, 87.0]);
    expect(hits, hasLength(1));
    expect(tracker.phase, MovementPhase.ascending);
  });

  test('an ascent with no descent before it is not a bottom', () {
    // Standing up from a chair at the start of a set: the angle only ever
    // opens, so there is no rep to judge the depth of.
    expect(bottomsIn([90, 120, 150, 175]), isEmpty);
    expect(tracker.phase, MovementPhase.ascending);
  });

  test('bottomedOut lasts exactly one frame', () {
    bottomsIn([140, 100, 85]);
    tracker.update(110);
    expect(tracker.bottomedOut, isTrue);
    tracker.update(140);
    expect(tracker.bottomedOut, isFalse);
  });

  test('reset forgets the direction, so no phantom rep spans the gap', () {
    // The body left the frame mid-descent. When it comes back the first
    // upward reading must not be mistaken for the bottom of a rep that the
    // tracker never actually watched.
    bottomsIn([160, 120, 85]);
    tracker.reset();
    expect(tracker.phase, MovementPhase.still);
    expect(bottomsIn([120, 160]), isEmpty);
  });
}
