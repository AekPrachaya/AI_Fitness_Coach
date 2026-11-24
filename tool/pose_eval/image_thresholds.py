"""Choose a form-check threshold on one split of labelled images, test on another.

Reads image_angles.csv. For one measurement and one fault label it finds the
cut-off that best separates fault images from good ones on the train split
(highest balanced accuracy: the mean of faults caught and good images left
alone), then reports how that cut-off — and the app's current one — fare on
the test split. Only images the app would grade are used: a body detected,
the measurement present, and the knee bent below --graded (_analyzeThreshold).

Usage:
    python image_thresholds.py image_angles.csv --measure torso_deg --fault "bad back" --current 55
    python image_thresholds.py image_angles.csv --measure heel_deg --fault "bad heel"
"""

from __future__ import annotations

import argparse
import csv
import statistics


def rates(rows, measure, fault, good, cut):
    pos = [float(r[measure]) for r in rows if r["label"] == fault]
    neg = [float(r[measure]) for r in rows if r["label"] == good]
    caught = sum(v > cut for v in pos) / len(pos) if pos else float("nan")
    false_alarm = sum(v > cut for v in neg) / len(neg) if neg else float("nan")
    return caught, false_alarm, len(pos), len(neg)


def line(name, rows, args, cut):
    caught, fa, npos, nneg = rates(rows, args.measure, args.fault, args.good, cut)
    balanced = (caught + 1 - fa) / 2
    return (f"  {name:<22} > {cut:5.1f}°  caught {100 * caught:5.1f}% of {npos:<4} "
            f"false alarm {100 * fa:5.1f}% of {nneg:<4} balanced {100 * balanced:5.1f}%")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("csv")
    p.add_argument("--measure", required=True, help="column, e.g. torso_deg, heel_deg, shin_deg")
    p.add_argument("--fault", required=True, help="label of the fault images, lower case")
    p.add_argument("--good", default="good")
    p.add_argument("--current", type=float, help="the app's threshold today, to compare")
    p.add_argument("--graded", type=float, default=130, help="only knee angles at or below this")
    p.add_argument("--train", default="train")
    p.add_argument("--test", default="test")
    args = p.parse_args()

    with open(args.csv) as fh:
        all_rows = list(csv.DictReader(fh))
    rows = [r for r in all_rows
            if r["detected"] == "1" and r[args.measure] and r["knee_deg"]
            and float(r["knee_deg"]) <= args.graded and r["label"] in (args.fault, args.good)]
    dropped = sum(1 for r in all_rows if r["label"] in (args.fault, args.good)) - len(rows)
    train = [r for r in rows if r["split"] == args.train]
    test = [r for r in rows if r["split"] == args.test]

    print(f"{args.measure}: '{args.fault}' vs '{args.good}' — {len(rows)} images graded, "
          f"{dropped} left out (no body, no measurement, or knee above {args.graded:g}°)")
    for split, rs in ((args.train, train), (args.test, test)):
        for lab in (args.good, args.fault):
            vals = sorted(float(r[args.measure]) for r in rs if r["label"] == lab)
            if vals:
                q = statistics.quantiles(vals, n=10)
                print(f"  {split:<5} {lab:<9} n={len(vals):<4} p10 {q[0]:5.1f}  median {statistics.median(vals):5.1f}  p90 {q[-1]:5.1f}")

    candidates = sorted({round(float(r[args.measure]), 1) for r in train})
    best = max(candidates, key=lambda c: (lambda t: (t[0] + 1 - t[1]))(rates(train, args.measure, args.fault, args.good, c)))
    print(f"\nchosen on {args.train}:")
    print(line(f"{args.train} (chosen)", train, args, best))
    print(line(f"{args.test} (chosen)", test, args, best))
    if args.current is not None:
        print(line(f"{args.train} (app today)", train, args, args.current))
        print(line(f"{args.test} (app today)", test, args, args.current))


if __name__ == "__main__":
    main()
