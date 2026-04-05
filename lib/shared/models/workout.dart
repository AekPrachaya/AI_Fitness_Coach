class Workout {
  const Workout({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.difficulty,
    required this.defaultSets,
    required this.defaultReps,
    required this.durationMinutes,
    required this.description,
    required this.instructions,
    required this.commonMistakes,
    required this.muscleGroupTags,
    this.imagePath,
  });

  final String id;
  final String name;
  final String muscleGroup;    // 'upper_body' | 'lower_body' | 'full_body' | 'core' | 'cardio'
  final String difficulty;     // 'beginner' | 'intermediate' | 'advanced'
  final int defaultSets;
  final int defaultReps;
  final int durationMinutes;
  final String description;
  final List<String> instructions;
  final List<String> commonMistakes;
  final List<String> muscleGroupTags;
  final String? imagePath;

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
        id: j['id'] as String,
        name: j['name'] as String,
        muscleGroup: j['muscle_group'] as String,
        difficulty: j['difficulty'] as String,
        defaultSets: j['default_sets'] as int,
        defaultReps: j['default_reps'] as int,
        durationMinutes: j['duration_minutes'] as int,
        description: j['description'] as String,
        instructions: List<String>.from(j['instructions'] as List),
        commonMistakes: List<String>.from(j['common_mistakes'] as List),
        muscleGroupTags: List<String>.from(j['muscle_group_tags'] as List),
        imagePath: j['image_path'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'muscle_group': muscleGroup,
        'difficulty': difficulty,
        'default_sets': defaultSets,
        'default_reps': defaultReps,
        'duration_minutes': durationMinutes,
        'description': description,
        'instructions': instructions,
        'common_mistakes': commonMistakes,
        'muscle_group_tags': muscleGroupTags,
        'image_path': imagePath,
      };
}
