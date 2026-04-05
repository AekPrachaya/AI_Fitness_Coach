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
