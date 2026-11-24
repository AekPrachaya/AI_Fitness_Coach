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

With --tune-group the thresholds are chosen on that group of labels.csv
alone and --test-group reports how they hold up on people never tuned on:
    python sweep_thresholds.py pose_out labels.csv --gate-front \\
        --tune-group tune --test-group test --by sex --participants participants.csv
"""

from __future__ import annotations

import argparse
import csv
import sys
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
    p.add_argument("--tune-group", help="choose thresholds on this labels.csv group only")
    p.add_argument("--test-group", help="then report the chosen thresholds on this group")
    p.add_argument("--by", help="break the chosen thresholds down by a column (person, code, sex, …)")
    p.add_argument("--participants", type=Path, help="CSV keyed by person, adds e.g. sex for --by")
    args = p.parse_args()

    with args.labels.open() as f:
        meta = {Path(r["video"]).stem: r for r in csv.DictReader(f)
                if r.get("video", "").strip() and r.get("reps", "").strip()}
    if args.participants:
        with args.participants.open() as f:
            people = {r["person"]: r for r in csv.DictReader(f)}
        for r in meta.values():
            for k, v in people.get(r.get("person", ""), {}).items():
                r.setdefault(k, v)
    labels = {v: int(r["reps"]) for v, r in meta.items()}
    column = f"angle_{args.angle}"
    frames = {v: load_frames(args.out, v, column) for v in labels}
    standing = not args.no_standing_torso

    def in_group(name):
        return [v for v in labels if not name or meta[v].get("group") == name]

    tune = in_group(args.tune_group)
    if not tune:
        sys.exit(f"no labelled videos in group {args.tune_group!r}")

    def score(videos, counts):
        total = sum(labels[v] for v in videos)
        wrong = sum(abs(counts[v] - labels[v]) for v in videos)
        return {"accuracy_pct": round(100 * (1 - wrong / max(total, 1)), 1),
                "exact_videos": sum(counts[v] == labels[v] for v in videos),
                "wrong_reps": wrong, "reps": total, "videos": len(videos)}

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
            results.append({"down": down, "up": up, **score(tune, counts), "_counts": counts})
    results.sort(key=lambda r: (r["wrong_reps"], -r["exact_videos"]))

    with (args.out / "sweep.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["down", "up", "accuracy_pct", "exact_videos", "wrong_reps"])
        w.writeheader()
        w.writerows({k: r[k] for k in w.fieldnames} for r in results)

    best = results[0]
    counts = best["_counts"]
    with (args.out / "per_video.csv").open("w", newline="") as f:
        extra = [k for k in ("person", "group", "code", "sex") if any(k in meta[v] for v in labels)]
        w = csv.writer(f)
        w.writerow(["video", *extra, "true_reps", "counted", "error"])
        for v in labels:
            w.writerow([v, *(meta[v].get(k, "") for k in extra), labels[v], counts[v], counts[v] - labels[v]])

    tuned_on = f"group {args.tune_group!r}" if args.tune_group else "all videos"
    print(f"tuned on {tuned_on}: {len(tune)} videos, {best['reps']} reps, angle {args.angle}"
          f"{', front frames gated' if args.gate_front else ''}"
          f"{' (current torso only)' if args.gate_front and not standing else ''}")
    for r in results[:5]:
        print(f"  down {r['down']:g} / up {r['up']:g}: {r['accuracy_pct']}% "
              f"({r['exact_videos']}/{r['videos']} videos exact)")

    chosen = f"down {best['down']:g} / up {best['up']:g}"
    if args.test_group:
        test = in_group(args.test_group)
        t = score(test, counts)
        print(f"\nheld-out group {args.test_group!r} at {chosen}: {t['accuracy_pct']}% "
              f"({t['wrong_reps']} wrong of {t['reps']} reps, {t['exact_videos']}/{t['videos']} videos exact)")
    if args.by:
        print(f"\nby {args.by} at {chosen}:")
        buckets = {}
        for v in labels:
            buckets.setdefault(meta[v].get(args.by, ""), []).append(v)
        for key in sorted(buckets):
            b = score(buckets[key], counts)
            print(f"  {key or '-':<12} {b['accuracy_pct']:>5}%  ({b['reps']} reps, {b['videos']} videos)")

if __name__ == "__main__":
    main()
