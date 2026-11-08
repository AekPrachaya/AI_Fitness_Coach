"""Extract joint angles from recorded workout videos, offline.

Mirrors what the app does on device so thresholds can be tuned and rep
counting measured against real footage:

  * angle      — lib/core/utils/angle_calculator.dart, on pixel coordinates
  * side pick  — ExerciseAnalyzer.bestSide, likelihood > 0.65
  * rep count  — lib/core/services/rep_counter.dart, per-exercise hysteresis

On top of the app's 2D angle it also records the same joint angle in 3D
(MediaPipe world landmarks, metres), the time each rep took, and every
landmark of every frame, so the skeletons can be reused to train a model.

The app uses ML Kit, this uses MediaPipe Pose Landmarker. Both are BlazePose
with the same 33 landmarks, but not the identical model, so expect small
differences in the numbers.

Usage:
    python extract_angles.py ~/Downloads/Resources/Squat-dataset --out ~/Downloads/Resources/out
    python extract_angles.py clip.MOV --exercise pushup --overlay
    python extract_angles.py <dir> --labels labels.csv   # video,reps → accuracy

labels.csv has a header row `video,reps`; video is the file name.
"""

from __future__ import annotations

import argparse
import csv
import math
import sys
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path

import cv2
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import mediapipe as mp
import numpy as np
from mediapipe.tasks.python import BaseOptions
from mediapipe.tasks.python.vision import (
    PoseLandmarker,
    PoseLandmarkerOptions,
    RunningMode,
)

MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/pose_landmarker/"
    "pose_landmarker_full/float16/1/pose_landmarker_full.task"
)
MODEL_PATH = Path.home() / ".cache" / "formai" / "pose_landmarker_full.task"

VIDEO_EXTS = {".mov", ".mp4", ".m4v", ".avi"}

# BlazePose landmark indices.
L_SHOULDER, R_SHOULDER = 11, 12
L_ELBOW, R_ELBOW = 13, 14
L_WRIST, R_WRIST = 15, 16
L_HIP, R_HIP = 23, 24
L_KNEE, R_KNEE = 25, 26
L_ANKLE, R_ANKLE = 27, 28

# Same as ExerciseAnalyzer.minLikelihood.
MIN_LIKELIHOOD = 0.65


@dataclass(frozen=True)
class Exercise:
    left: tuple[int, int, int]
    right: tuple[int, int, int]
    down: float
    up: float
    hysteresis: float = 8.0


# Joint triplets and thresholds copied from lib/core/services/analyzers/.
EXERCISES = {
    "squat": Exercise((L_HIP, L_KNEE, L_ANKLE), (R_HIP, R_KNEE, R_ANKLE), 125.0, 160.0),
    "pushup": Exercise((L_SHOULDER, L_ELBOW, L_WRIST), (R_SHOULDER, R_ELBOW, R_WRIST), 90.0, 160.0, 6.0),
    "curl": Exercise((L_SHOULDER, L_ELBOW, L_WRIST), (R_SHOULDER, R_ELBOW, R_WRIST), 50.0, 150.0, 10.0),
    "deadlift": Exercise((L_SHOULDER, L_HIP, L_KNEE), (R_SHOULDER, R_HIP, R_KNEE), 80.0, 160.0),
}


def angle_2d(a, b, c) -> float:
    """Port of calculateAngle(): pixel-space angle at b, in [0, 180]."""
    rad = math.atan2(c[1] - b[1], c[0] - b[0]) - math.atan2(a[1] - b[1], a[0] - b[0])
    deg = abs(rad) * 180.0 / math.pi
    return 360.0 - deg if deg > 180.0 else deg


def angle_3d(a, b, c) -> float:
    """Angle at b between the 3D vectors b→a and b→c."""
    v1, v2 = np.asarray(a) - b, np.asarray(c) - b
    n = np.linalg.norm(v1) * np.linalg.norm(v2)
    if n == 0:
        return float("nan")
    return float(np.degrees(np.arccos(np.clip(np.dot(v1, v2) / n, -1.0, 1.0))))


def from_vertical(top, bottom) -> float:
    """Angle of a segment from vertical, as the squat analyzer measures it."""
    dx, dy = abs(top[0] - bottom[0]), abs(top[1] - bottom[1])
    return math.degrees(math.atan2(dx, dy)) if dy > 0 else float("nan")


def best_side(vis: np.ndarray, left, right):
    """Port of ExerciseAnalyzer.bestSide: the side whose weakest joint is
    most visible, or None when neither side clears MIN_LIKELIHOOD."""
    scores = []
    for side in (left, right):
        worst = min(vis[i] for i in side)
        scores.append(worst if worst > MIN_LIKELIHOOD else None)
    l, r = scores
    if l is None and r is None:
        return None, float("nan")
    if r is None or (l is not None and l >= r):
        return "L", l
    return "R", r


@dataclass
class Rep:
    top_t: float
    bottom_t: float
    end_t: float
    min_angle: float


@dataclass
class RepCounter:
    """Port of RepCounter, recording when each rep's phases happened."""

    down: float
    up: float
    hysteresis: float = 8.0
    phase: str = "waitingDown"
    reps: list[Rep] = field(default_factory=list)
    _top_t: float = 0.0
    _bottom_t: float = 0.0
    _min: float = math.inf

    def update(self, t: float, angle: float) -> None:
        if self.phase == "waitingDown":
            # The last moment standing tall is where the descent starts.
            if angle > self.up:
                self._top_t = t
            if angle < self.down - self.hysteresis:
                self.phase, self._min, self._bottom_t = "down", angle, t
        else:
            if angle < self._min:
                self._min, self._bottom_t = angle, t
            if angle > self.up + self.hysteresis:
                self.reps.append(Rep(self._top_t, self._bottom_t, t, self._min))
                self.phase, self._top_t = "waitingDown", t


def ensure_model() -> Path:
    if not MODEL_PATH.exists():
        MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
        print(f"downloading pose model → {MODEL_PATH}")
        urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
    return MODEL_PATH


# Pairs drawn for the --overlay skeleton.
BONES = [
    (L_SHOULDER, R_SHOULDER), (L_HIP, R_HIP),
    (L_SHOULDER, L_ELBOW), (L_ELBOW, L_WRIST), (R_SHOULDER, R_ELBOW), (R_ELBOW, R_WRIST),
    (L_SHOULDER, L_HIP), (R_SHOULDER, R_HIP),
    (L_HIP, L_KNEE), (L_KNEE, L_ANKLE), (R_HIP, R_KNEE), (R_KNEE, R_ANKLE),
]


def process(video: Path, ex: Exercise, out: Path, width: int, overlay: bool) -> dict:
    cap = cv2.VideoCapture(str(video))
    if not cap.isOpened():
        raise RuntimeError(f"cannot open {video}")
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    n_total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    options = PoseLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(ensure_model())),
        running_mode=RunningMode.VIDEO,
        num_poses=1,
    )

    rows, img_lms, world_lms, times = [], [], [], []
    counter_2d = RepCounter(ex.down, ex.up, ex.hysteresis)
    counter_3d = RepCounter(ex.down, ex.up, ex.hysteresis)
    writer = None

    with PoseLandmarker.create_from_options(options) as landmarker:
        i = 0
        while True:
            ok, frame = cap.read()
            if not ok:
                break
            # OpenCV applies the iPhone rotation flag, so portrait stays portrait.
            h0, w0 = frame.shape[:2]
            if w0 > width:
                frame = cv2.resize(frame, (width, round(h0 * width / w0)), interpolation=cv2.INTER_AREA)
            h, w = frame.shape[:2]
            t = i / fps

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            res = landmarker.detect_for_video(
                mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb), int(t * 1000)
            )

            img = np.full((33, 4), np.nan)
            wld = np.full((33, 4), np.nan)
            row = {"frame": i, "t": round(t, 4), "side": "", "likelihood": "",
                   "angle_2d": "", "angle_3d": "", "shin_deg": "", "torso_deg": ""}

            if res.pose_landmarks:
                for k, lm in enumerate(res.pose_landmarks[0]):
                    # Pixel coordinates, like ML Kit — normalised ones would
                    # distort every angle on a non-square frame.
                    img[k] = (lm.x * w, lm.y * h, lm.z * w, lm.visibility)
                for k, lm in enumerate(res.pose_world_landmarks[0]):
                    wld[k] = (lm.x, lm.y, lm.z, lm.visibility)

                vis = img[:, 3]
                side, score = best_side(vis, ex.left, ex.right)
                if side:
                    a, b, c = ex.left if side == "L" else ex.right
                    a2 = angle_2d(img[a, :2], img[b, :2], img[c, :2])
                    a3 = angle_3d(wld[a, :3], wld[b, :3], wld[c, :3])
                    row.update(side=side, likelihood=round(score, 3),
                               angle_2d=round(a2, 2), angle_3d=round(a3, 2))
                    counter_2d.update(t, a2)
                    counter_3d.update(t, a3)

                # The squat analyzer's shin and torso checks, each on its own best side.
                leg, _ = best_side(vis, (L_KNEE, L_ANKLE), (R_KNEE, R_ANKLE))
                if leg:
                    k_, a_ = (L_KNEE, L_ANKLE) if leg == "L" else (R_KNEE, R_ANKLE)
                    row["shin_deg"] = round(from_vertical(img[k_], img[a_]), 2)
                torso, _ = best_side(vis, (L_SHOULDER, L_HIP), (R_SHOULDER, R_HIP))
                if torso:
                    s_, h_ = (L_SHOULDER, L_HIP) if torso == "L" else (R_SHOULDER, R_HIP)
                    row["torso_deg"] = round(from_vertical(img[s_], img[h_]), 2)

            if overlay:
                if writer is None:
                    writer = cv2.VideoWriter(str(out / f"{video.stem}_overlay.mp4"),
                                             cv2.VideoWriter_fourcc(*"mp4v"), fps, (w, h))
                draw_overlay(frame, img, row)
                writer.write(frame)

            rows.append(row)
            img_lms.append(img)
            world_lms.append(wld)
            times.append(t)
            i += 1
            if i % 100 == 0:
                print(f"  {video.name}: {i}/{n_total}", end="\r", file=sys.stderr)

    cap.release()
    if writer:
        writer.release()

    stem = video.stem
    write_csv(out / f"{stem}_frames.csv", rows)
    write_csv(out / f"{stem}_reps.csv", [
        {"rep": n + 1, "top_t": round(r.top_t, 3), "bottom_t": round(r.bottom_t, 3),
         "end_t": round(r.end_t, 3), "down_s": round(r.bottom_t - r.top_t, 3),
         "up_s": round(r.end_t - r.bottom_t, 3), "total_s": round(r.end_t - r.top_t, 3),
         "min_angle": round(r.min_angle, 2)}
        for n, r in enumerate(counter_2d.reps)
    ])
    # Skeletons for later model training: (frames, 33, x/y/z/visibility).
    np.savez_compressed(out / f"{stem}_landmarks.npz", image=np.array(img_lms),
                        world=np.array(world_lms), t=np.array(times), fps=fps, width=w, height=h)
    plot(out / f"{stem}.png", stem, rows, ex, counter_2d.reps)

    a2 = np.array([r["angle_2d"] for r in rows if r["angle_2d"] != ""], dtype=float)
    a3 = np.array([r["angle_3d"] for r in rows if r["angle_3d"] != ""], dtype=float)
    durs = [r.end_t - r.top_t for r in counter_2d.reps]
    return {
        "video": video.name,
        "frames": len(rows),
        "fps": round(fps, 2),
        "tracked_pct": round(100 * len(a2) / max(len(rows), 1), 1),
        "reps_2d": len(counter_2d.reps),
        "reps_3d": len(counter_3d.reps),
        "min_angle_2d": round(float(a2.min()), 1) if len(a2) else "",
        "min_angle_3d": round(float(a3.min()), 1) if len(a3) else "",
        "mean_abs_2d_3d": round(float(np.nanmean(np.abs(a2 - a3))), 1) if len(a2) else "",
        "mean_rep_s": round(float(np.mean(durs)), 2) if durs else "",
    }


def draw_overlay(frame, img, row) -> None:
    for p, q in BONES:
        if img[p, 3] > MIN_LIKELIHOOD and img[q, 3] > MIN_LIKELIHOOD:
            cv2.line(frame, (int(img[p, 0]), int(img[p, 1])),
                     (int(img[q, 0]), int(img[q, 1])), (0, 255, 0), 2)
    for k in range(33):
        if not np.isnan(img[k, 0]):
            color = (0, 255, 0) if img[k, 3] > MIN_LIKELIHOOD else (0, 0, 255)
            cv2.circle(frame, (int(img[k, 0]), int(img[k, 1])), 3, color, -1)
    label = f"2D {row['angle_2d']}  3D {row['angle_3d']}  side {row['side'] or '-'}"
    cv2.putText(frame, label, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 0), 4)
    cv2.putText(frame, label, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)


def plot(path: Path, title: str, rows, ex: Exercise, reps: list[Rep]) -> None:
    t = [r["t"] for r in rows]
    a2 = [r["angle_2d"] if r["angle_2d"] != "" else np.nan for r in rows]
    a3 = [r["angle_3d"] if r["angle_3d"] != "" else np.nan for r in rows]
    fig, ax = plt.subplots(figsize=(12, 4))
    ax.plot(t, a2, label="2D (app)", lw=1.4)
    ax.plot(t, a3, label="3D (world)", lw=1, alpha=0.7)
    h = ex.hysteresis
    for y, ls, name in [(ex.down, "--", "down"), (ex.down - h, ":", f"down−{h:g}"),
                        (ex.up, "--", "up"), (ex.up + h, ":", f"up+{h:g}")]:
        ax.axhline(y, color="grey", ls=ls, lw=0.8)
        ax.text(t[-1] if t else 0, y, f" {name}", va="center", fontsize=8, color="grey")
    for n, r in enumerate(reps):
        ax.axvline(r.end_t, color="tab:green", lw=0.8, alpha=0.6)
        ax.text(r.end_t, 5, str(n + 1), color="tab:green", fontsize=8, ha="center")
    ax.set(title=f"{title} — {len(reps)} reps (2D)", xlabel="time (s)", ylabel="angle (°)", ylim=(0, 185))
    ax.legend(loc="lower left", fontsize=8)
    fig.tight_layout()
    fig.savefig(path, dpi=110)
    plt.close(fig)


def write_csv(path: Path, rows: list[dict]) -> None:
    if not rows:
        path.write_text("")
        return
    with path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("inputs", nargs="+", type=Path, help="video files or folders of videos")
    p.add_argument("--exercise", choices=EXERCISES, default="squat")
    p.add_argument("--out", type=Path, default=Path("pose_out"))
    p.add_argument("--width", type=int, default=720, help="resize frames to this width before detection")
    p.add_argument("--overlay", action="store_true", help="also write a skeleton overlay video")
    p.add_argument("--labels", type=Path, help="CSV with columns video,reps (true rep counts)")
    args = p.parse_args()

    videos = sorted(
        f for i in args.inputs
        for f in (i.iterdir() if i.is_dir() else [i])
        if f.suffix.lower() in VIDEO_EXTS
    )
    if not videos:
        sys.exit("no videos found")
    args.out.mkdir(parents=True, exist_ok=True)
    ex = EXERCISES[args.exercise]

    labels = {}
    if args.labels:
        with args.labels.open() as f:
            labels = {r["video"]: int(r["reps"]) for r in csv.DictReader(f) if r["reps"].strip()}

    summary = []
    for v in videos:
        print(f"→ {v.name}", file=sys.stderr)
        s = process(v, ex, args.out, args.width, args.overlay)
        if v.name in labels:
            s["true_reps"] = labels[v.name]
            s["error"] = s["reps_2d"] - labels[v.name]
        summary.append(s)
        print(f"  {v.name}: {s['reps_2d']} reps (3D: {s['reps_3d']}), "
              f"tracked {s['tracked_pct']}%, min {s['min_angle_2d']}°", file=sys.stderr)

    # Some videos may have a label and others not; keep every column.
    keys = list(dict.fromkeys(k for s in summary for k in s))
    write_csv(args.out / "summary.csv", [{k: s.get(k, "") for k in keys} for s in summary])

    labelled = [s for s in summary if "true_reps" in s]
    if labelled:
        exact = sum(s["error"] == 0 for s in labelled)
        true_total = sum(s["true_reps"] for s in labelled)
        abs_err = sum(abs(s["error"]) for s in labelled)
        print(f"\nexact count: {exact}/{len(labelled)} videos; "
              f"rep accuracy: {100 * (1 - abs_err / max(true_total, 1)):.1f}% "
              f"({abs_err} wrong of {true_total} reps)")
    print(f"\nwrote {args.out}/summary.csv")


if __name__ == "__main__":
    main()
