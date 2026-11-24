import '../../core/providers/session_history_provider.dart';
import '../../shared/models/session_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pure grouping for the History tab. The demo year holds hundreds of sessions,
// so the tab renders one flat list lazily; this turns the sessions into that
// list — a day header followed by the day's sessions, newest first.
// ─────────────────────────────────────────────────────────────────────────────

/// One row of the History list: either a day header or a session.
sealed class HistoryItem {
  const HistoryItem();
}

class HistoryDayHeader extends HistoryItem {
  const HistoryDayHeader({required this.day, required this.label});

  /// Local midnight of the day.
  final DateTime day;
  final String label;
}

class HistorySessionItem extends HistoryItem {
  const HistorySessionItem(this.session);

  final SessionData session;
}

/// Flattens [sessions] into day headers and sessions, newest day first and
/// newest session first within a day. Days are local calendar days. [now]
/// decides which day reads TODAY / YESTERDAY.
List<HistoryItem> buildHistoryItems(
  List<SessionData> sessions, {
  required DateTime now,
}) {
  if (sessions.isEmpty) return const [];

  // The provider already sorts newest first; sorting again keeps this function
  // correct on its own and costs little next to building the widgets.
  final sorted = [
    ...sessions,
  ]..sort((a, b) => b.completedAt.toLocal().compareTo(a.completedAt.toLocal()));

  final items = <HistoryItem>[];
  DateTime? currentDay;
  for (final session in sorted) {
    final day = dateOnly(session.completedAt.toLocal());
    if (day != currentDay) {
      currentDay = day;
      items.add(HistoryDayHeader(day: day, label: historyDayLabel(day, now)));
    }
    items.add(HistorySessionItem(session));
  }
  return items;
}

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

/// `TODAY`, `YESTERDAY`, otherwise `MON 18 NOV` — with the year appended when
/// [day] is not in [now]'s year.
String historyDayLabel(DateTime day, DateTime now) {
  final date = dateOnly(day);
  final today = dateOnly(now);
  // Calendar arithmetic rather than subtracting 24h, which a DST change breaks.
  final yesterday = DateTime(today.year, today.month, today.day - 1);

  if (date == today) return 'TODAY';
  if (date == yesterday) return 'YESTERDAY';

  final base =
      '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}
