import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_fitness_coach/core/services/exercise_analyzer.dart';
import 'package:ai_fitness_coach/core/services/form_alerts.dart';
import 'package:ai_fitness_coach/core/services/form_coach.dart';
import 'package:ai_fitness_coach/core/services/form_fault.dart';

/// Records what it was asked to do instead of doing it.
class _RecordingAlerts implements FormAlerts {
  final List<String> calls = [];

  @override
  void raise(FormCue cue) => calls.add('raise:${cue.message}');

  @override
  void silence() => calls.add('silence');

  @override
  void dispose() => calls.add('dispose');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FormCue cueOf(FormFault fault) {
    final result = ExerciseAnalyzer.verdict([fault]);
    return FormCue(
      message: result.feedback,
      score: result.score,
      fault: fault,
      alert: true,
    );
  }

  group('CombinedFormAlerts', () {
    test('passes every call on to each channel, in order', () {
      final a = _RecordingAlerts();
      final b = _RecordingAlerts();
      final combined = CombinedFormAlerts([a, b]);

      combined.raise(cueOf(FormFault.squatShallow));
      combined.silence();
      combined.dispose();

      const expected = [
        'raise:ย่อลงอีก ให้ต้นขาขนานพื้น',
        'silence',
        'dispose',
      ];
      expect(a.calls, expected);
      expect(b.calls, expected);
    });

    test('an empty channel list is a working no-op', () {
      const combined = CombinedFormAlerts([]);
      expect(() {
        combined.raise(cueOf(FormFault.squatShallow));
        combined.silence();
        combined.dispose();
      }, returnsNormally);
    });
  });

  group('HapticFormAlerts', () {
    final buzzes = <String?>[];

    setUp(() {
      buzzes.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          buzzes.add(call.arguments as String?);
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('a risky fault buzzes harder than a sloppy one', () {
      const alerts = HapticFormAlerts();
      alerts.raise(cueOf(FormFault.squatTorsoLean)); // risky → poor
      alerts.raise(cueOf(FormFault.squatShallow)); // minor → fair
      expect(buzzes, [
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    test('praise does not buzz', () {
      const alerts = HapticFormAlerts();
      alerts.raise(const FormCue(
        message: FormResult.praise,
        score: FormScore.good,
      ));
      expect(buzzes, isEmpty);
    });
  });

  group('SilentFormAlerts', () {
    test('does nothing, loudly or otherwise', () {
      const alerts = SilentFormAlerts();
      expect(() {
        alerts.raise(cueOf(FormFault.squatTorsoLean));
        alerts.silence();
        alerts.dispose();
      }, returnsNormally);
    });
  });
}
