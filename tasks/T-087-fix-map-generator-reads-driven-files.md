---
id: T-087
title: Fix: the map generator reads the drivability check's output as sketches
status: done
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
qa_rounds: 1
---

<!--
status: needs-playtest | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
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

Fix: `game/tools/build_mvp_map.py` now reads a sketch only when its name matches `^arrow-\d+\.json$` (`SKETCH_NAME`), so `.fitted.json` and `.driven.json` files are never read. New test `WriteTest.test_only_the_sketches_are_read` puts `.driven.json` and `.fitted.json` files (with junk content) next to the sketches and shows the build result is identical and still has 3 sketches. The existing write test now also ignores `*.driven.*` when it copies the sketches. Running the generator changes nothing apart from line endings (`git diff --ignore-space-at-eol` is empty); the line-ending-only changes were not committed. Tests: game/tools 61 OK, tools 72 OK, GUT TESTS PASSED. The worktree had no `.env`, so I copied it from the main folder (git-ignored).

### QA round 1

- Criterion 1 (game/tools tests): PASS. 61 tests OK.
- Criterion 2 (test with .driven.json and .fitted.json next to sketches): PASS. `WriteTest.test_only_the_sketches_are_read` copies the sketches, adds junk `.driven.json` and `.fitted.json` files beside each, and checks the build result is identical and still 3 sketches. The code filters with `SKETCH_NAME = ^arrow-\d+\.json$`.
- Criterion 3 (generator leaves map and fitted files unchanged): PASS. After `python game/tools/build_mvp_map.py`, `git diff --ignore-space-at-eol` was empty (only line endings differ). Files restored with `git checkout --`.
- Criterion 4 (full GUT and all Python tests): PASS. GUT "TESTS PASSED"; game/tools 61 OK; tools 72 OK.

Note: the GUT run rewrote `.import` files (line endings); they were restored and not committed.

### Board review

Merged on QA's pass (no board review needed), 2026-10-10.
