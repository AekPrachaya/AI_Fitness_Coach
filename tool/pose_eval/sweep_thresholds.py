"""Score rep-count thresholds against hand-labelled videos.

Reads the *_frames.csv and *_landmarks.npz files written by extract_angles.py,
so trying a new threshold takes seconds instead of re-running pose detection.

Usage:
    python sweep_thresholds.py pose_out labels.csv
    python sweep_thresholds.py pose_out labels.csv --angle 3d
    python sweep_thresholds.py pose_out labels.csv --gate-front   # like the app

--gate-front drops frames the app's BodyView would call a front view
(shoulder width / torso length > 0.35), the way the session skips them. The
divisor is the larger of this frame's torso and the one last seen at the top
of the movement, as in the app; --no-standing-torso uses this frame's alone
(the behaviour before 2026-11-09).
Writes sweep.csv (every combination) and per_video.csv (the best one) into
the pose_out folder.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path

import numpy as np

MIN_LIKELIHOOD = 0.65
SIDE_MAX_RATIO = 0.35  # BodyView.sideMaxRatio


@dataclass
class Frame:
    angle: float | None
    shoulder_width: float | None  # None when either shoulder is not trusted
    torso: float | None


def count_reps(frames: list[Frame], down: float, up: float, hysteresis: float,
               gate_front: bool, standing_torso: bool) -> int:
    waiting_down, n, standing = True, 0, None
    for f in frames:
        if gate_front:
            if standing_torso and f.angle is not None and f.angle > up and f.torso:
                standing = f.torso
            if f.shoulder_width is not None and f.torso:
                divisor = max(f.torso, standing or 0) if standing_torso else f.torso
                if f.shoulder_width / divisor > SIDE_MAX_RATIO:
                    continue
        if f.angle is None:
            continue
        if waiting_down and f.angle < down - hysteresis:
            waiting_down = False
        elif not waiting_down and f.angle > up + hysteresis:
            n += 1
            waiting_down = True
    return n


def torso_length(frame: np.ndarray) -> float | None:
    """Port of BodyView.torsoLength for one frame (33×4)."""
    ls, rs, lh, rh = frame[11], frame[12], frame[23], frame[24]
    left, right = min(ls[3], lh[3]), min(rs[3], rh[3])
    left_ok, right_ok = left > MIN_LIKELIHOOD, right > MIN_LIKELIHOOD
    if not (left_ok or right_ok):
        return None
    s, h = (ls, lh) if left_ok and (not right_ok or left >= right) else (rs, rh)
    length = float(np.hypot(*(s[:2] - h[:2])))
    return length if length > 0 else None


def load_frames(out: Path, stem: str, column: str) -> list[Frame]:
    rows = list(csv.DictReader((out / f"{stem}_frames.csv").open()))
    image = np.load(out / f"{stem}_landmarks.npz")["image"]
    frames = []
    for i, r in enumerate(rows):
        ls, rs = image[i, 11], image[i, 12]
        width = None
        if ls[3] > MIN_LIKELIHOOD and rs[3] > MIN_LIKELIHOOD:
            width = float(np.hypot(*(ls[:2] - rs[:2])))
        frames.append(Frame(float(r[column]) if r[column] else None, width, torso_length(image[i])))
    return frames


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("out", type=Path, help="folder written by extract_angles.py")
    p.add_argument("labels", type=Path, help="CSV with columns video,reps")
    p.add_argument("--angle", choices=["2d", "3d"], default="2d")
    p.add_argument("--hysteresis", type=float, default=8.0)
    p.add_argument("--down", default="90:141:5", help="start:stop:step")
    p.add_argument("--up", default="140:171:5", help="start:stop:step")
    p.add_argument("--gate-front", action="store_true")
    p.add_argument("--no-standing-torso", action="store_true")
    args = p.parse_args()

    with args.labels.open() as f:
        labels = {Path(r["video"]).stem: int(r["reps"]) for r in csv.DictReader(f) if r["reps"].strip()}
    column = f"angle_{args.angle}"
    frames = {v: load_frames(args.out, v, column) for v in labels}
    standing = not args.no_standing_torso
    total = sum(labels.values())

    def span(spec: str):
        a, b, c = (float(x) for x in spec.split(":"))
        return np.arange(a, b, c)

    results = []
    for down in span(args.down):
        for up in span(args.up):
            if up - down <= 2 * args.hysteresis:
                continue
            counts = {v: count_reps(f, down, up, args.hysteresis, args.gate_front, standing)
                      for v, f in frames.items()}
            wrong = sum(abs(counts[v] - labels[v]) for v in labels)
            results.append({
                "down": down, "up": up,
                "accuracy_pct": round(100 * (1 - wrong / total), 1),
                "exact_videos": sum(counts[v] == labels[v] for v in labels),
                "wrong_reps": wrong,
                "_counts": counts,
            })
    results.sort(key=lambda r: (r["wrong_reps"], -r["exact_videos"]))

    with (args.out / "sweep.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["down", "up", "accuracy_pct", "exact_videos", "wrong_reps"])
        w.writeheader()
        w.writerows({k: v for k, v in r.items() if not k.startswith("_")} for r in results)

    best = results[0]
    with (args.out / "per_video.csv").open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["video", "true_reps", "counted", "error"])
        for v in labels:
            w.writerow([v, labels[v], best["_counts"][v], best["_counts"][v] - labels[v]])

    print(f"{len(labels)} videos, {total} reps, angle {args.angle}"
          f"{', front frames gated' if args.gate_front else ''}"
          f"{' (current torso only)' if args.gate_front and not standing else ''}")
    for r in results[:10]:
        print(f"  down {r['down']:g} / up {r['up']:g}: {r['accuracy_pct']}% "
              f"({r['exact_videos']}/{len(labels)} videos exact)")


if __name__ == "__main__":
    main()
