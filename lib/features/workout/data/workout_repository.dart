import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/mock_data.dart';
import '../../../shared/models/session_data.dart';

class WorkoutRepository {
  Box get _box => Hive.box(MockData.boxSessionHistory);
  Box get _prefs => Hive.box(MockData.boxUserProfile);

  static const _realPrefix = 'real_session_';

  /// Preference key: whether the seeded year of demo history is shown.
  static const prefShowDemoHistory = 'show_demo_history';

  /// Stores a finished session. Returns false, never throws, when the write
  /// fails: the caller is a listener at the end of a workout, and an exception
  /// there would surface as an unhandled error with the summary half-built.
  Future<bool> saveSession(Map<String, dynamic> session) async {
    final key = '$_realPrefix${session['id']}';
    try {
      await _box.put(key, jsonEncode(session));
      return true;
    } catch (e) {
      debugPrint('WorkoutRepository: session $key not saved — $e');
      return false;
    }
  }

  List<Map<String, dynamic>> getRealSessions() {
    final result = <Map<String, dynamic>>[];
    for (final key in _box.keys) {
      if (key.toString().startsWith(_realPrefix)) {
        final raw = _box.get(key) as String?;
        if (raw != null) {
          result.add(jsonDecode(raw) as Map<String, dynamic>);
        }
      }
    }
    result.sort((a, b) =>
        (b['completed_at'] as String).compareTo(a['completed_at'] as String));
    return result;
  }

  /// Whether [getAllSessions] mixes in the seeded demo history.
  ///
  /// Off unless the user turns it on. The demo year is there so Home and
  /// Progress have something to show in a demonstration, but merged silently
  /// it passes off made-up workouts, form scores and streaks as the user's
  /// own, and dilutes every real number on those screens.
  bool get showDemoHistory =>
      _prefs.get(prefShowDemoHistory, defaultValue: false) as bool;

  Future<void> setShowDemoHistory(bool show) =>
      _prefs.put(prefShowDemoHistory, show);

  /// Every session to show, newest first: each recorded `real_session_*` row,
  /// plus the seeded demo history under `'sessions'` when [showDemoHistory] is
  /// on. The two writers disagree on encoding but not on field names, so
  /// [SessionData.tryParse] normalises both and drops anything unreadable.
  List<SessionData> getAllSessions() {
    try {
      final sessions = <SessionData>[];

      if (showDemoHistory) {
        final seeded = _box.get('sessions');
        if (seeded is List) {
          sessions.addAll(
            seeded.map(SessionData.tryParse).whereType<SessionData>(),
          );
        }
      }

      for (final key in _box.keys) {
        if (!key.toString().startsWith(_realPrefix)) continue;
        final parsed = SessionData.tryParse(_box.get(key));
        if (parsed != null) sessions.add(parsed);
      }

      sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return sessions;
    } catch (_) {
      // A corrupt box should land on the empty-history UI, not a red screen.
      return const [];
    }
  }

  /// Deletes every recorded session and returns how many went. The demo
  /// history is left alone — it is regenerated data, not the user's.
  Future<int> clearRecordedSessions() async {
    final keys = _box.keys
        .where((k) => k.toString().startsWith(_realPrefix))
        .toList();
    await _box.deleteAll(keys);
    return keys.length;
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(),
);
