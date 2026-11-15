import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/core/services/form_coach.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';

void main() {
  // A fixed clock: every behaviour under test is about how long a cue lives,
  // so the tests advance time themselves instead of waiting for it.
  final t0 = DateTime(2026, 1, 1, 9, 0, 0);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  // Two posture faults, which are the ones judged frame by frame and so the
  // ones frame confirmation exists for.
  final sagging = ExerciseAnalyzer.verdict([FormFault.pushUpHipSag]);
  final piked = ExerciseAnalyzer.verdict([FormFault.pushUpHipPike]);
  // A range-of-motion fault: one measurement taken at the bottom of a rep.
  final shallow = ExerciseAnalyzer.verdict([FormFault.pushUpShallow]);
  final clean = ExerciseAnalyzer.verdict(const []);

  late FormCoach coach;
  setUp(() => coach = FormCoach(
        confirmFrames: 3,
        minHold: const Duration(milliseconds: 1500),
        repeatAfter: const Duration(seconds: 4),
      ));

  group('confirming a fault', () {
    test('says nothing until the fault has held for confirmFrames', () {
      expect(coach.update(sagging, at: at(0)), isNull);
      expect(coach.update(sagging, at: at(33)), isNull);
      final cue = coach.update(sagging, at: at(66));
      expect(cue, isNotNull);
      expect(cue!.fault, FormFault.pushUpHipSag);
      expect(cue.message, FormFault.pushUpHipSag.cue);
    });

    test('a one-frame glitch never reaches the user', () {
      // The shape of a landmark wobbling across a threshold: two bad frames
      // in a row at most, then clean again.
      for (var i = 0; i < 10; i++) {
        final result = i.isEven ? sagging : clean;
        final cue = coach.update(result, at: at(i * 33));
        expect(cue?.fault, isNull, reason: 'frame $i');
      }
    });

    test('a different fault restarts the count', () {
      coach.update(sagging, at: at(0));
      coach.update(sagging, at: at(33));
      expect(coach.update(piked, at: at(66)), isNull);
      expect(coach.update(piked, at: at(99)), isNull);
      expect(coach.update(piked, at: at(132))!.fault,
          FormFault.pushUpHipPike);
    });

    test('a range-of-motion fault is raised on its very first frame', () {
      // It only exists on the frame the rep bottomed out, so waiting for it
      // to repeat would mean never reporting depth at all.
      final cue = coach.update(shallow, at: at(0));
      expect(cue!.fault, FormFault.pushUpShallow);
      expect(cue.alert, isTrue);
    });
  });

  group('holding a cue on screen', () {
    FormCue raise(FormResult result, {int from = 0}) {
      for (var i = 0; i < 3; i++) {
        coach.update(result, at: at(from + i * 33));
      }
      return coach.cue!;
    }

    test('the frame that fixes the fault does not wipe the correction', () {
      raise(sagging);
      final cue = coach.update(clean, at: at(200));
      expect(cue!.fault, FormFault.pushUpHipSag,
          reason: 'a correction read for 0.2s was never read');
    });

    test('the cue gives way once it has been readable for minHold', () {
      raise(sagging);
      expect(coach.update(clean, at: at(1400))!.fault, isNotNull);
      final after = coach.update(clean, at: at(1600));
      expect(after!.fault, isNull);
      expect(after.message, FormResult.praise);
    });

    test('an untracked body does not cut a held cue short either', () {
      raise(sagging);
      expect(coach.update(FormResult.notEvaluated, at: at(300))!.fault,
          FormFault.pushUpHipSag);
      // Once held long enough, nothing to grade means nothing to show.
      expect(coach.update(FormResult.notEvaluated, at: at(1600)), isNull);
    });

    test('a held cue never re-alerts while it waits out minHold', () {
      raise(sagging);
      expect(coach.cue!.alert, isTrue);
      expect(coach.update(clean, at: at(200))!.alert, isFalse);
      expect(coach.update(clean, at: at(400))!.alert, isFalse);
    });
  });

  group('alerting', () {
    test('a newly raised cue alerts exactly once', () {
      for (var i = 0; i < 3; i++) {
        coach.update(sagging, at: at(i * 33));
      }
      expect(coach.cue!.alert, isTrue);
      expect(coach.update(sagging, at: at(132))!.alert, isFalse);
      expect(coach.update(sagging, at: at(165))!.alert, isFalse);
    });

    test('an uncorrected fault alerts again after repeatAfter', () {
      for (var i = 0; i < 3; i++) {
        coach.update(sagging, at: at(i * 33));
      }
      // Four seconds of the same fault, one frame every 33ms, must not buzz
      // the phone a hundred times.
      var alerts = 0;
      for (var ms = 132; ms <= 5000; ms += 33) {
        if (coach.update(sagging, at: at(ms))!.alert) alerts++;
      }
      expect(alerts, 1);
    });

    test('praise is never an alert', () {
      for (var i = 0; i < 5; i++) {
        final cue = coach.update(clean, at: at(i * 33));
        expect(cue!.alert, isFalse);
        expect(cue.score, FormScore.good);
      }
    });

    test('a risky fault carries the grade the buzz strength is picked from',
        () {
      for (var i = 0; i < 3; i++) {
        coach.update(sagging, at: at(i * 33));
      }
      expect(coach.cue!.score, FormScore.poor);

      expect(coach.update(shallow, at: at(0))!.score, FormScore.fair);
    });
  });

  group('praise', () {
    test('a clean rep is praised when nothing needs correcting', () {
      final cue = coach.update(clean, at: at(0));
      expect(cue!.message, FormResult.praise);
      expect(cue.fault, isNull);
    });

    test('an ungraded frame says nothing at all', () {
      expect(coach.update(FormResult.notEvaluated, at: at(0)), isNull);
    });
  });

  group('reset', () {
    test('drops the cue and the repeat cooldown', () {
      for (var i = 0; i < 3; i++) {
        coach.update(sagging, at: at(i * 33));
      }
      coach.reset();
      expect(coach.cue, isNull);

      // The same fault opening the next set is worth a fresh buzz, even
      // though its cooldown would not have expired.
      for (var i = 0; i < 3; i++) {
        coach.update(sagging, at: at(200 + i * 33));
      }
      expect(coach.cue!.alert, isTrue);
    });
  });

  group('FormCue', () {
    test('two renderings of the same cue are equal', () {
      const a = FormCue(message: 'x', score: FormScore.fair);
      const b = FormCue(message: 'x', score: FormScore.fair);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('silenced keeps the wording and drops only the alert', () {
      const alerting = FormCue(
        message: 'x',
        score: FormScore.poor,
        fault: FormFault.pushUpHipSag,
        alert: true,
      );
      final quiet = alerting.silenced;
      expect(quiet.alert, isFalse);
      expect(quiet.message, alerting.message);
      expect(quiet.fault, alerting.fault);
      expect(quiet.score, alerting.score);
      expect(quiet.silenced, same(quiet), reason: 'already silent');
    });
  });
}
