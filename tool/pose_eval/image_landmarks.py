"""Save the full pose of every labelled image, for training a form classifier.

Same layout as image_angles.py (<root>/<split>/<class>/*.jpg), but instead of a
handful of angles it keeps all 33 landmarks, so features can be chosen later
without running pose detection again:

  image   (N, 33, 4)  x, y in pixels, z (MediaPipe's relative depth), visibility
  world   (N, 33, 3)  metres, hip-centred
  size    (N, 2)      image width, height
  path, split, label  one per row; images with no body detected are left out

Usage:
    python image_landmarks.py ~/Downloads/Dataset --out image_landmarks.npz
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np
from mediapipe.tasks.python import BaseOptions
from mediapipe.tasks.python.vision import PoseLandmarker, PoseLandmarkerOptions, RunningMode

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_angles import ensure_model  # noqa: E402

IMAGE_EXTS = {".jpg", ".jpeg", ".png"}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("root", type=Path, help="<root>/<split>/<class>/images")
    p.add_argument("--out", type=Path, default=Path("image_landmarks.npz"))
    args = p.parse_args()

    images = sorted(f for f in args.root.rglob("*") if f.suffix.lower() in IMAGE_EXTS)
    if not images:
        sys.exit("no images found")
    options = PoseLandmarkerOptions(base_options=BaseOptions(model_asset_path=str(ensure_model())),
                                    running_mode=RunningMode.IMAGE, num_poses=1)
    image, world, size, files, splits, labels = [], [], [], [], [], []
    missed = 0
    with PoseLandmarker.create_from_options(options) as lm:
        for i, f in enumerate(images, 1):
            img = cv2.imread(str(f))
            if img is None:
                missed += 1
                continue
            h, w = img.shape[:2]
            res = lm.detect(mp.Image(image_format=mp.ImageFormat.SRGB,
                                     data=cv2.cvtColor(img, cv2.COLOR_BGR2RGB)))
            if not res.pose_landmarks:
                missed += 1
                continue
            image.append([(p.x * w, p.y * h, p.z * w, p.visibility) for p in res.pose_landmarks[0]])
            world.append([(p.x, p.y, p.z) for p in res.pose_world_landmarks[0]])
            size.append((w, h))
            rel = f.relative_to(args.root).parts
            files.append(str(Path(*rel)))
            # Folder names differ in case between splits ("Bad back" / "Bad Back").
            labels.append(rel[-2].strip().lower() if len(rel) >= 2 else "")
            splits.append(rel[0].lower() if len(rel) >= 3 else "")
            if i % 200 == 0:
                print(f"  {i}/{len(images)}", file=sys.stderr)

    np.savez_compressed(args.out, image=np.array(image, np.float32), world=np.array(world, np.float32),
                        size=np.array(size, np.int32), path=np.array(files), split=np.array(splits),
                        label=np.array(labels))
    print(f"wrote {args.out}: {len(files)} poses, {missed} images with no body")


if __name__ == "__main__":
    main()
