"""Group labelled images by scene, so frames of one recording stay together.

Image datasets cut from video hold runs of near-identical frames. If those land
on both sides of a cross-validation split, a model is graded on frames it has
all but seen, and the score means little. This clusters images by a 24×24
colour thumbnail — background, lighting and clothing dominate it — and writes
one scene id per image, to be used as the group in GroupKFold.

It is a heuristic: one person filmed in two outfits becomes two scenes, which
is fine for keeping neighbouring frames together.

Usage:
    python image_scenes.py ~/Downloads/Dataset --out image_scenes.csv --sheet scenes.jpg
"""

from __future__ import annotations

import argparse
import collections
import csv
from pathlib import Path

import cv2
import numpy as np
from sklearn.cluster import AgglomerativeClustering

IMAGE_EXTS = {".jpg", ".jpeg", ".png"}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("root", type=Path)
    p.add_argument("--out", type=Path, default=Path("image_scenes.csv"))
    p.add_argument("--distance", type=float, default=12.0, help="Ward linkage cut-off")
    p.add_argument("--sheet", type=Path, help="also write a contact sheet, six frames per scene")
    args = p.parse_args()

    paths = sorted(f for f in args.root.rglob("*") if f.suffix.lower() in IMAGE_EXTS)
    thumbs = []
    for f in paths:
        im = cv2.resize(cv2.imread(str(f)), (24, 24), interpolation=cv2.INTER_AREA)
        thumbs.append(cv2.cvtColor(im, cv2.COLOR_BGR2LAB).astype(np.float32).ravel() / 255)
    scene = AgglomerativeClustering(n_clusters=None, distance_threshold=args.distance,
                                    linkage="ward").fit_predict(np.array(thumbs))

    with args.out.open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["file", "scene"])
        for f, s in zip(paths, scene):
            w.writerow([str(f.relative_to(args.root)), int(s)])

    table = collections.defaultdict(collections.Counter)
    for f, s in zip(paths, scene):
        rel = f.relative_to(args.root).parts
        table[s][f"{rel[0]}/{rel[-2].lower()}"] += 1
    mixed = [s for s, c in table.items() if len({k.split('/')[0] for k in c}) > 1]
    print(f"{len(table)} scenes; {len(mixed)} span more than one split")
    for s, c in sorted(table.items(), key=lambda kv: -sum(kv[1].values())):
        print(f"  scene {s:>3}  {sum(c.values()):>4}  {dict(c)}")

    if args.sheet:
        rows = []
        for s, _ in sorted(table.items(), key=lambda kv: -sum(kv[1].values())):
            idx = np.flatnonzero(scene == s)
            pick = idx[np.linspace(0, len(idx) - 1, 6).astype(int)]
            row = np.hstack([cv2.resize(cv2.imread(str(paths[i])), (90, 120)) for i in pick])
            cv2.putText(row, str(s), (3, 15), 0, 0.5, (0, 0, 255), 2)
            rows.append(row)
        cv2.imwrite(str(args.sheet), np.vstack(rows))


if __name__ == "__main__":
    main()
