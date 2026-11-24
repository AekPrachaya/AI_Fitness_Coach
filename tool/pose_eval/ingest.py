"""Gather self-recorded clips into one dataset folder and draft their labels.

Each participant uploads into a folder of their own, under whatever name they
picked. This links every clip into one folder under a neutral name
(P01_01.MOV, P01_02.MOV, ...) in the order it was filmed, pairs each with
the clip it should be from the recording plan, and draws a contact sheet per
person so the pairing can be checked by eye before anything is analysed.

People film in order and say the clip number aloud, but retakes and skipped
clips happen: a person whose clip count does not match their plan is marked
`check` and their codes are left for a human to fill in.

Usage:
    python ingest.py --src ~/Downloads/round2_raw --map people.csv \\
        --plan labels_round2_template.csv --dest ~/Downloads/Resources/Squat-dataset-2

    # after extract_angles.py has run over --dest:
    python ingest.py --dest ... --fill-auto pose_out_2/summary.csv

people.csv maps upload folder names to codes: `folder,person` (e.g. `alex,P3`).
Keep it outside the repository — it holds participants' names.
"""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

VIDEO_EXTS = {".mov", ".mp4", ".m4v"}
DRAFT = "labels_draft.csv"


def creation_time(path: Path) -> str:
    """When the clip was filmed, from the container metadata; file time if absent."""
    try:
        out = subprocess.run(
            ["ffprobe", "-v", "error", "-print_format", "json", "-show_entries",
             "format_tags=creation_time,com.apple.quicktime.creationdate", str(path)],
            capture_output=True, text=True, check=True,
        ).stdout
        tags = json.loads(out).get("format", {}).get("tags", {})
        stamp = tags.get("com.apple.quicktime.creationdate") or tags.get("creation_time")
        if stamp:
            return stamp
    except (subprocess.CalledProcessError, json.JSONDecodeError):
        pass
    return f"mtime:{path.stat().st_mtime:.0f}"


def duration(path: Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True,
    ).stdout.strip()
    return float(out) if out else 0.0


def contact_sheet(clips: list[Path], dest: Path) -> None:
    """One frame from the middle of each clip, numbered, in a grid."""
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.image as mpimg
    import matplotlib.pyplot as plt

    tmp = dest.parent / f"_tmp_{dest.stem}"
    tmp.mkdir(exist_ok=True)
    tiles = []
    for i, clip in enumerate(clips, 1):
        tile = tmp / f"{i:02d}.jpg"
        length = duration(clip)
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-ss", f"{length / 2:.2f}", "-i", str(clip),
             "-frames:v", "1", "-vf", "scale=240:-2", str(tile)],
            check=False,
        )
        tiles.append((i, clip.name, length, tile))
    cols = 6
    rows = (len(tiles) + cols - 1) // cols
    fig, axes = plt.subplots(rows, cols, figsize=(cols * 2, rows * 3.6), squeeze=False)
    for ax in axes.flat:
        ax.axis("off")
    for ax, (i, name, length, tile) in zip(axes.flat, tiles):
        if tile.exists():
            ax.imshow(mpimg.imread(tile))
        ax.set_title(f"{i}  {name}\n{length:.0f}s", fontsize=8)
    fig.tight_layout()
    fig.savefig(dest, dpi=90)
    plt.close(fig)
    for t in tmp.iterdir():
        t.unlink()
    tmp.rmdir()


def ingest(args) -> None:
    with args.map.open() as f:
        folder_to_person = {r["folder"].strip(): r["person"].strip() for r in csv.DictReader(f)}
    with args.plan.open() as f:
        plan = defaultdict(list)
        for r in csv.DictReader(f):
            plan[r["person"]].append(r)
    for rows in plan.values():
        rows.sort(key=lambda r: int(r["clip_no"]))

    args.dest.mkdir(parents=True, exist_ok=True)
    draft = []
    for folder in sorted(p for p in args.src.iterdir() if p.is_dir()):
        person = folder_to_person.get(folder.name)
        if person is None:
            print(f"skipping folder {folder.name!r}: not in {args.map.name}", file=sys.stderr)
            continue
        clips = sorted((c for c in folder.rglob("*") if c.suffix.lower() in VIDEO_EXTS),
                       key=creation_time)
        planned = plan.get(person, [])
        matches = len(clips) == len(planned)
        num = int(person.lstrip("P"))
        linked = []
        for i, clip in enumerate(clips, 1):
            name = f"P{num:02d}_{i:02d}{clip.suffix.upper()}"
            link = args.dest / name
            if link.is_symlink() or link.exists():
                link.unlink()
            link.symlink_to(clip.resolve())
            linked.append(link)
            p = planned[i - 1] if matches else {}
            draft.append({
                # The plan's count: 5, or 0 for a dip too small to be a rep.
                "video": name, "reps": p.get("reps", ""), "reps_auto": "", "person": person,
                "group": planned[0]["group"] if planned else "",
                "clip_no": p.get("clip_no", ""), "code": p.get("code", ""),
                "condition": p.get("condition", ""),
                "status": "ok" if matches else "check",
                "notes": "" if matches else f"{len(clips)} clips, plan has {len(planned)}",
            })
        contact_sheet(linked, args.dest / f"_{person}_sheet.jpg")
        flag = "" if matches else f"  <-- CHECK: plan has {len(planned)}"
        print(f"{person}: {len(clips)} clips{flag}")

    with (args.dest / DRAFT).open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(draft[0]))
        w.writeheader()
        w.writerows(draft)
    print(f"\nwrote {args.dest / DRAFT} and a contact sheet per person (_Pn_sheet.jpg)")


def fill_auto(args) -> None:
    """Copy the counter's rep counts in, so a human only checks the odd ones."""
    with args.fill_auto.open() as f:
        counted = {Path(r["video"]).stem: r["reps_2d"] for r in csv.DictReader(f)}
    path = args.dest / DRAFT
    with path.open() as f:
        rows = list(csv.DictReader(f))
    for r in rows:
        r["reps_auto"] = counted.get(Path(r["video"]).stem, "")
    with path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)
    odd = [r["video"] for r in rows if r["reps_auto"] not in ("", "5")]
    print(f"filled reps_auto; {len(odd)} clips not counted as 5 — watch these first: {', '.join(odd)}")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--dest", type=Path, required=True, help="dataset folder to build")
    p.add_argument("--src", type=Path, help="folder holding one upload folder per person")
    p.add_argument("--map", type=Path, help="CSV folder,person")
    p.add_argument("--plan", type=Path, help="labels_round2_template.csv")
    p.add_argument("--fill-auto", type=Path, help="summary.csv from extract_angles.py")
    args = p.parse_args()
    if args.fill_auto:
        fill_auto(args)
    elif args.src and args.map and args.plan:
        ingest(args)
    else:
        p.error("give --src, --map and --plan to ingest, or --fill-auto after extraction")


if __name__ == "__main__":
    main()
