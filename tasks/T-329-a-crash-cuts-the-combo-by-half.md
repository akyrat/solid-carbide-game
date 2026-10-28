---
id: T-329
title: A crash cuts the combo by 50%, not 80%
status: open
from: project-lead
to: game-data
lead: Tokens
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/data/combo.json, game/scripts/data/combo_data.gd, game/scripts/run/run_state.gd]
files_expected_to_change: [game/data/combo.json, game/scripts/run/run_state.gd, game/tests/unit/, game/README.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "A crash cuts the combo by 50%", 2026-10-28): breaking the combo (a collision with a wall, a building, the map edge or a boulder, or any damage to the car) now cuts the part of the multiplier above "no combo" by 50% instead of 80%. So x4 becomes x2.5 (today x1.6), and the cap x6 becomes x3.5 (today x2).

Today the cut is `collision_cut: 0.8` in `game/data/combo.json`, applied by `ComboData.after_collision` (`new = start + (old - start) * (1 - collision_cut)`); only the number changes, not the formula. Also update the comments and docs that name the 80%: the comment on `RunState.collision()` in `game/scripts/run/run_state.gd`, `game/README.md` (the `collision()` row and any other mention), the header comment of `game/tests/unit/run/test_run_combo.gd`, and Game loop architecture, Content (the "Hitting a wall..." line). The "combo broken" popup still shows whenever the multiplier went down, as today.

The board's review: play a run, crash with a high combo and feel how much is left.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `combo.json`'s `collision_cut` is 0.5. (QA: pass / fail)
- [ ] A test checks that a collision at x4.0 leaves x2.5 and at x6.0 leaves x3.5, and that a collision at x1.0 leaves x1.0 with no "combo broken" signal. (QA: pass / fail)
- [ ] Every test that assumed 0.8 is updated, and none is weakened beyond the number change (the result notes list them). (QA: pass / fail)
- [ ] No comment or doc in `game/` or `docs/` still describes the collision cut as 80% (outside the timeline and dated Decisions entries); Game loop architecture, Content and `game/README.md` say 50%. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
