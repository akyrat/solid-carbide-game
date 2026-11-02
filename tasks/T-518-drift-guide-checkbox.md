---
id: T-518
title: Drift Guide checkbox in the pause settings
status: in-qa
from: project-lead
to: ui
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [docs/hud-and-menus.md, tasks/T-508-rain-settings-toggle.md, tasks/README.md]
files_expected_to_change: [game/scripts/, game/tests/unit/, docs/hud-and-menus.md]
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

Add the Drift Guide checkbox to the pause screen's settings (docs/hud-and-menus.md, Decisions, "A Drift Guide checkbox"), next to the Rain checkbox (T-508), with T-516's label (drift_guide_label), showing the saved drift_guide_enabled (off by default, T-517), switching the guide at once through T-517's function and saving the choice. Mouse and keyboard work like the other checkboxes; the strip still fits (say if the row needs to wrap). This ticket's branch is built on T-517's and T-516's branches so the board plays one build. Update docs/hud-and-menus.md Content (the pause screen).

The board, 2026-11-02: docs/drifting.md, Decisions, "The Drift Guide", and docs/hud-and-menus.md, Decisions, "A Drift Guide checkbox". The board plays T-516..T-518 together in one playtest build before anything merges or reaches itch.io. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build (T-516, T-517, T-518) from the Project Lead's combined folder (C:\solid-carbide-worktrees\T-518\game\project.godot), before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: the checkbox starts unticked for a new player and shows a saved true as ticked. (QA: pass)
- [ ] A unit test: ticking it turns the guide on at once and saves it; unticking turns it off. (QA: pass)
- [ ] Its label comes from drift_guide_label, not hard-coded (test). (QA: pass)
- [ ] Keyboard navigation reaches it like the other checkboxes (test). (QA: pass)
- [ ] docs/hud-and-menus.md Content describes the checkbox. (QA: pass)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: fail: code - game/tests/unit/hud/test_shared_button.gd line 100 expects 10 + god page buttons for the pause screen, but the new Drift Guide checkbox makes it 11 (34 vs 33); test not updated; full Godot set 2710/2712, reproduced on rerun)
- [ ] A screenshot of the pause screen with the checkbox, and of a drift with the guide on, under art-archive/T-NNN/screenshots/. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-516 and T-517 (both in QA).

### 2026-11-02, In progress → In QA

Drift Guide checkbox is in the pause settings after Rain, off by default, switching the guide at once and saving; row still fits; ready to play in the combined build.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built: drift_guide_check in pause_screen.gd, 4th checkbox in the settings row after Rain; label pause_text('drift_guide_label'); state GameSettings.load_drift_guide_enabled() (off by default); toggle calls save_drift_guide_enabled(on), applying at once via the notifier. Same CheckBox as the others, so keyboard (Space/Enter) and mouse work. The row of four fits the strip, no wrapping (screenshot). Tests: game/tests/unit/test_pause_drift_guide_toggle.gd (6 pass: label from data, default off, saved true shown ticked, toggle saves, mouse click, keyboard, notifier emits at once); test_pause_rain_toggle still passes. Docs: docs/hud-and-menus.md Content updated. Screenshots in art-archive/T-518/screenshots/: pause_checkbox.png (new fixture tests/fixtures/pause_drift_guide_demo, test settings file), drift_guide_on_left.png, drift_guide_on_right.png (T-517 fixtures). Note: run_tests.sh -gselect used (direct gut_cmdln hangs here).

QA round 1: all criteria pass except the full Godot set. Combined branch (T-515..T-518 + master): Godot set 2710/2712 passing; 1 red: test_shared_button.gd test_level_up_and_pause_buttons_are_shared (line 100, pause shared buttons 34, expected 33): the count 10 + god page buttons needs 11 now that the Drift Guide checkbox adds one (same fix T-508 did for Rain). Reproduced on rerun. Screenshots reviewed: pause row of four fits, Drift Guide ticked; guide arc visible in drift. Docs updated. T-518's own 6 tests pass.

QA round 1 fix: test_shared_button.gd pause count 10 -> 11 + god_page_buttons, comment updated. The QA note names only this one red test (the 2712 figure is test count vs the one failing test; no second red named). Ran test_shared_button (12 pass) and all test_pause* files (51 pass).
