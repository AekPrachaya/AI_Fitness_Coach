"""Measure the squat form angles on still images, one row per image.

For labelled image sets laid out as <root>/<split>/<class>/*.jpg (train/test
folders of Good, Bad back, ...). Each image goes through MediaPipe Pose and
the same measurements the app makes, on pixel coordinates:

  knee_deg   hip–knee–ankle, as SquatAnalyzer's primary angle
  torso_deg  shoulder→hip from vertical (squatTorsoLean)
  shin_deg   knee→ankle from vertical (squatKneeOverToe)
  heel_deg   heel→toe from horizontal, positive when the heel is lifted —
             not checked by the app yet
  view_ratio shoulder width / torso length (BodyView, ≤ 0.35 = side view)

each on the better-tracked side (likelihood > 0.65), blank when it is not.

Usage:
    python image_angles.py ~/Downloads/Dataset --out image_angles.csv
"""

from __future__ import annotations

import argparse
import csv
import math
import sys
from pathlib import Path

import cv2
import mediapipe as mp
from mediapipe.tasks.python import BaseOptions
from mediapipe.tasks.python.vision import PoseLandmarker, PoseLandmarkerOptions, RunningMode

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_angles import MIN_LIKELIHOOD, angle_2d, ensure_model, from_vertical  # noqa: E402

L_SHOULDER, R_SHOULDER, L_HIP, R_HIP = 11, 12, 23, 24
L_KNEE, R_KNEE, L_ANKLE, R_ANKLE = 25, 26, 27, 28
L_HEEL, R_HEEL, L_TOE, R_TOE = 29, 30, 31, 32
IMAGE_EXTS = {".jpg", ".jpeg", ".png"}


def side(pts, vis, left, right):
    """The side whose weakest joint is most visible, as bestSide picks it."""
    scores = [min(vis[i] for i in s) for s in (left, right)]
    ok = [s > MIN_LIKELIHOOD for s in scores]
    if not any(ok):
        return None
    pick = 0 if ok[0] and (not ok[1] or scores[0] >= scores[1]) else 1
    return [pts[i] for i in (left, right)[pick]]


def heel_lift(heel, toe) -> float:
    """Foot angle from horizontal, positive when the heel is above the toe."""
    dx, dy = abs(toe[0] - heel[0]), toe[1] - heel[1]  # image y grows downwards
    return math.degrees(math.atan2(dy, dx)) if dx or dy else float("nan")


def measure(landmarker, path: Path) -> dict:
    img = cv2.imread(str(path))
    if img is None:
        return {}
    h, w = img.shape[:2]
    res = landmarker.detect(mp.Image(image_format=mp.ImageFormat.SRGB,
                                     data=cv2.cvtColor(img, cv2.COLOR_BGR2RGB)))
    if not res.pose_landmarks:
        return {"detected": 0}
    lms = res.pose_landmarks[0]
    pts = [(lm.x * w, lm.y * h) for lm in lms]
    vis = [lm.visibility for lm in lms]
    row = {"detected": 1}
    if leg := side(pts, vis, (L_HIP, L_KNEE, L_ANKLE), (R_HIP, R_KNEE, R_ANKLE)):
        row["knee_deg"] = round(angle_2d(*leg), 2)
    if t := side(pts, vis, (L_SHOULDER, L_HIP), (R_SHOULDER, R_HIP)):
        row["torso_deg"] = round(from_vertical(*t), 2)
        if vis[L_SHOULDER] > MIN_LIKELIHOOD and vis[R_SHOULDER] > MIN_LIKELIHOOD:
            torso = math.dist(*t)
            if torso > 0:
                row["view_ratio"] = round(math.dist(pts[L_SHOULDER], pts[R_SHOULDER]) / torso, 3)
    if s := side(pts, vis, (L_KNEE, L_ANKLE), (R_KNEE, R_ANKLE)):
        row["shin_deg"] = round(from_vertical(*s), 2)
    if f := side(pts, vis, (L_HEEL, L_TOE), (R_HEEL, R_TOE)):
        row["heel_deg"] = round(heel_lift(*f), 2)
    return row


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("root", type=Path, help="<root>/<split>/<class>/images")
    p.add_argument("--out", type=Path, default=Path("image_angles.csv"))
    args = p.parse_args()

    images = sorted(f for f in args.root.rglob("*") if f.suffix.lower() in IMAGE_EXTS)
    if not images:
        sys.exit("no images found")
    options = PoseLandmarkerOptions(base_options=BaseOptions(model_asset_path=str(ensure_model())),
                                    running_mode=RunningMode.IMAGE, num_poses=1)
    fields = ["file", "split", "label", "detected", "knee_deg", "torso_deg", "shin_deg", "heel_deg", "view_ratio"]
    with PoseLandmarker.create_from_options(options) as lm, args.out.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        for i, f in enumerate(images, 1):
            rel = f.relative_to(args.root).parts
            # Folder names differ in case between splits ("Bad back" / "Bad Back").
            label = rel[-2].strip().lower() if len(rel) >= 2 else ""
            split = rel[0].lower() if len(rel) >= 3 else ""
            w.writerow({"file": str(Path(*rel)), "split": split, "label": label, **measure(lm, f)})
            if i % 200 == 0:
                print(f"  {i}/{len(images)}", file=sys.stderr)
    print(f"wrote {args.out} ({len(images)} images)")


if __name__ == "__main__":
    main()
