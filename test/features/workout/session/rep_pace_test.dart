import 'package:ai_fitness_coach/features/workout/session/rep_pace.dart';
import 'package:ai_fitness_coach/features/workout/session/workout_session_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

final t0 = DateTime(2026, 11, 24, 9);
DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

void main() {
  late RepPace pace;

  void feed(SessionStatus status, int reps, int ms) =>
      pace.update(status: status, repCount: reps, now: at(ms));

  setUp(() => pace = RepPace());

  test('nothing to show before the first rep', () {
    feed(SessionStatus.initializing, 0, 0);
    feed(SessionStatus.tracking, 0, 100);
    expect(pace.lastRep, isNull);
  });

  test('times each rep from the one before it', () {
    feed(SessionStatus.tracking, 0, 0);
    feed(SessionStatus.repComplete, 1, 2500);
    expect(pace.lastRep, const Duration(milliseconds: 2500));

    // The 600ms flash back to tracking must not move the start mark.
    feed(SessionStatus.tracking, 1, 3100);
    feed(SessionStatus.repComplete, 2, 4300);
    expect(pace.lastRep, const Duration(milliseconds: 1800));
  });

  test('the last rep of a set is timed though it arrives with setComplete', () {
    feed(SessionStatus.tracking, 0, 0);
    feed(SessionStatus.repComplete, 1, 2000);
    feed(SessionStatus.tracking, 1, 2600);
    feed(SessionStatus.setComplete, 2, 5000);
    expect(pace.lastRep, const Duration(milliseconds: 3000));
  });

  test(
    'a new set starts blank and its first rep does not include the rest',
    () {
      feed(SessionStatus.tracking, 0, 0);
      feed(SessionStatus.setComplete, 1, 2000);
      feed(SessionStatus.resting, 1, 2900);
      feed(SessionStatus.tracking, 0, 62900); // a minute of rest later
      expect(pace.lastRep, isNull);

      feed(SessionStatus.repComplete, 1, 65000);
      expect(pace.lastRep, const Duration(milliseconds: 2100));
    },
  );

  test('time spent paused is not counted', () {
    feed(SessionStatus.tracking, 0, 0);
    feed(SessionStatus.paused, 0, 1000);
    feed(SessionStatus.tracking, 0, 31000);
    feed(SessionStatus.repComplete, 1, 33000);
    expect(pace.lastRep, const Duration(milliseconds: 2000));
  });

  test('a tracking loss restarts the clock when the body is found again', () {
    feed(SessionStatus.tracking, 0, 0);
    feed(SessionStatus.repComplete, 1, 2000);
    feed(SessionStatus.tracking, 1, 2600);
    feed(SessionStatus.error, 1, 3000);
    feed(SessionStatus.tracking, 1, 9000);
    feed(SessionStatus.repComplete, 2, 11500);
    expect(pace.lastRep, const Duration(milliseconds: 2500));
  });
}
