import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_history_provider.dart';
import '../../../shared/models/session_data.dart';

/// Which stored session the summary screen shows.
///
/// With a [sessionId] (a replay from History) that exact session. Without one
/// (the session screen has just finished and saved) the newest session for
/// [workoutId] — [all] is already newest-first. Null when nothing matches.
SessionData? pickSummarySession(
  List<SessionData> all, {
  required String workoutId,
  String? sessionId,
}) {
  for (final session in all) {
    final matches = sessionId != null
        ? session.id == sessionId
        : session.workoutId == workoutId;
    if (matches) return session;
  }
  return null;
}

typedef SummaryArgs = ({String workoutId, String? sessionId});

/// Reads through [sessionHistoryProvider], which the session screen
/// invalidates right after saving, so a just-finished workout is visible.
final summarySessionProvider =
    Provider.autoDispose.family<SessionData?, SummaryArgs>(
  (ref, args) => pickSummarySession(
    ref.watch(sessionHistoryProvider),
    workoutId: args.workoutId,
    sessionId: args.sessionId,
  ),
);
