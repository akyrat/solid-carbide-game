---
id: T-296
title: "Style loop: a repeated run adds to the Style review instead of replacing it"
status: in-qa
from: project-lead
to: project-lead
lead: Greenbull
epic: tooling
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [tasks/README.md]
files_to_read_first: [tasks/README.md, tools/style_loop/loop.py, tools/style_loop/run.py, tools/task_status.py, tools/style_loop/test_loop.py, tasks/T-294-art-greenbull-emblem.md]
files_expected_to_change: [tools/style_loop/loop.py, tools/style_loop/test_loop.py, tasks/README.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's PixelLab go for the Greenbull rebrand (2026-10-26) allows up to 12 generations per asset, so the style loop may run up to three times on one asset, each run with an improved brief. In T-294 the loop ran twice, and run 2 erased run 1's record: `loop.py` writes the whole `## Style review` section through `task_status.write_section` (`set_section`), which replaces the section's body. QA failed T-294 for the missing round, and the Project Lead restored it by hand.

Change the loop so a new run on a task whose Style review already holds rounds **keeps the earlier runs** and adds its own after them: each run under its own `### Run N` heading (run 1 is the first; a review written before this change, with bare `### Round N` headings, counts as run 1), with its rounds as `#### Round N` or as `### Run N, round M`, whichever keeps the QA gate in `task_status.py` (it looks for `### Round N` headings; tasks/README.md, "How it is enforced") working: update the gate's pattern if needed, with a test. While a run is going, it rewrites only its own run's part, never an earlier run's. The version files already never overwrite an earlier run's (`v1-2.png`), so only the record changes.

The record of a single run (the usual case) may stay as it is today.

## Acceptance criteria

- [ ] A fake run (`--fake`) on a sandbox copy of a task whose Style review already holds a run leaves that run's text unchanged and adds the new run after it, as a new test in `tools/style_loop/test_loop.py` shows. (QA: pass)
- [ ] A task with two runs can still move to `in-qa` (the QA gate finds its rounds), and a task with an empty Style review still can't, as tests in `tools/test_task_status.py` show. (QA: pass)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes. (QA: pass)
- [ ] `tasks/README.md`, "The style loop", says what a repeated run writes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-26, Open → In progress

Building it in this session: the goal runner waits for reused tickets and doesn't build them, so G-006 needs it done first.

### 2026-10-26, In progress → In QA

Built: a repeated style loop run now adds its own record after the earlier runs instead of replacing them; 5 new tests, 490 tools tests pass. Going to QA.

## Result notes

- `tools/style_loop/loop.py`: `write_record` now reads the Style review once per run (`Spec.earlier`, via `earlier_runs`). With earlier rounds present, they are kept: a single-run review (bare `### Round N`) becomes `### Run 1` with `#### Round N`; a review that already has `### Run N` parts is kept as it is. The new run is written as `### Run N+1` after them, with `#### Round N`, and only that part is rewritten as the run goes. An empty/template-only review, or a first run, is written as before (plain `### Round N`).
- `tools/task_status.py`: the QA gate's `STYLE_ROUND_RE` now matches `### Round N` and `#### Round N`.
- `tasks/README.md`, "The style loop": says what a repeated run writes, and the gate line mentions `#### Round N`.
- Tests: `RepeatedRun` in `tools/style_loop/test_loop.py` (4 tests: run 2 keeps run 1, run 3, only own part rewritten while going, `--fake` run on a sandbox copy), one test in `tools/test_task_status.py` (two runs can go to in-qa, an empty review cannot). Full suite: 490 tests, OK.
- Nothing left open.
- QA round 1: all four criteria pass. Full suite OK (490 tests); RepeatedRun and TextLoop 14 tests OK. Empty review: earlier_runs returns ('', 0), so a first run writes plain `### Round N` as before. The sandbox `--fake` test checks the real ticket is unchanged and the copy has Run 1 and Run 2; run 1's exact text kept is asserted by the second-run test (wrapped one heading level down, as the ticket allows).
