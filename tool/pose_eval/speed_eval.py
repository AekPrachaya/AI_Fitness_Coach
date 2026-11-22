"""How fast can someone squat before the app stops keeping up?

The phone delivers pose estimates at a frame rate well below the camera's
(27 fps after the 2026-11-19 fixes, 21 before), and a quick rep spends only a
handful of frames near the bottom. Two things can break:

  * counting — the rep counter needs one frame below the down threshold and
    one above the up threshold; skip past the bottom and the rep is lost
  * depth — the lowest angle seen is the lowest frame that happened to be
    sampled, so a fast rep reads shallower than it went

This replays the recorded clips (extract_angles.py output) at lower frame
rates by keeping one frame per 1/fps seconds, and reports, per rate:
  rep-count accuracy against labels.csv (scored as sweep_thresholds.py does),
  and how much shallower each rep's bottom reads than at the full rate,
  split by how fast that rep went down.

Usage:
    python speed_eval.py pose_out labels.csv --fps 30 27 20 15 10 \
        --down 125 --up 160 --gate-front
"""

from __future__ import annotations

import argparse
import csv
import statistics
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sweep_thresholds import SIDE_MAX_RATIO, Frame, count_reps, load_frames  # noqa: E402


def times(out: Path, stem: str) -> list[float]:
    return [float(r["t"]) for r in csv.DictReader((out / f"{stem}_frames.csv").open())]


def subsample(frames: list[Frame], ts: list[float], fps: float | None):
    """Keep the first frame of every 1/fps window; None keeps every frame."""
    if fps is None:
        return frames, ts
    kept, kept_t, next_t = [], [], 0.0
    for f, t in zip(frames, ts):
        if t + 1e-9 >= next_t:
            kept.append(f)
            kept_t.append(t)
            next_t += 1 / fps
            while next_t <= t:
                next_t += 1 / fps
    return kept, kept_t


def visible(frames: list[Frame], up: float, gate_front: bool) -> list[bool]:
    """Which frames the app would grade — BodyView side-view gate, as in sweep."""
    out, standing = [], None
    for f in frames:
        ok = f.angle is not None
        if gate_front and ok:
            if f.angle > up and f.torso:
                standing = f.torso
            if f.shoulder_width is not None and f.torso:
                if f.shoulder_width / max(f.torso, standing or 0) > SIDE_MAX_RATIO:
                    ok = False
        out.append(ok)
    return out


def reps_with_timing(frames, ts, down, up, hyst, gate_front):
    """Each counted rep: (start of descent, time of low point, low angle)."""
    ok = visible(frames, up, gate_front)
    reps, waiting_down, start, low, low_t = [], True, None, None, None
    for f, t, v in zip(frames, ts, ok):
        if not v:
            continue
        a = f.angle
        if waiting_down and a > up:
            start = t  # last frame at the top before going down
        if waiting_down:
            if a < down - hyst:
                waiting_down, low, low_t = False, a, t
        else:
            if a < low:
                low, low_t = a, t
            if a > up + hyst:
                reps.append((start if start is not None else low_t, low_t, low))
                waiting_down = True
    return reps


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("out", type=Path)
    p.add_argument("labels", type=Path)
    p.add_argument("--fps", type=float, nargs="+", default=[30, 27, 20, 15, 10])
    p.add_argument("--down", type=float, default=125.0)
    p.add_argument("--up", type=float, default=160.0)
    p.add_argument("--hysteresis", type=float, default=8.0)
    p.add_argument("--gate-front", action="store_true")
    args = p.parse_args()

    with args.labels.open() as fh:
        labels = {Path(r["video"]).stem: int(r["reps"]) for r in csv.DictReader(fh)
                  if r.get("video", "").strip() and r.get("reps", "").strip()}
    clips = {v: (load_frames(args.out, v, "angle_2d"), times(args.out, v)) for v in labels}
    total = sum(labels.values())

    # Reference: every recorded frame. Each rep's descent speed and true depth.
    ref = {v: reps_with_timing(f, t, args.down, args.up, args.hysteresis, args.gate_front)
           for v, (f, t) in clips.items()}
    descents = [lo_t - st for rs in ref.values() for st, lo_t, _ in rs]
    q = statistics.quantiles(descents, n=3)
    bins = (("fast", 0, q[0]), ("medium", q[0], q[1]), ("slow", q[1], 99))
    print(f"{sum(len(r) for r in ref.values())} reps counted at the recorded rate; "
          f"descent top→bottom median {statistics.median(descents):.2f}s "
          f"(fast < {q[0]:.2f}s ≤ medium < {q[1]:.2f}s ≤ slow)")

    print(f"\n{'fps':>6}  {'count acc':>9}  {'exact clips':>11}  "
          + "  ".join(f"{name + ' depth err':>17}" for name, *_ in bins) + "   (median / worst, degrees shallower)")
    for fps in [None, *args.fps]:
        counts, errs = {}, {name: [] for name, *_ in bins}
        for v, (f, t) in clips.items():
            fs, tsub = subsample(f, t, fps)
            counts[v] = count_reps(fs, args.down, args.up, args.hysteresis, args.gate_front, True)
            # Depth: lowest sampled angle inside each reference rep's descent-to-rise window.
            for st, lo_t, lo in ref[v]:
                window = [fr.angle for fr, tt in zip(fs, tsub)
                          if fr.angle is not None and st <= tt <= lo_t + 0.6]
                if not window:
                    continue
                d = lo_t - st
                name = next(n for n, a, b in bins if a <= d < b)
                errs[name].append(min(window) - lo)
        wrong = sum(abs(counts[v] - labels[v]) for v in labels)
        exact = sum(counts[v] == labels[v] for v in labels)
        cells = []
        for name, *_ in bins:
            e = errs[name]
            cells.append(f"{statistics.median(e):6.1f} / {max(e):5.1f}" if e else "-")
        label = "all" if fps is None else f"{fps:g}"
        print(f"{label:>6}  {100 * (1 - wrong / total):8.1f}%  {exact:>5}/{len(labels):<5}  "
              + "  ".join(f"{c:>17}" for c in cells))


if __name__ == "__main__":
    main()
