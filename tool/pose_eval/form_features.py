"""Pose → feature vector for the form classifier.

Every feature is something the app can compute from one ML Kit pose on the
phone (33 landmarks, pixel x/y, a likelihood each), so a model trained on these
can run in Dart without anything new from the camera:

  * the better-tracked side, as ExerciseAnalyzer.bestSide picks it
  * mirrored so the person always faces +x (the nose is ahead of the ear)
  * hip at the origin, lengths in units of that side's torso
    (shoulder→hip), so camera distance and body size drop out
  * the joint angles the rules already use, plus a few they do not

No heel or toe. A first version read them, and on the phone it called flat
heels lifted: with the camera propped high and the toes turned out a little,
perspective drops the toe below the heel in the image, and side-on the far
foot hides behind the near one and gets placed at random. Without the feet the
model still caught every heel lift on held-out images — a lifted heel shows in
the shin and knee too — and warned on far fewer good squats.

FEATURE_NAMES lists the columns in order; the Dart port must keep it.
"""

from __future__ import annotations

import math

import numpy as np

MIN_LIKELIHOOD = 0.65

NOSE = 0
# BlazePose / ML Kit indices, (left, right).
EAR = (7, 8)
SHOULDER = (11, 12)
HIP = (23, 24)
KNEE = (25, 26)
ANKLE = (27, 28)
CHAIN = (EAR, SHOULDER, HIP, KNEE, ANKLE)
# The joints a side must track well to be used at all.
REQUIRED = (SHOULDER, HIP, KNEE, ANKLE)

POINT_NAMES = ("ear", "shoulder", "knee", "ankle")  # hip is the origin
FEATURE_NAMES = tuple(f"{n}_{a}" for n in POINT_NAMES for a in ("x", "y")) + (
    "knee_deg",     # hip–knee–ankle (SquatAnalyzer's rep angle)
    "hip_deg",      # shoulder–hip–knee
    "torso_deg",    # shoulder→hip from vertical (squatTorsoLean)
    "shin_deg",     # knee→ankle from vertical (squatKneeOverToe)
    "neck_deg",     # ear–shoulder–hip
    "thigh_deg",    # hip→knee from horizontal
)


def _angle(a, b, c) -> float:
    """Angle at b, degrees, as ExerciseAnalyzer computes it (atan2 difference)."""
    r = math.atan2(c[1] - b[1], c[0] - b[0]) - math.atan2(a[1] - b[1], a[0] - b[0])
    d = abs(math.degrees(r))
    return 360 - d if d > 180 else d


def _from_vertical(top, bottom) -> float:
    return math.degrees(math.atan2(abs(top[0] - bottom[0]), abs(top[1] - bottom[1])))


def best_side(vis) -> int | None:
    """0 for left, 1 for right, None when neither side is tracked well enough."""
    scores = [min(vis[j[s]] for j in REQUIRED) for s in (0, 1)]
    ok = [sc > MIN_LIKELIHOOD for sc in scores]
    if not any(ok):
        return None
    return 0 if ok[0] and (not ok[1] or scores[0] >= scores[1]) else 1


def side_joints(side: int) -> list[int]:
    """Indices of every joint the features read for that side, nose included."""
    return [NOSE] + [j[side] for j in CHAIN]


def features(lms: np.ndarray) -> np.ndarray | None:
    """lms: (33, 4) pixel x, y, z, visibility. None when the body is not usable."""
    vis = lms[:, 3]
    s = best_side(vis)
    if s is None:
        return None
    pts = {name: lms[j[s], :2].astype(float) for name, j in zip(
        ("ear", "shoulder", "hip", "knee", "ankle"), CHAIN)}
    torso = math.dist(pts["shoulder"], pts["hip"])
    if torso < 1e-6:
        return None
    facing = 1.0 if lms[NOSE, 0] >= pts["ear"][0] else -1.0
    hip = pts["hip"]
    rel = {k: ((v[0] - hip[0]) * facing / torso, (v[1] - hip[1]) / torso) for k, v in pts.items()}

    ea, sh, hp, kn, an = (rel[k] for k in ("ear", "shoulder", "hip", "knee", "ankle"))
    thigh = math.degrees(math.atan2(kn[1] - hp[1], abs(kn[0] - hp[0]) or 1e-9))
    out = [c for n in POINT_NAMES for c in rel[n]] + [
        _angle(hp, kn, an), _angle(sh, hp, kn), _from_vertical(sh, hp), _from_vertical(kn, an),
        _angle(ea, sh, hp), thigh,
    ]
    return np.array(out, np.float32)
