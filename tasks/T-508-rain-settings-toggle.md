---
id: T-508
title: The rain toggle in the settings
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/hud-and-menus.md]
files_expected_to_change: [game/scenes/, game/scripts/ui/, game/scripts/menu/, game/tests/unit/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 1
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

The board, 2026-11-02 (docs/level-design.md, Decisions, "Rain over the map"): add a toggle to the settings (the main menu's settings and the pause screen's settings, wherever the other settings show) that turns the rain on or off through T-507's saved setting `rain_enabled`, in the same style as the other toggles (shared button or the existing toggle style, T-446), with T-506's label (no placeholder). Mouse and keyboard work like the rest of the settings. This task's branch is built on T-497's branch, which already holds the board's new weapon trees (T-495 to T-499) and the playtest tier switch (T-500), so the board can play everything in one build. Never write, move or commit anything in game/data/levels/. SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py <id> --append <file>`, never with Edit or Bash on the ticket. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it with another tool or command.

The board's review: play it in the one combined build with the weapon trees (T-495 to T-499), the power-up changes and God mode (T-501 to T-505), from the Project Lead's combined folder, before merging.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The settings show a rain toggle with T-506's label, in every settings screen the other settings appear in (screenshots). (QA: pass; Rain checkbox shows in the pause screen's settings with T-506's label; the pause screen is the only settings screen with checkboxes, the other CheckBox/CheckButton uses are the tutorial's "don't show again" and the dev tuning panel)
- [ ] A test: switching it sets rain_enabled, the rain shows or hides at once, and the choice survives a restart (saved). (QA: pass; test_pause_rain_toggle.gd passes in the full run)
- [ ] Keyboard and mouse both work on it, like the other settings. (QA: pass; the mouse click and Space key tests pass)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass; round 2: both test sets pass, test_shared_button count fixed to 10; documents line passes, docs/hud-and-menus.md changed)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-02, Open → In progress

Started on top of T-507's rain and T-506's label.

### 2026-11-02, In progress → In QA

Rain checkbox in the pause settings; saved and applied at once.

### 2026-11-02, In QA → In progress

QA round 1 failed: test_shared_button.gd expects 9 pause buttons, now 10 (Rain checkbox); docs/hud-and-menus.md not updated. Criteria 1-3 pass.

### 2026-11-02, In progress → In QA

Button count and docs fixed.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done: a Rain checkbox in the pause screen (the game's only settings screen; the main menu has none), in the checkbox row after Dynamic camera, shared checkbox style. Label from data/pause_text.json rain_label (T-506). Starts from GameSettings.load_rain_enabled(); toggling calls save_rain_enabled, so the rain shows or hides at once (T-507 notifier) and the choice is saved. Mouse and keyboard work like the other checkboxes. Tests: game/tests/unit/test_pause_rain_toggle.gd 5/5 (label, default on, saved and read back, real mouse click, keyboard Space, rain layer in a run); test_pause_screen, test_pause_camera_controls, test_pause_slider_saves, test_rain pass. Full set for QA. Screenshots: art-archive/T-508/screenshots/pause_screen_game.png and pause_screen_prototype.png. Documents affected: docs/hud-and-menus.md. Files: game/scripts/ui/pause_screen.gd, game/tests/unit/test_pause_rain_toggle.gd, docs/hud-and-menus.md.

QA round 1 fixes: test_shared_button pause count 9 to 10 (T-508's Rain checkbox), and the docs/hud-and-menus.md Rain checkbox bullet, which had been lost, now committed. test_shared_button 12/12, test_pause_rain_toggle 5/5.
