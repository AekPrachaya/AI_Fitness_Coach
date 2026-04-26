class ProgressEntry {
  const ProgressEntry({
    required this.id,
    required this.recordedAt,
    required this.weightKg,
    this.bodyFatPercent,
    this.notes,
  });

  final String id;
  final DateTime recordedAt;
  final double weightKg;
  final double? bodyFatPercent;
  final String? notes;

  factory ProgressEntry.fromJson(Map<String, dynamic> j) => ProgressEntry(
        id: j['id'] as String,
        recordedAt: DateTime.parse(j['recorded_at'] as String),
        weightKg: (j['weight_kg'] as num).toDouble(),
        bodyFatPercent: j['body_fat_percent'] == null
            ? null
            : (j['body_fat_percent'] as num).toDouble(),
        notes: j['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'recorded_at': recordedAt.toIso8601String(),
        'weight_kg': weightKg,
        'body_fat_percent': bodyFatPercent,
        'notes': notes,
      };
}
