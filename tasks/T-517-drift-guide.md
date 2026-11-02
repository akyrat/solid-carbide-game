---
id: T-517
title: The Drift Guide: a predicted-path arrow during a drift
status: in-qa
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [docs/drifting.md, docs/visual-style.md, game/scripts/game/game_settings.gd, tasks/README.md]
files_expected_to_change: [game/scripts/driving/, game/scripts/game/game_settings.gd, game/data/, game/tests/unit/, game/docs/, docs/drifting.md]
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

Build the Drift Guide (docs/drifting.md, Decisions, "The Drift Guide"): a saved setting drift_guide_enabled, off by default (like rain_enabled, T-507/T-510, in GameSettings), and, when it is on, during a drift a gray, semi-transparent arrow drawn in code flat on the isometric ground in front of the car, showing the predicted path for about the next second if the player keeps the current steering and throttle. Predict by stepping the car's own drift model forward with the current input (no physics side effects on the real car), so it bends live with the steering and matches what the car really does; say how it treats walls, ramps, jumps and the end of the drift. It fades towards its tip, fades in when a drift starts and out when it ends, never shows when not drifting, and never when the setting is off. Hard pixel edges, no PixelLab. Its look and prediction numbers in game/data (a _comment, proposals). Expose a function the pause screen (T-518, UI Agent) can call to turn it on and off at once. Write a test that the predicted path matches the real car's path within a tolerance when the input is held for that time. Update docs/drifting.md Content and game/docs. No checkbox in this ticket (T-518 does it).

The board, 2026-11-02: docs/drifting.md, Decisions, "The Drift Guide", and docs/hud-and-menus.md, Decisions, "A Drift Guide checkbox". The board plays T-516..T-518 together in one playtest build before anything merges or reaches itch.io. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build (T-516, T-517, T-518) from the Project Lead's combined folder (C:\solid-carbide-worktrees\T-518\game\project.godot), before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: with the setting off (and with no saved setting) no guide draws during a drift. (QA: pass / fail)
- [ ] A unit test: with it on, the guide shows only while drifting, and fades in and out at a drift's start and end. (QA: pass / fail)
- [ ] A unit test: the predicted path matches where the real car goes when the input is held for the predicted time, within a tolerance the result notes give. (QA: pass / fail)
- [ ] A unit test: changing the steering mid-drift changes the predicted path the same frame or the next. (QA: pass / fail)
- [ ] Its numbers live in game/data with a _comment; docs/drifting.md Content describes the guide and points to them. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots (or a GIF) of the guide during a left and a right drift, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started: the Drift Guide arrow.

### 2026-11-02, In progress → In QA

Drift Guide built: gray predicted-path arrow during a drift, off by default; T-518 calls GameSettings.save_drift_guide_enabled(on). Ready for QA.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. drift_guide.gd (under the car in the run), GameSettings drift_guide_enabled (off default; GameSettings.save_drift_guide_enabled(on) is the function T-518 calls, applies at once via notifier), CarModel.duplicate_state(), Car.last_input, data/drift_guide.json (_comment, proposals), game/docs/driving/drift_guide.md, docs/drifting.md Content. Prediction: 1 s ahead, input held; matches real car within 0.01 units (test). Walls: path ends at Car.test_move hit; ramps/jumps/Space/Rev Charge not predicted; air = not drifting so it fades. Tests: test_drift_guide (10), test_car_collisions, test_rain pass. Screenshots: art-archive/T-517/screenshots/left.png, right.png (fixtures drift_guide_left/right.tscn).
