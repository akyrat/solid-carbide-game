---
id: T-087
title: Fix: the map generator reads the drivability check's output as sketches
status: open
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, tasks/T-019-build-mvp-map.md, tasks/T-021-challenge-drivability-scripts.md, game/README.md]
files_expected_to_change: [game/tools/build_mvp_map.py, game/tools/test_build_mvp_map.py]
model: sonnet
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

A bug from merging T-019 and T-021 together (found 2026-10-10): `game/tools/build_mvp_map.py` reads every `arrow-*.json` in `docs/level-design/<pattern>/` as a board sketch. T-021's drivability check saves `arrow-*.driven.json` next to the sketches, and T-019 itself writes `arrow-*.fitted.json`, so the generator now also picks up those files. On master, 3 of the Python tool tests in `game/tools` fail (`KeyError: 'boulders'`, and a count of 12 files instead of 6).

Make the generator read only the board's sketches (`arrow-<number>.json`), never `.fitted.json` or `.driven.json` files, and add a test with such files present. The generated map must stay exactly the same.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] `python -m unittest discover -s game/tools -p "test_*.py"` passes on the branch (QA: pass / fail)
- [ ] A test puts `.driven.json` and `.fitted.json` files next to a sketch and shows the generator reads only the sketch (QA: pass / fail)
- [ ] Running `python game/tools/build_mvp_map.py` leaves `game/data/level/mvp_map.json` and the fitted files unchanged (`git diff` is empty) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
