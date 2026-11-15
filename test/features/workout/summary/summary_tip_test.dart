import 'package:ai_fitness_coach/core/services/form_fault.dart';
import 'package:ai_fitness_coach/features/workout/summary/summary_tip.dart';
import 'package:ai_fitness_coach/shared/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';

SessionData _session({
  String workoutId = 'squats',
  double avgFormScore = 80,
  String mostCommonError = '',
  String aiTip = '',
}) =>
    SessionData(
      id: 's1',
      workoutId: workoutId,
      workoutName: 'Squats',
      completedAt: DateTime(2026, 11, 15, 9),
      durationSeconds: 300,
      totalReps: 30,
      avgFormScore: avgFormScore,
      estimatedCalories: 40,
      mostCommonError: mostCommonError,
      exercises: const [],
      aiTip: aiTip,
    );

void main() {
  test('a tip stored with the session wins over everything else', () {
    final tip = summaryTipFor(_session(
      aiTip: 'Stored tip',
      mostCommonError: FormFault.squatKneeOverToe.label,
    ));
    expect(tip.message, 'Stored tip');
    expect(tip.focus, isNull);
  });

  test('the most common fault turns into its correction cue', () {
    final tip = summaryTipFor(
      _session(mostCommonError: FormFault.squatKneeOverToe.label),
    );
    expect(tip.focus, FormFault.squatKneeOverToe.label);
    expect(tip.message, FormFault.squatKneeOverToe.cue);
  });

  test('a label shared by two exercises resolves to the right one', () {
    // 'ลงไม่ลึกพอ' is both a squat and a push-up fault, with different cues.
    expect(FormFault.squatShallow.label, FormFault.pushUpShallow.label);

    final squat = summaryTipFor(_session(
      workoutId: 'squats',
      mostCommonError: FormFault.squatShallow.label,
    ));
    final pushUp = summaryTipFor(_session(
      workoutId: 'push_ups',
      mostCommonError: FormFault.pushUpShallow.label,
    ));

    expect(squat.message, FormFault.squatShallow.cue);
    expect(pushUp.message, FormFault.pushUpShallow.cue);
  });

  test('a fault from an unknown workout still gets a cue', () {
    final tip = summaryTipFor(_session(
      workoutId: 'lunges',
      mostCommonError: FormFault.curlBodySway.label,
    ));
    expect(tip.message, FormFault.curlBodySway.cue);
  });

  test('fault text the analyzers never produce falls back to the score', () {
    // The seeded demo history uses English placeholder text.
    final tip = summaryTipFor(
      _session(mostCommonError: 'Keep knees aligned', avgFormScore: 90),
    );
    expect(tip.focus, isNull);
    expect(tip.message, summaryTipFor(_session(avgFormScore: 90)).message);
  });

  test('each score tier, including ungraded, has its own line', () {
    final messages = [0.0, 50.0, 75.0, 90.0]
        .map((score) => summaryTipFor(_session(avgFormScore: score)).message)
        .toList();

    expect(messages.every((m) => m.isNotEmpty), isTrue);
    expect(messages.toSet().length, messages.length);
  });

  test('tier boundaries follow the form score badge (70 and 85)', () {
    String line(double score) =>
        summaryTipFor(_session(avgFormScore: score)).message;

    expect(line(69.9), isNot(line(70)));
    expect(line(70), line(84.9));
    expect(line(84.9), isNot(line(85)));
    expect(line(85), line(100));
  });
}
