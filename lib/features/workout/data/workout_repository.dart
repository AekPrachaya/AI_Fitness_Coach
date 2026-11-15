import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/mock_data.dart';
import '../../../shared/models/session_data.dart';

class WorkoutRepository {
  Box get _box => Hive.box(MockData.boxSessionHistory);

  static const _realPrefix = 'real_session_';

  Future<void> saveSession(Map<String, dynamic> session) async {
    final key = '$_realPrefix${session['id']}';
    await _box.put(key, jsonEncode(session));
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

  /// Every session the app knows about, newest first: the seeded demo history
  /// under `'sessions'` plus each recorded `real_session_*` row. The two
  /// writers disagree on encoding but not on field names, so
  /// [SessionData.tryParse] normalises both and drops anything unreadable.
  List<SessionData> getAllSessions() {
    try {
      final sessions = <SessionData>[];

      final seeded = _box.get('sessions');
      if (seeded is List) {
        sessions.addAll(
          seeded.map(SessionData.tryParse).whereType<SessionData>(),
        );
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
}

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(),
);
