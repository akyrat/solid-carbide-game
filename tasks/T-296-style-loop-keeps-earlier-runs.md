---
id: T-296
title: "Style loop: a repeated run adds to the Style review instead of replacing it"
status: open
from: project-lead
to: project-lead
lead: Goal-G-006
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

- [ ] A fake run (`--fake`) on a sandbox copy of a task whose Style review already holds a run leaves that run's text unchanged and adds the new run after it, as a new test in `tools/style_loop/test_loop.py` shows. (QA: pass / fail)
- [ ] A task with two runs can still move to `in-qa` (the QA gate finds its rounds), and a task with an empty Style review still can't, as tests in `tools/test_task_status.py` show. (QA: pass / fail)
- [ ] `python -m unittest discover -s tools -p "test_*.py"` passes. (QA: pass / fail)
- [ ] `tasks/README.md`, "The style loop", says what a repeated run writes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes
