import 'dart:convert';

import 'package:ai_fitness_coach/shared/models/session_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stored session row. Pass `aiTip: null` to leave the key out entirely.
Map<String, dynamic> _row({Object? aiTip = 'Keep your chest up'}) {
  final row = <String, dynamic>{
    'id': 'x',
    'workout_id': 'squats',
    'workout_name': 'Squats',
    'completed_at': '2026-11-15T09:00:00.000',
    'duration_seconds': 300,
    'total_reps': 30,
    'avg_form_score': 80.0,
    'estimated_calories': 40,
    'most_common_error': '',
    'exercises': const [],
  };
  if (aiTip != null) row['ai_tip'] = aiTip;
  return row;
}

void main() {
  group('ai_tip', () {
    test('is read from a raw Hive map (seeded rows)', () {
      // Hive hands seeded rows back as Map<dynamic, dynamic>.
      final raw = Map<dynamic, dynamic>.from(_row());
      expect(SessionData.tryParse(raw)?.aiTip, 'Keep your chest up');
    });

    test('is read from a JSON string (recorded rows)', () {
      expect(
        SessionData.tryParse(jsonEncode(_row()))?.aiTip,
        'Keep your chest up',
      );
    });

    test('defaults to empty when missing', () {
      expect(SessionData.tryParse(_row(aiTip: null))?.aiTip, '');
      expect(SessionData.fromJson(_row(aiTip: null)).aiTip, '');
    });

    test('defaults to empty when it is not a string', () {
      expect(SessionData.tryParse(_row(aiTip: 42))?.aiTip, '');
    });

    test('survives a toMap round trip', () {
      final parsed = SessionData.tryParse(_row())!;
      expect(SessionData.tryParse(parsed.toMap())?.aiTip, parsed.aiTip);
    });
  });
}
