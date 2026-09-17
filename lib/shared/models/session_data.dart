import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// Stored session history comes from two writers with different encodings: the
// seeded mock list (raw Hive objects, so Map<dynamic, dynamic>) and recorded
// sessions (jsonEncode'd, so Map<String, dynamic>). The `fromJson` factories
// below assume the latter and throw on the former; `tryParse` accepts both and
// never throws, so one bad row cannot take down a whole screen.
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic>? _asStringMap(Object? raw) {
  final decoded = raw is String ? jsonDecode(raw) : raw;
  return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
}

int _asInt(Object? v) => v is num ? v.toInt() : 0;
double _asDouble(Object? v) => v is num ? v.toDouble() : 0.0;
String _asString(Object? v) => v is String ? v : '';

class ExerciseResult {
  const ExerciseResult({
    required this.exerciseId,
    required this.exerciseName,
    required this.setsCompleted,
    required this.totalReps,
    required this.avgFormScore,
    required this.mostCommonError,
  });

  final String exerciseId;
  final String exerciseName;
  final int setsCompleted;
  final int totalReps;
  final double avgFormScore;
  final String mostCommonError;

  factory ExerciseResult.fromJson(Map<String, dynamic> j) => ExerciseResult(
        exerciseId: j['exercise_id'] as String,
        exerciseName: j['exercise_name'] as String,
        setsCompleted: j['sets_completed'] as int,
        totalReps: j['total_reps'] as int,
        avgFormScore: (j['avg_form_score'] as num).toDouble(),
        mostCommonError: j['most_common_error'] as String,
      );

  /// Tolerant counterpart to [ExerciseResult.fromJson]. Returns null only when
  /// the row is not a map at all.
  static ExerciseResult? tryParse(Object? raw) {
    final j = _asStringMap(raw);
    if (j == null) return null;
    return ExerciseResult(
      exerciseId: _asString(j['exercise_id']),
      exerciseName: _asString(j['exercise_name']),
      setsCompleted: _asInt(j['sets_completed']),
      totalReps: _asInt(j['total_reps']),
      avgFormScore: _asDouble(j['avg_form_score']),
      mostCommonError: _asString(j['most_common_error']),
    );
  }

  Map<String, dynamic> toMap() => {
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'sets_completed': setsCompleted,
        'total_reps': totalReps,
        'avg_form_score': avgFormScore,
        'most_common_error': mostCommonError,
      };
}

class SessionData {
  const SessionData({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    required this.durationSeconds,
    required this.totalReps,
    required this.avgFormScore,
    required this.estimatedCalories,
    required this.mostCommonError,
    required this.exercises,
  });

  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime completedAt;
  final int durationSeconds;
  final int totalReps;
  final double avgFormScore;
  final int estimatedCalories;
  final String mostCommonError;
  final List<ExerciseResult> exercises;

  factory SessionData.fromJson(Map<String, dynamic> j) => SessionData(
        id: j['id'] as String,
        workoutId: j['workout_id'] as String,
        workoutName: j['workout_name'] as String,
        completedAt: DateTime.parse(j['completed_at'] as String),
        durationSeconds: j['duration_seconds'] as int,
        totalReps: j['total_reps'] as int,
        avgFormScore: (j['avg_form_score'] as num).toDouble(),
        estimatedCalories: j['estimated_calories'] as int,
        mostCommonError: j['most_common_error'] as String,
        exercises: (j['exercises'] as List)
            .map((e) => ExerciseResult.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Parses either storage shape (raw Hive map or JSON string) without ever
  /// throwing. Returns null when the row is unusable — not a map, or missing a
  /// parsable `completed_at`, which every progress aggregate keys off.
  static SessionData? tryParse(Object? raw) {
    final j = _asStringMap(raw);
    if (j == null) return null;

    final completedAt = DateTime.tryParse(_asString(j['completed_at']));
    if (completedAt == null) return null;

    final exercises = j['exercises'];
    return SessionData(
      id: _asString(j['id']),
      workoutId: _asString(j['workout_id']),
      workoutName: _asString(j['workout_name']),
      completedAt: completedAt,
      durationSeconds: _asInt(j['duration_seconds']),
      totalReps: _asInt(j['total_reps']),
      avgFormScore: _asDouble(j['avg_form_score']),
      estimatedCalories: _asInt(j['estimated_calories']),
      mostCommonError: _asString(j['most_common_error']),
      exercises: exercises is List
          ? exercises
              .map(ExerciseResult.tryParse)
              .whereType<ExerciseResult>()
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'workout_id': workoutId,
        'workout_name': workoutName,
        'completed_at': completedAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'total_reps': totalReps,
        'avg_form_score': avgFormScore,
        'estimated_calories': estimatedCalories,
        'most_common_error': mostCommonError,
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };
}
