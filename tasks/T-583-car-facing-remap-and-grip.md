---
id: T-583
title: The car points where it goes: frame remap and more grip outside a drift, compared
status: open
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car.gd, game/scripts/driving/car_tuning.gd, game/scripts/driving/car_sprite.gd, game/tests/unit/test_t580_facing_vs_travel.gd]
files_expected_to_change: [game/scripts/driving/, game/data/, game/tests/, game/docs/driving/, docs/drifting.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build fixes A and C of Drifting, Decisions, "The car points where it goes", each switchable in data so they can be compared. A: draw each heading with the frame whose drawing really points that way (T-580's measured drawn angles), for the car sheet and the tilt sheet (car_iso_tilt), so the worst on-screen gap drops (T-580 estimated 55 to 23 degrees). It must still work when T-584 redraws frames 19 to 23, 2 and 3: keep the measured angles in data, with a script that re-measures a sheet so T-584 can refresh them. C: more grip outside a drift (drift_factor or a separate non-drift grip), so after a turn the car straightens within a short time while drifts, the alt drift and the drift tests stay as they are; propose the number with its reason. Then measure with T-580's test every combination (none, A, C, A+C) for its cases (straight along each diagonal, coasting then throttling onto another, turning onto the up-right diagonal) and give a table in the result notes, with your recommendation. Set the data to your recommended combination. Things that depend on the grip (drift tests, tricks, the challenge checks, the tutorial's practice drives) must still pass or be updated with reasons.

The board's review: play it from C:\solid-carbide-worktrees\T-583\game\project.godot, driving along the up-right diagonal and turning onto it; the result notes say how to switch A and C on and off in data to compare.

Read T-580's result notes first (tasks/T-580-facing-vs-velocity-investigation.md on branch task/T-580-facing-vs-velocity-investigation, already merged into your branch) and its measurement test, game/tests/unit/test_t580_facing_vs_travel.gd. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A is built and switchable: with it on, each heading uses the frame that points closest to it, measured (tests). (QA: pass / fail)
- [ ] C is built and switchable: with it on, the car straightens after a turn faster outside a drift, and drifts and alt drifts behave as before (tests). (QA: pass / fail)
- [ ] The result notes have a table of T-580's measurements for none, A, C and A+C, and a recommendation, and the data is set to it. (QA: pass / fail)
- [ ] The drift, trick, challenge and tutorial tests pass, updated with reasons where the grip changed them. (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-583/screenshots/ shows the up-right diagonal before and after. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
