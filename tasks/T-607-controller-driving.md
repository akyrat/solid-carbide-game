---
id: T-607
title: Controller: driving, jump, pause and practice reset
status: open
from: project-lead
to: driving-drift
lead: Controller-support
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/project.godot, game/scripts/driving/car.gd, game/scripts/run/practice_session.gd]
files_expected_to_change: [game/project.godot, game/scripts/run/practice_session.gd, game/scripts/driving/drift_prototype.gd, game/tests/]
model: sonnet
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

Step 1 of controller support (Drifting, Decisions, "Controller support"; the board, 2026-11-09). Add controller bindings next to the keyboard ones, so the car drives with an Xbox-layout controller on the desktop and in the browser build: left stick (x axis, in proportion, small dead zone) and D-pad left/right to car_steer_left/right; right trigger (JOY_AXIS_TRIGGER_RIGHT) to car_accelerate and left trigger to car_reverse, both on or off past about half pull; A (JOY_BUTTON_A) to car_jump, so holding it charges the jump as Space does; Start (JOY_BUTTON_START) to pause. The practice reset (a hard-coded KEY_R in practice_session.gd) becomes an input action, practice_reset, with R and Y (JOY_BUTTON_Y), so R still works exactly as before. Use device -1 (all devices). Keep every keyboard binding as it is. To keep merges clean alongside T-608, add practice_reset straight after the pause action in project.godot's [input] section, and add nothing after toggle_view. Check that car.gd, drift_prototype.gd and anything else the car's input passes through (the wreck's dead controls, the charged jump, the tuning panel's use_keyboard switch) work with the actions as they are; change code only where a key is read directly. No menu work (T-608) and no on-screen button prompts (T-610). Add a line to Drifting, Content, saying where the bindings live. In the result notes, write the browser caveat for the board: a browser reports a controller only after a button is pressed on the focused page.
The board's review: drive a run with a controller (steer with the stick and the D-pad, accelerate and reverse on the triggers, drift, charged jump on A, pause on Start) and reset with Y in the tutorial's practice; the keyboard still works as before.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] project.godot binds the left stick x axis and the D-pad left/right to car_steer_left/right, the right and left triggers to car_accelerate and car_reverse, JOY_BUTTON_A to car_jump and JOY_BUTTON_START to pause, each next to its unchanged keyboard binding (QA reads the [input] section). (QA: pass / fail)
- [ ] A GUT test feeds InputEventJoypadMotion and InputEventJoypadButton events (or Input.parse_input_event with them) and shows the car's steer value follows the stick in proportion past the dead zone, a trigger past half pull accelerates or reverses, and A starts and releases the charged jump as Space does. (QA: pass / fail)
- [ ] A practice_reset action exists with R and JOY_BUTTON_Y; practice_session.gd reads the action instead of KEY_R, and a test shows both R and Y reset the practice car. (QA: pass / fail)
- [ ] The existing keyboard driving tests pass unchanged. (QA: pass / fail)
- [ ] The Web export preset still exports (headless export to a folder outside game/), as the result notes say. (QA: pass / fail)
- [ ] Drifting, Content, says where the controller bindings live; the result notes list every file where input was read and what changed, and say screenshots are not applicable (input only). (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
