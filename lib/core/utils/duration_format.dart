/// Formats a length of time as a clock reading: `m:ss`, or `h:mm:ss` once it
/// passes an hour. Negative input reads as zero.
///
/// Shared by the live session timer and the workout summary, so the two show
/// the same number the same way.
String formatClock(int seconds) {
  final total = seconds < 0 ? 0 : seconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}
