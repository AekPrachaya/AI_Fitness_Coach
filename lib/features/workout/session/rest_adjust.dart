/// A rest countdown: seconds still to go, and the full length of this rest
/// for drawing the countdown ring.
typedef RestTime = ({int left, int total});

/// Longest a rest can be stretched to with the +30s button.
const int maxRestSeconds = 300;

/// Applies a +/− adjustment from the rest screen.
///
/// Returns null when the adjustment uses up the rest, which means the next
/// set should start straight away — the same as skipping.
///
/// Adding time grows the total along with what is left, so the ring keeps its
/// proportion instead of overflowing past full. Taking time away leaves the
/// total alone, so the ring visibly drops by the amount cut.
RestTime? adjustRest(
  RestTime rest,
  int delta, {
  int maxSeconds = maxRestSeconds,
}) {
  final raw = rest.left + delta;
  if (raw <= 0) return null;

  final left = raw > maxSeconds ? maxSeconds : raw;
  final grown = delta > 0 ? rest.total + (left - rest.left) : rest.total;
  final total = grown < left ? left : grown;
  return (left: left, total: total);
}
