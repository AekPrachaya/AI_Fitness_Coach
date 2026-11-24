import 'dart:ui' show Color;

import '../../core/theme/app_colors.dart';
import '../../shared/models/session_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pure logic behind the Profile screen: lifetime stats, BMI category, input
// validation and the equipment toggle rule. Nothing here touches Hive or
// widgets, so all of it is unit-tested directly.
// ─────────────────────────────────────────────────────────────────────────────

// ── Lifetime stats ───────────────────────────────────────────────────────────

class ProfileStats {
  const ProfileStats({
    required this.workouts,
    required this.totalSeconds,
    required this.avgFormScore,
  });

  final int workouts;
  final int totalSeconds;

  /// Mean of every session's avgFormScore; null when there are no sessions.
  final double? avgFormScore;

  static const empty = ProfileStats(
    workouts: 0,
    totalSeconds: 0,
    avgFormScore: null,
  );

  /// `41H` from an hour up, `35M` below it.
  String get totalTimeLabel {
    final minutes = totalSeconds ~/ 60;
    if (minutes >= 60) return '${minutes ~/ 60}H';
    return '${minutes}M';
  }

  /// `86%`, or `--` when there is nothing to average.
  String get avgFormLabel =>
      avgFormScore == null ? '--' : '${avgFormScore!.round()}%';
}

ProfileStats profileStats(List<SessionData> sessions) {
  if (sessions.isEmpty) return ProfileStats.empty;
  var seconds = 0;
  var scoreSum = 0.0;
  for (final s in sessions) {
    seconds += s.durationSeconds;
    scoreSum += s.avgFormScore;
  }
  return ProfileStats(
    workouts: sessions.length,
    totalSeconds: seconds,
    avgFormScore: scoreSum / sessions.length,
  );
}

// ── BMI ──────────────────────────────────────────────────────────────────────

enum BmiCategory {
  under('UNDER', AppColors.warning),
  normal('NORMAL', AppColors.scoreGood),
  over('OVER', AppColors.warning),
  obese('OBESE', AppColors.error);

  const BmiCategory(this.label, this.color);
  final String label;
  final Color color;
}

/// WHO adult bands.
BmiCategory bmiCategory(double bmi) {
  if (bmi < 18.5) return BmiCategory.under;
  if (bmi < 25) return BmiCategory.normal;
  if (bmi < 30) return BmiCategory.over;
  return BmiCategory.obese;
}

// ── Numeric validation ───────────────────────────────────────────────────────

/// Range and shape of one numeric profile field.
class NumberRule {
  const NumberRule({
    required this.min,
    required this.max,
    required this.unit,
    this.decimals = 0,
  });

  final double min;
  final double max;
  final String unit;

  /// 0 = whole numbers only.
  final int decimals;

  static const age = NumberRule(min: 13, max: 100, unit: 'years');
  static const heightCm = NumberRule(min: 100, max: 250, unit: 'cm');
  static const weightKg = NumberRule(
    min: 30,
    max: 250,
    unit: 'kg',
    decimals: 1,
  );

  String _fmt(double v) => v.toStringAsFixed(0);

  /// Null when [text] is a valid value, otherwise the message to show.
  String? validate(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Enter a value';
    final value = parse(trimmed);
    if (value == null) {
      return decimals == 0 ? 'Whole numbers only' : 'Enter a number';
    }
    if (value < min || value > max) {
      return 'Between ${_fmt(min)} and ${_fmt(max)} $unit';
    }
    return null;
  }

  /// The parsed value, or null when [text] is not a number of this shape.
  double? parse(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (decimals == 0) return int.tryParse(trimmed)?.toDouble();
    final pattern = RegExp(
      r'^\d+(\.\d{1,'
      '$decimals'
      r'})?$',
    );
    if (!pattern.hasMatch(trimmed)) return null;
    return double.tryParse(trimmed);
  }
}

/// Null when [name] is acceptable, otherwise the message to show.
String? validateName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Enter your name';
  if (trimmed.length > maxNameLength) {
    return 'At most $maxNameLength characters';
  }
  return null;
}

const maxNameLength = 30;

// ── Equipment ────────────────────────────────────────────────────────────────

const noEquipmentId = 'no_equipment';

/// Mirrors `OnboardingNotifier.toggleEquipment`: 'no_equipment' is exclusive —
/// picking it clears everything else, picking anything else clears it.
List<String> toggleEquipment(List<String> current, String item) {
  final next = List<String>.from(current);
  if (next.contains(item)) {
    next.remove(item);
  } else {
    if (item == noEquipmentId) {
      next.clear();
    } else {
      next.remove(noEquipmentId);
    }
    next.add(item);
  }
  return next;
}
