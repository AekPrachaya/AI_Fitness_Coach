"""Replay the app's squat form checks over recorded videos, rep by rep.

Reads the *_frames.csv and *_landmarks.npz written by extract_angles.py and
runs each frame through the same steps as WorkoutSessionNotifier:

  BodyView gate → SquatAnalyzer.analyze → judgeableNow(MovementTracker)
  → SessionStats.observe (what history and the summary record)
  → FormCoach confirmation (what the user is actually told)
  → RepCounter, which closes the rep

and reports, per rep, which faults each of the two paths raised. With a
labels file whose `code` column follows the recording checklist, each rep is
also marked with the fault it was meant to show (E2/E3 shallow, E4 knee over
toe, E5 torso lean; anything else none) so precision and recall come out.

Usage:
    python form_eval.py pose_out labels.csv
    python form_eval.py pose_out labels.csv --depth 100 --shin 45 --torso 60
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sweep_thresholds import SIDE_MAX_RATIO, Frame, load_frames  # noqa: E402

# Highest priority first, as FormFault.byPriority orders them for the cue.
TORSO, KNEE, SHALLOW = "torso_lean", "knee_over_toe", "shallow"
FAULTS = [TORSO, KNEE, SHALLOW]
RANGE_OF_MOTION = {SHALLOW}

EXPECTED = {"E2": SHALLOW, "E3": SHALLOW, "E4": KNEE, "E5": TORSO}


class MovementTracker:
    """Port of MovementTracker: flags the frame a descent turns into a rise.

    `rise` is riseToTurn — how far above the descent's low point the angle
    must climb to count as the turnaround, with `bottom` that low point. 5 is
    the app since 2026-11-18; 0 replays the version before, which turned on
    any rise past the noise floor and judged depth on the rising frame.
    """

    def __init__(self, noise_floor: float = 1.5, rise: float = 5, rearm_above: float | None = None):
        self.noise_floor, self.rise, self.rearm_above = noise_floor, rise, rearm_above
        self.reset()

    def reset(self):
        self.last, self.low, self.bottom = None, None, None
        self.phase, self.bottomed_out, self.armed = "still", False, True

    def update(self, angle: float):
        self.bottomed_out = False
        if self.rearm_above is not None and angle > self.rearm_above:
            self.armed = True
        if self.last is None:
            self.last = angle
            return
        if self.rise and self.phase == "descending":
            self.low = min(self.low, angle)
            if angle - self.low >= self.rise:
                self.bottomed_out, self.bottom = self.armed, self.low
                self.phase, self.last = "ascending", angle
                if self.rearm_above is not None:
                    self.armed = False
            return
        delta = angle - self.last
        if abs(delta) < self.noise_floor:
            return
        self.last = angle
        if delta < 0:
            self.phase, self.low = "descending", angle
            return
        if not self.rise and self.phase == "descending":
            self.bottomed_out, self.bottom = True, angle
        self.phase = "ascending"


def analyze(angle, shin, torso, args) -> list[str] | None:
    """Port of SquatAnalyzer.analyze; None = notEvaluated (standing)."""
    if angle > args.analyze:
        return None
    faults = []
    if torso is not None and torso > args.torso:
        faults.append(TORSO)
    if shin is not None and shin > args.shin:
        faults.append(KNEE)
    if angle > args.depth:
        faults.append(SHALLOW)
    return faults


def replay(frames: list[Frame], rows: list[dict], args) -> list[dict]:
    reps = []
    movement = MovementTracker(rise=args.rise, rearm_above=None if args.no_rearm else args.up)
    waiting_down, standing = True, None
    candidate, candidate_frames = None, 0
    rep = None

    def new_rep():
        return {"stats": set(), "cue": set(), "graded": False, "bottom": 999.0, "turns": [],
                "max_shin": 0.0, "max_torso": 0.0}

    rep = new_rep()
    for f, r in zip(frames, rows):
        # BodyView, with the standing torso as the app keeps it.
        if f.angle is not None and f.angle > args.up and f.torso:
            standing = f.torso
        front = (f.shoulder_width is not None and f.torso
                 and f.shoulder_width / max(f.torso, standing or 0) > SIDE_MAX_RATIO)
        if front or f.angle is None:
            candidate, candidate_frames = None, 0  # _coachOn(notEvaluated)
            continue

        angle = f.angle
        shin = float(r["shin_deg"]) if r["shin_deg"] else None
        torso = float(r["torso_deg"]) if r["torso_deg"] else None
        movement.update(angle)

        # The notifier grades the turnaround frame at the low point, so the
        # analyzer sees bottomAngle there — including its 130° cut-off.
        judged = movement.bottom if movement.rise and movement.bottomed_out else angle
        faults = analyze(judged, shin, torso, args)
        if faults is not None:
            # judgeableNow: range-of-motion faults only at the turnaround.
            if not movement.bottomed_out:
                faults = [x for x in faults if x not in RANGE_OF_MOTION]
            rep["graded"] = True
            if movement.bottomed_out:
                rep["turns"].append(round(judged, 1))
            rep["stats"].update(faults)
            rep["bottom"] = min(rep["bottom"], angle)
            if shin is not None:
                rep["max_shin"] = max(rep["max_shin"], shin)
            if torso is not None:
                rep["max_torso"] = max(rep["max_torso"], torso)

        # FormCoach: the top fault has to hold for confirmFrames in a row.
        top = next((x for x in FAULTS if faults and x in faults), None)
        if top is None:
            candidate, candidate_frames = None, 0
        elif top == candidate:
            candidate_frames += 1
        else:
            candidate, candidate_frames = top, 1
        need = 1 if top in RANGE_OF_MOTION else args.confirm
        if top is not None and candidate_frames >= need:
            rep["cue"].add(top)

        # RepCounter closes the rep on the same frame.
        if waiting_down and angle < args.down - args.hysteresis:
            waiting_down = False
        elif not waiting_down and angle > args.up + args.hysteresis:
            waiting_down = True
            if rep["graded"]:
                reps.append(rep)
            rep = new_rep()
    return reps


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("out", type=Path, help="folder written by extract_angles.py")
    p.add_argument("labels", type=Path, help="CSV with a video column; code/person/group optional")
    p.add_argument("--down", type=float, default=125)
    p.add_argument("--up", type=float, default=160)
    p.add_argument("--hysteresis", type=float, default=8)
    p.add_argument("--analyze", type=float, default=130, help="_analyzeThreshold")
    p.add_argument("--depth", type=float, default=90, help="_depthThreshold")
    p.add_argument("--shin", type=float, default=40, help="_shinForwardMax")
    p.add_argument("--torso", type=float, default=55, help="_torsoLeanMax")
    p.add_argument("--confirm", type=int, default=3, help="FormCoach.confirmFrames")
    p.add_argument("--rise", type=float, default=5,
                   help="MovementTracker.riseToTurn (0 = the app before 2026-11-18)")
    p.add_argument("--no-rearm", action="store_true",
                   help="judge every turnaround, not one per rep (the app before the rearm fix)")
    p.add_argument("--group", help="column to split results by: group, person, code, sex")
    p.add_argument("--participants", type=Path, help="CSV keyed by person, adds e.g. sex")
    args = p.parse_args()

    with args.labels.open() as fh:
        labels = [r for r in csv.DictReader(fh) if r.get("video", "").strip()]
    if args.participants:
        with args.participants.open() as fh:
            people = {r["person"]: r for r in csv.DictReader(fh)}
        for lab in labels:
            for k, v in people.get(lab.get("person", ""), {}).items():
                lab.setdefault(k, v)

    out_rows = []
    for lab in labels:
        stem = Path(lab["video"]).stem
        if not (args.out / f"{stem}_frames.csv").exists():
            print(f"skipping {lab['video']!r}: no {stem}_frames.csv", file=sys.stderr)
            continue
        frames = load_frames(args.out, stem, "angle_2d")
        rows = list(csv.DictReader((args.out / f"{stem}_frames.csv").open()))
        expected = EXPECTED.get(lab.get("code", ""), "")
        for n, rep in enumerate(replay(frames, rows, args), 1):
            out_rows.append({
                "video": stem, "rep": n, "code": lab.get("code", ""),
                "person": lab.get("person", ""), "group": lab.get("group", ""),
                "sex": lab.get("sex", ""),
                "expected": expected, "bottom_angle": round(rep["bottom"], 1),
                "max_shin": round(rep["max_shin"], 1), "max_torso": round(rep["max_torso"], 1),
                "stats_faults": "|".join(x for x in FAULTS if x in rep["stats"]),
                "cue_faults": "|".join(x for x in FAULTS if x in rep["cue"]),
                "turnarounds": " ".join(str(t) for t in rep["turns"]),
            })

    with (args.out / "form_per_rep.csv").open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(out_rows[0]))
        w.writeheader()
        w.writerows(out_rows)

    groups = defaultdict(list)
    for r in out_rows:
        groups[r[args.group] if args.group else "all"].append(r)

    print(f"depth {args.depth:g}  shin {args.shin:g}  torso {args.torso:g}  confirm {args.confirm}")
    for g, rs in groups.items():
        print(f"\n[{g}] {len(rs)} graded reps")
        for fault in FAULTS:
            for path in ("stats", "cue"):
                flagged = [r for r in rs if fault in r[f"{path}_faults"].split("|")]
                meant = [r for r in rs if r["expected"] == fault]
                clean = [r for r in rs if r["expected"] != fault]
                false_pos = [r for r in clean if r in flagged]
                line = f"  {fault:<14} {path:<5} flagged {len(flagged):>3}/{len(rs)}"
                line += f"  false alarm {len(false_pos)}/{len(clean)}"
                if meant:
                    caught = [r for r in meant if r in flagged]
                    line += f"  caught {len(caught)}/{len(meant)}"
                print(line)
    print(f"\nwrote {args.out}/form_per_rep.csv")


if __name__ == "__main__":
    main()
