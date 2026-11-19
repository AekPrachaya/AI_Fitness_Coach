# pose_eval

Offline tools that replay recorded workouts through the app's own logic, so
thresholds are measured against hand-counted footage instead of guessed.

| Script | Does |
|---|---|
| `ingest.py` | Gathers per-person upload folders into one dataset, names clips `P01_01.MOV…` in filming order, pairs them with the recording plan, draws a contact sheet per person |
| `extract_angles.py` | Runs MediaPipe Pose over each video: per-frame 2D/3D joint angles, every landmark (`*_landmarks.npz`), rep timings, angle plots, optional skeleton overlay |
| `sweep_thresholds.py` | Scores every down/up pair for rep counting; can tune on one group and report on a held-out one |
| `form_eval.py` | Replays the squat form checks rep by rep — what history records and what the user is told |

Needs Python 3.12 (MediaPipe has no wheels for 3.14):

```bash
python3.12 -m venv .venv && .venv/bin/pip install -r tool/pose_eval/requirements.txt
```

## A recording round, end to end

Videos and the folder-to-person map show participants' faces and names: keep
them outside the repository.

```bash
R=~/Downloads/Resources
T=tool/pose_eval

# 1. Gather uploads → $R/Squat-dataset-2 (+ labels_draft.csv, _Pn_sheet.jpg)
python $T/ingest.py --src $R/round2_raw --map $R/people.csv \
    --plan report_findings/data/round2_template/labels_round2_template.csv \
    --dest $R/Squat-dataset-2

# 2. Check each contact sheet; fix rows marked `check` in labels_draft.csv

# 3. Angles at the app's own resolution (ResolutionPreset.medium = 480 wide)
python $T/extract_angles.py $R/Squat-dataset-2 --out $R/pose_out_2 --width 480

# 4. Pre-fill the counter's reps; watch the clips it lists, correct `reps`
python $T/ingest.py --dest $R/Squat-dataset-2 --fill-auto $R/pose_out_2/summary.csv

# 5. Rep counting: tune on the tune group, report the test group once
python $T/sweep_thresholds.py $R/pose_out_2 $R/Squat-dataset-2/labels_draft.csv \
    --gate-front --tune-group tune --test-group test \
    --by sex --participants report_findings/data/round2_template/participants_template.csv

# 6. Form checks, split by group
python $T/form_eval.py $R/pose_out_2 $R/Squat-dataset-2/labels_draft.csv --group group
```

`reps` in the plan is 5, or 0 for clip code E3 (a dip too small to count).
Never move a threshold because of a test-group result — that turns the test
group into a second tune group and the number reported stops meaning anything.
