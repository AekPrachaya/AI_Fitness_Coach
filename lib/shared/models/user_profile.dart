class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.fitnessGoal,
    required this.fitnessLevel,
    required this.equipment,
    required this.joinedAt,
  });

  final String name;
  final String email;
  final int age;
  final String gender;       // 'male' | 'female' | 'prefer_not_to_say'
  final double heightCm;
  final double weightKg;
  final String fitnessGoal;  // 'lose_weight' | 'build_muscle' | 'improve_flexibility' | 'boost_endurance'
  final String fitnessLevel; // 'beginner' | 'intermediate' | 'advanced'
  final List<String> equipment;
  final DateTime joinedAt;

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] as String,
        email: j['email'] as String,
        age: j['age'] as int,
        gender: j['gender'] as String,
        heightCm: (j['height_cm'] as num).toDouble(),
        weightKg: (j['weight_kg'] as num).toDouble(),
        fitnessGoal: j['fitness_goal'] as String,
        fitnessLevel: j['fitness_level'] as String,
        equipment: List<String>.from(j['equipment'] as List),
        joinedAt: DateTime.parse(j['joined_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'fitness_goal': fitnessGoal,
        'fitness_level': fitnessLevel,
        'equipment': equipment,
        'joined_at': joinedAt.toIso8601String(),
      };
}
