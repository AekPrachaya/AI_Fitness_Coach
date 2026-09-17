import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MockData
// Static utility class for the frontend-only data layer.
// No HTTP calls, no Firebase — all data is local JSON or Hive.
// ─────────────────────────────────────────────────────────────────────────────

abstract class MockData {
  // ── Hive box names ──────────────────────────────────────────────────────────
  static const String boxUserProfile    = 'user_profile';
  static const String boxSessionHistory = 'session_history';
  static const String boxProgressData   = 'progress_data';

  // ── SharedPreferences keys ──────────────────────────────────────────────────
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefUnits              = 'units';
  static const String prefThemeMode          = 'theme_mode';
  static const String prefDefaultDifficulty  = 'default_difficulty';
  static const String prefRestDuration       = 'rest_duration';
  static const String prefAutoAdvance        = 'auto_advance';
  static const String prefShowSkeleton       = 'show_skeleton';
  static const String prefShowAngles         = 'show_angles';
  static const String prefMirrorCamera       = 'mirror_camera';
  static const String prefRepSound           = 'rep_sound';
  static const String prefFormHaptic         = 'form_haptic';
  static const String prefWorkoutReminder    = 'workout_reminder';
  static const String prefReminderTime       = 'reminder_time';
  static const String prefIsGuest            = 'is_guest';

  // ── Method 1: Load workouts from bundled JSON ───────────────────────────────
  static Future<List<Workout>> loadWorkouts() async {
    final jsonStr = await rootBundle.loadString('assets/data/workouts.json');
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => Workout.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Method 2: Default user profile (guest / first launch) ──────────────────
  static UserProfile getDefaultUserProfile() => UserProfile(
        name: 'Athlete',
        email: '',
        age: 25,
        gender: 'prefer_not_to_say',
        heightCm: 170.0,
        weightKg: 70.0,
        fitnessGoal: 'build_muscle',
        fitnessLevel: 'beginner',
        equipment: ['no_equipment'],
        joinedAt: DateTime.now(),
      );

  /// Bumped whenever the generated demo history changes shape, so devices that
  /// already seeded pick the new data up exactly once.
  static const int seedVersion = 5;

  /// Days of demo history — the widest heatmap window (52 weeks), so a desktop
  /// width never shows empty columns on the left.
  static const int seedDays = 364;

  /// Inclusive day range (counted from the oldest seeded day) left free of rest
  /// days, giving the demo history one 11-day personal best.
  static const int _bestRunStart = 30;
  static const int _bestRunEnd = 40;

  // ── Method 3: Seed demo sessions across the past [seedDays] days ───────────
  static Future<void> seedProgressHistory() async {
    final box = Hive.box(boxSessionHistory);
    if (box.get('seed_version') == seedVersion) return;

    const exerciseIds = ['push_ups', 'squats', 'deadlifts', 'bicep_curls'];
    const exerciseNames = ['Push-ups', 'Squats', 'Deadlifts', 'Bicep Curls'];
    const tips = [
      'Your knee alignment improved. Focus on back posture next time.',
      'Great consistency this week! Try increasing reps by 2 next session.',
      'Your form score is trending upward. Keep it up!',
      'Work on slowing down the eccentric phase for better muscle engagement.',
      'Excellent depth on squats today. Now focus on keeping your chest up.',
    ];

    final sessions = <Map<String, dynamic>>[];
    final now = DateTime.now();

    // Rotates over emitted sessions, not over the calendar: keying the exercise
    // off the day would collide with the rest cycle and starve one exercise.
    var rotation = 0;

    for (var i = seedDays - 1; i >= 0; i--) {
      // age 0 = oldest day, so form improves as the history approaches today.
      final age = seedDays - 1 - i;

      // Rest every fourth day, except through one unbroken stretch — without it
      // the best streak would be pinned at the cycle length and the streak card
      // would look broken rather than merely modest.
      final inBestRun = age >= _bestRunStart && age <= _bestRunEnd;
      if (!inBestRun && age % 4 == 3) continue;

      final idx = rotation++ % exerciseIds.length;
      // Scaled by progress through the history rather than raw age, so a
      // longer window still climbs gradually instead of pinning at the cap.
      final progress = age / (seedDays - 1);
      final score = (62.0 + progress * 26 + (i % 5) * 2).clamp(60.0, 97.0);
      // 10–50 min, so day intensity spans every heatmap shade.
      final durationSeconds = 600 + (i % 9) * 300;

      void addSession(String suffix, int hourOffset) {
        sessions.add({
          'id': 'mock_session_$i$suffix',
          'workout_id': exerciseIds[idx],
          'workout_name': exerciseNames[idx],
          'completed_at': now
              .subtract(Duration(days: i, hours: hourOffset))
              .toIso8601String(),
          'duration_seconds': durationSeconds,
          'total_reps': 36 + (i % 6) * 4,
          'avg_form_score': score,
          'estimated_calories': 110 + (i % 7) * 15,
          'most_common_error': 'Keep knees aligned',
          'ai_tip': tips[i % tips.length],
          'exercises': [
            {
              'exercise_id': exerciseIds[idx],
              'exercise_name': exerciseNames[idx],
              'sets_completed': 3,
              'total_reps': 36,
              'avg_form_score': score,
              'most_common_error': 'Keep knees aligned',
            },
          ],
        });
      }

      addSession('', 0);
      // An occasional double session gives the heatmap its darkest cells.
      if (i % 11 == 0) addSession('_b', 5);
    }

    await box.put('sessions', sessions);
    await box.put('seed_version', seedVersion);
    // Retire the pre-versioning flag so it cannot mask a future re-seed.
    await box.delete('seeded');
  }

  // ── Method 4: Seed 8 weekly body-metric entries ─────────────────────────────
  // Idempotent — checks 'metrics_seeded' flag before writing.
  static Future<void> seedBodyMetrics() async {
    final box = Hive.box(boxProgressData);
    if (box.get('metrics_seeded') == true) return;

    final entries = <Map<String, dynamic>>[];
    final now = DateTime.now();

    for (var i = 7; i >= 0; i--) {
      entries.add({
        'id': 'mock_metric_$i',
        'recorded_at': now.subtract(Duration(days: i * 7)).toIso8601String(),
        'weight_kg': 72.5 - (i * 0.3),
        'body_fat_percent': null,
        'notes': null,
      });
    }

    await box.put('body_metrics', entries);
    await box.put('metrics_seeded', true);
  }

  // ── Method 5: Mock feedback pool for the session screen ─────────────────────
  // Phase 4 (Task 4.7) imports this instead of hardcoding strings in the notifier.
  static Map<String, List<String>> getMockFeedbackMessages() => {
        'push_ups': [
          'Good Form!',
          'Back too curved',
          'Elbows flaring outward',
          'Hips sagging',
          'Great depth!',
          'Incomplete range of motion',
        ],
        'squats': [
          'Good Form!',
          'Knees caving inward',
          'Keep knees aligned',
          'Back too curved',
          'Great depth!',
          'Heels rising off the floor',
        ],
        'deadlifts': [
          'Good Form!',
          'Back too curved',
          'Bar drifting away from body',
          'Hips rising too fast',
          'Excellent lift!',
          'Keep the bar close',
        ],
        'bicep_curls': [
          'Good Form!',
          'Elbows flaring outward',
          'Using too much momentum',
          'Back too curved',
          'Full range of motion!',
          'Control the descent',
        ],
      };
}
