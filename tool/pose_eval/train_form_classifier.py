"""Train a squat form classifier on pose landmarks and compare it with the rules.

Inputs: image_landmarks.npz (image_landmarks.py) and image_scenes.csv
(image_scenes.py). Classes are the dataset's: good / bad back / bad heel.

Two questions, kept apart:
  1. Model selection — GroupKFold on the train split, one group per scene, so
     frames of the same recording never sit on both sides of a fold.
  2. Final score — fit on all of train, scored once on the test split. In this
     dataset the test split is filmed in scenes the train split never shows
     (image_scenes.py reports any overlap), so it stands in for new people.

The rule baseline is what the app does today, on the same images:
  bad back  if torso_deg > 55  (squatTorsoLean)
  bad heel  if shin_deg  > 40  (squatKneeOverToe — the app has no heel check,
                                 this is the fault that fires when heels rise)
  good      otherwise
plus the same two rules with thresholds re-chosen on train, so the model is
compared against the best the rules can do and not just today's numbers.

Scores are given on every usable image and on the "graded" subset only (knee at
or below 130°, where SquatAnalyzer judges form at all).

Usage:
    python train_form_classifier.py image_landmarks.npz image_scenes.csv \
        --export form_model.json --report results.txt
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import sys
from contextlib import redirect_stdout
from pathlib import Path

import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import confusion_matrix, f1_score
from sklearn.model_selection import GroupKFold
from sklearn.neural_network import MLPClassifier
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

sys.path.insert(0, str(Path(__file__).resolve().parent))
from form_features import FEATURE_NAMES, features  # noqa: E402

CLASSES = ("good", "bad back", "bad heel")
GRADED_KNEE = 130.0
TORSO, SHIN, KNEE = (FEATURE_NAMES.index(n) for n in ("torso_deg", "shin_deg", "knee_deg"))


def load(npz: Path, scenes_csv: Path):
    d = np.load(npz)
    with scenes_csv.open() as fh:
        scene_of = {r["file"]: int(r["scene"]) for r in csv.DictReader(fh)}
    X, y, split, group, files = [], [], [], [], []
    skipped = 0
    for lms, f, s, lab in zip(d["image"], d["path"], d["split"], d["label"]):
        v = features(lms)
        if v is None or lab not in CLASSES:
            skipped += 1
            continue
        X.append(v)
        y.append(CLASSES.index(lab))
        split.append(s)
        group.append(scene_of[str(f)])
        files.append(str(f))
    return (np.array(X), np.array(y), np.array(split), np.array(group), np.array(files), skipped)


def rules(X, torso_max=55.0, shin_max=40.0):
    pred = np.zeros(len(X), int)
    pred[X[:, SHIN] > shin_max] = 2
    pred[X[:, TORSO] > torso_max] = 1  # the app coaches the torso first
    return pred


def tune_rules(X, y):
    best = (-1, 55.0, 40.0)
    for t in np.arange(20, 80.5, 1.0):
        for s in np.arange(10, 60.5, 1.0):
            f = f1_score(y, rules(X, t, s), average="macro")
            if f > best[0]:
                best = (f, float(t), float(s))
    return best[1], best[2]


def models():
    return {
        "logistic": make_pipeline(StandardScaler(), LogisticRegression(C=1.0, max_iter=2000)),
        "random forest": RandomForestClassifier(n_estimators=300, min_samples_leaf=3, random_state=0, n_jobs=-1),
        "mlp": make_pipeline(StandardScaler(), MLPClassifier((32, 16), alpha=1e-3, max_iter=2000,
                                                             early_stopping=True, random_state=0)),
    }


def score(y, pred):
    rec = [float(np.mean(pred[y == c] == c)) if np.any(y == c) else float("nan") for c in range(3)]
    return float(np.mean(pred == y)), float(f1_score(y, pred, average="macro")), rec


def fmt(name, y, pred):
    acc, f1, rec = score(y, pred)
    return (f"  {name:<24} acc {100 * acc:5.1f}%  macro-F1 {100 * f1:5.1f}%  recall "
            + "  ".join(f"{c} {100 * r:5.1f}%" for c, r in zip(("good", "back", "heel"), rec)))


def export_logistic(pipe, path: Path, train_info: dict):
    scaler, lr = pipe.named_steps["standardscaler"], pipe.named_steps["logisticregression"]
    path.write_text(json.dumps({
        "kind": "multinomial_logistic",
        "classes": list(CLASSES),
        "features": list(FEATURE_NAMES),
        "mean": scaler.mean_.round(6).tolist(),
        "scale": scaler.scale_.round(6).tolist(),
        "coef": lr.coef_.round(6).tolist(),
        "intercept": lr.intercept_.round(6).tolist(),
        "trained_on": train_info,
    }, indent=1, ensure_ascii=False))


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("npz", type=Path)
    p.add_argument("scenes", type=Path)
    p.add_argument("--folds", type=int, default=5)
    p.add_argument("--export", type=Path, help="write the logistic model as JSON for the app")
    p.add_argument("--report", type=Path, help="also save the printed results here")
    args = p.parse_args()

    buf = io.StringIO()
    with redirect_stdout(buf):
        run(args)
    print(buf.getvalue(), end="")
    if args.report:
        args.report.write_text(buf.getvalue())


def run(args) -> None:
    X, y, split, group, files, skipped = load(args.npz, args.scenes)
    tr, te = split == "train", split == "test"
    overlap = set(group[tr]) & set(group[te])
    print(f"{len(X)} usable poses ({skipped} skipped: no side tracked well enough)")
    print(f"  train {tr.sum()}  test {te.sum()}  scenes train {len(set(group[tr]))} "
          f"test {len(set(group[te]))}  shared {len(overlap)}")
    for name, m in (("train", tr), ("test", te)):
        print(f"  {name}: " + "  ".join(f"{c} {int(np.sum(y[m] == i))}" for i, c in enumerate(CLASSES)))

    # 1. Cross-validation on train, grouped by scene.
    print(f"\n[1] {args.folds}-fold cross-validation on train, grouped by scene")
    gkf = GroupKFold(n_splits=args.folds)
    Xtr, ytr, gtr = X[tr], y[tr], group[tr]
    cv_pred = {name: np.zeros(len(ytr), int) for name in (*models(), "rules (app today)", "rules (tuned)")}
    for fit_idx, val_idx in gkf.split(Xtr, ytr, gtr):
        for name, m in models().items():
            cv_pred[name][val_idx] = m.fit(Xtr[fit_idx], ytr[fit_idx]).predict(Xtr[val_idx])
        cv_pred["rules (app today)"][val_idx] = rules(Xtr[val_idx])
        t, s = tune_rules(Xtr[fit_idx], ytr[fit_idx])
        cv_pred["rules (tuned)"][val_idx] = rules(Xtr[val_idx], t, s)
    for name, pred in cv_pred.items():
        print(fmt(name, ytr, pred))

    # 2. Fit on all of train, score once on test.
    t, s = tune_rules(Xtr, ytr)
    print(f"\n[2] fit on train, scored on test (rules re-tuned on train: torso > {t:.0f}°, shin > {s:.0f}°)")
    fitted = {name: m.fit(Xtr, ytr) for name, m in models().items()}
    preds = {name: m.predict(X[te]) for name, m in fitted.items()}
    preds["rules (app today)"] = rules(X[te])
    preds["rules (tuned)"] = rules(X[te], t, s)
    graded = X[te][:, KNEE] <= GRADED_KNEE
    yte = y[te]
    print(" all usable test images")
    for name, pred in preds.items():
        print(fmt(name, yte, pred))
    print(f" graded only (knee ≤ {GRADED_KNEE:g}°, n={graded.sum()})")
    for name, pred in preds.items():
        print(fmt(name, yte[graded], pred[graded]))

    for name in ("logistic", "rules (app today)"):
        print(f"\n confusion, {name}, all test (rows true, cols predicted: good back heel)")
        for c, row in zip(CLASSES, confusion_matrix(yte, preds[name], labels=[0, 1, 2])):
            print(f"   {c:<9} " + " ".join(f"{v:5d}" for v in row))

    lr = fitted["logistic"]
    coef = lr.named_steps["logisticregression"].coef_
    print("\n strongest logistic weights (standardised features)")
    for ci, c in enumerate(CLASSES):
        top = np.argsort(-np.abs(coef[ci]))[:5]
        print(f"   {c:<9} " + ", ".join(f"{FEATURE_NAMES[i]} {coef[ci, i]:+.2f}" for i in top))

    if args.export:
        export_logistic(lr, args.export, {"poses": int(tr.sum()), "split": "train",
                                          "classes": {c: int(np.sum(ytr == i)) for i, c in enumerate(CLASSES)}})
        print(f"\nexported logistic model → {args.export}")


if __name__ == "__main__":
    main()
