"""One row per rep: what the app would make of it, and why.

For checking a recording round by eye before trusting any number from it.
Each rep the app would count (125/160, BodyView side-view gate) is judged at
its lowest frame, the way SquatAnalyzer judges it:

  bottom_knee   lowest knee angle — depth is graded against 90°
  model         the form model's verdict (good / bad back / bad heel) and its
                probability, or "gated" when a joint it reads is under 0.85
  rules         the fallback rules: torso lean > 55°, shin > 40°
  view          BodyView ratio at the bottom (≤ 0.35 = side view)
  ankle_lk      likelihood of the near-side ankle; the model and the rep
                counter both need it, the heel and toe they do not
  feet          how many feet ML Kit-equivalent tracking sees (heel and toe
                both over 0.65)
  hands         where the wrists are: front (reaching forward), chest
                (clasped in front of the chest), side (hanging), or ?

And per clip: share of frames with no usable side, and the rep count.

Usage:
    python review_reps.py pose_out_2 form_model.json --labels labels_draft.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from form_features import FEATURE_NAMES, best_side, features, side_joints  # noqa: E402
from speed_eval import reps_with_timing, times  # noqa: E402
from sweep_thresholds import count_reps, load_frames  # noqa: E402

CLASSES = ("good", "bad back", "bad heel")
GATE = 0.85
SEEN = 0.65


def probabilities(model, x):
    z = np.array(model["coef"]) @ ((x - np.array(model["mean"])) / np.array(model["scale"])) + np.array(model["intercept"])
    e = np.exp(z - z.max())
    return e / e.sum()


def hands(lms: np.ndarray, side: int) -> str:
    """Rough wrist placement relative to the shoulder, in torso lengths."""
    sh, hip = lms[11 + side, :2], lms[23 + side, :2]
    torso = math.dist(sh, hip) or 1.0
    wrists = [lms[15 + s] for s in (0, 1) if lms[15 + s, 3] > 0.5]
    if not wrists:
        return "?"
    w = max(wrists, key=lambda r: r[3])
    dx, dy = abs(w[0] - sh[0]) / torso, (w[1] - sh[1]) / torso
    if dx > 0.8 and dy < 0.5:
        return "front"
    if dy > 0.75:
        return "side"
    return "chest"


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("out", type=Path)
    p.add_argument("model", type=Path)
    p.add_argument("--labels", type=Path)
    p.add_argument("--csv", type=Path, help="also write the per-rep table here")
    args = p.parse_args()
    model = json.loads(args.model.read_text())
    K, T, S = (FEATURE_NAMES.index(n) for n in ("knee_deg", "torso_deg", "shin_deg"))

    meta = {}
    if args.labels:
        with args.labels.open() as fh:
            meta = {Path(r["video"]).stem: r for r in csv.DictReader(fh)}

    rows = []
    for fr_csv in sorted(args.out.glob("*_frames.csv")):
        stem = fr_csv.name[: -len("_frames.csv")]
        frames, ts = load_frames(args.out, stem, "angle_2d"), times(args.out, stem)
        img = np.load(args.out / f"{stem}_landmarks.npz")["image"]
        counted = count_reps(frames, 125, 160, 8, True, True)
        no_side = np.mean([best_side(np.nan_to_num(l[:, 3])) is None for l in img])
        m = meta.get(stem, {})
        print(f"\n{stem}  {m.get('code', ''):<3} {m.get('condition', ''):<18} counted {counted}"
              f" (plan {m.get('reps', '?')})  frames with no usable side {100 * no_side:.0f}%")
        index = {round(t, 4): i for i, t in enumerate(ts)}
        for n, (start, low_t, low) in enumerate(reps_with_timing(frames, ts, 125, 160, 8, True), 1):
            lms = np.nan_to_num(img[index[round(low_t, 4)]])
            s = best_side(lms[:, 3])
            x = features(lms)
            view = math.dist(lms[11, :2], lms[12, :2]) / (math.dist(lms[11 + s, :2], lms[23 + s, :2]) or 1) if s is not None else float("nan")
            if x is None:
                verdict = "no side"
            elif min(lms[j, 3] for j in side_joints(s)) < GATE:
                verdict = "gated"
            else:
                pr = probabilities(model, x)
                verdict = f"{CLASSES[int(pr.argmax())]} {pr.max():.2f}"
            rules = []
            if x is not None and x[T] > 55:
                rules.append("lean")
            if x is not None and x[S] > 40:
                rules.append("knee-toe")
            feet = sum(lms[29 + k, 3] > SEEN and lms[31 + k, 3] > SEEN for k in (0, 1))
            row = {"video": stem, "code": m.get("code", ""), "rep": n,
                   "down_s": round(low_t - start, 2), "bottom_knee": round(low, 1),
                   "depth": "ok" if low <= 90 else "shallow", "model": verdict,
                   "rules": "+".join(rules) or "-",
                   "torso": round(float(x[T]), 1) if x is not None else "",
                   "shin": round(float(x[S]), 1) if x is not None else "",
                   "view": round(view, 2), "ankle_lk": round(float(lms[27 + s, 3]), 2) if s is not None else "",
                   "feet": feet, "hands": hands(lms, s) if s is not None else "?"}
            rows.append(row)
            print("  rep {rep}: down {down_s}s  knee {bottom_knee} ({depth})  model {model:<14} rules {rules:<13}"
                  " torso {torso} shin {shin}  view {view}  ankle {ankle_lk}  feet {feet}  hands {hands}".format(**row))
    if args.csv and rows:
        with args.csv.open("w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=list(rows[0]))
            w.writeheader()
            w.writerows(rows)


if __name__ == "__main__":
    main()
