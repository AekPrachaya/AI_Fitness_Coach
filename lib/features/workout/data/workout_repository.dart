import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/mock_data.dart';

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
}

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(),
);
