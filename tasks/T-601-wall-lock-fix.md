---
id: T-601
title: Fix: the car locks against a wall with W held
status: open
from: project-lead
to: driving-drift
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car.gd, game/scripts/driving/car_model.gd, game/docs/driving/]
files_expected_to_change: [game/scripts/driving/, game/data/, game/tests/, game/docs/driving/]
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

Fix Drifting, Decisions, "The car never locks against a wall". The board's report (2026-11-08): "if i manage to get the nose of the car close enough to the wall and then i hold acceleration, the car gets locked there and i can't escape whether i press A or D. i am forced to let go of the acceleration, and then i hold S for what feels like a very long time to start going backwards and escape." First reproduce it in a test (a wall, the nose near it at a few angles including straight on and shallow, W held, then W plus A or D; then S alone) and measure: does the car move, how long until it is off the wall, how long S takes to reverse. Then confirm or correct the Project Lead's reading in the decision (car_model.gd step 5: W snaps fwd to cruise unless _bouncing_towards_wall, and bounce_normal is set only when the bounce is above 0; car.gd _bounce/_end_drift_on_hit ends the drift every step in contact; reverse brakes positive fwd at t.ramp_delta, the top-speed ramp), and look at anything else that holds the car (the rotation set on the body without a collision check, _update_bounce_rearm, move_and_collide depenetration). Fix it so W with A or D turns the car off the wall within a short time (propose the number) and S against a wall reverses promptly, while normal driving, the T-435 bounce, the cruise jump in open space, the drift and the wall-hit trick rules stay as they are (their tests pass). Numbers in data with reasons where needed; say what each change does.

The board's review: play it from C:\solid-carbide-worktrees\T-601\game\project.godot: nose into a wall with W held, then steer away; then try S.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test reproduces the lock before the fix (shown failing in the result notes) and passes after. (QA: pass / fail)
- [ ] With W held and A or D, the car leaves the wall within the proposed time at the tested angles (tests). (QA: pass / fail)
- [ ] S against a wall reverses promptly (a test with the time). (QA: pass / fail)
- [ ] Normal driving, wall bounces, the cruise jump, drifts and wall-hit tricks are unchanged (the existing tests pass). (QA: pass / fail)
- [ ] docs/drifting.md Content and game/docs/driving/ explain the cause and the fix. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-601/screenshots/ shows the car steering off a wall with W held, taken with bash game/tools/screenshot.sh frames. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
