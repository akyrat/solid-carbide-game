---
id: T-537
title: Pause screen: a Resume button, buttons stacked vertically and reordered
status: done
from: project-lead
to: ui
lead: Rails
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-533]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/scenes/, game/data/pause_text.json, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 2
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

Build HUD and menus, Decisions, "Resume on the pause screen, buttons stacked". Add a Resume button (the shared button style; label exactly T-533's text, in game/data/pause_text.json) that does what Escape does. Stack the pause screen's buttons vertically, one under the other, in a sensible order with Resume first; propose the order (for example Resume, Trick list, Edit HUD layout, Restart, Exit) and give the reason in the result notes. The screen must still scale with the window and fit at 1280x720 and at the smallest supported size; keyboard navigation must reach every button in the new order. Keep the God mode entry working.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Pressing Resume closes the pause screen and the run carries on, as Escape does (test). (QA: pass)
- [ ] The buttons are in one vertical column, in the order given in the result notes, with Resume first, and keyboard navigation follows that order (test). (QA: pass)
- [ ] The whole pause screen stays inside the window at 1280x720 (test or screenshot). (QA: pass)
- [ ] docs/hud-and-menus.md Content describes the new layout. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass, round 2)
- [ ] Screenshots in art-archive/T-537/screenshots/ show the new pause screen at 1280x720 and at a large window. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees\T-537.

### 2026-11-05, In progress → In QA

Built: pause buttons in one column, Resume, Trick list, Edit HUD layout, Restart, Exit (then God mode). QA is checking it.

### 2026-11-06, In QA → In progress

QA round 1 failed: the stacked column makes the pause strip taller than its height limit, and a button-count test needs updating. Back to the agent: the column goes beside the settings so the strip stays short.

### 2026-11-06, In progress → In QA

Fixed: the button column sits right of the settings, so the strip keeps its height. QA round 2.

### 2026-11-06, In QA → Needs playtest

QA round 2 passed. In the combined playtest build: C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built. Pause screen buttons now one vertical column (VBox RunButtonsColumn): Resume, Trick list, Edit HUD layout (run only), Restart, Exit, God mode (when unlocked). Resume text 'Resume' = T-533, new key resume_button in game/data/pause_text.json; pressing it calls resume() (same as Escape). Order reason: safe/most-used first; screens that return next; Restart and Exit (end the run) together at bottom, away from accidental hits; secret entry last. Keyboard: focus starts on Resume (was Restart); Up/Down/Tab/Shift+Tab walk the column in order and wrap (explicit focus neighbours, relinked when God mode joins). Proposals for playtest: button gap 4 px (BUTTON_GAP const), buttons full strip-content width (520). Tests: new game/tests/unit/game/test_pause_resume_stack.gd (6 pass: text, resume unpauses, column order and one x, keyboard order, God mode last, fits 720); updated test_pause_restart_exit (focus on Resume). Also green: pause_restart_exit, pause_trick_list, god_mode_page, pause_slider_saves, hud_layout_editor, hud_style, hud_size_slider, drift_guide/rain toggle. Full sets not run (QA). Screenshots in art-archive/T-537/screenshots/: pause_1280.png (1280x720), pause_large.png (2560x1440), pause_small.png (960x540), pause_god.png (God mode entry); fixtures game/tests/fixtures/pause_stack_*.tscn. Docs: docs/hud-and-menus.md Content updated (new bullet, Restart/Trick list wording).

QA round: criteria 1,2,3,4,6 pass (screenshot 1280 checked: inside window, Resume first). Criterion 5 fail (code): full Godot run 2744 tests, 3 failing, all caused by this change: hud/test_shared_button (pause shared buttons now 35, test expects 34, line 100) and game/test_screen_flow strip tests (strip height 354 vs limit 259.2 'thin band'; 436 vs 380 'compact') since the stacked column makes the strip taller. Both reproduced on rerun of the single files. Fix: update the expected count and height limits (proposal for playtest) and record counts in result notes.

QA round 1 fix: button column moved to the right of the settings (new HBox StripColumns: settings left, 200 px column right, 32 px gap; consts BUTTON_COLUMN_WIDTH, COLUMN_GAP, proposals), so the strip height is back within test_screen_flow's limits. test_shared_button pause count 11 -> 12 (Resume). Order and keyboard unchanged. Foreground runs, all green: test_shared_button 12/12, test_screen_flow 28/28, test_pause_resume_stack 6/6, test_pause_restart_exit 4/4, test_pause_trick_list 8/8, test_god_mode_page 8/8, test_pause_slider_saves 8/8, test_hud_layout_editor 13/13. Screenshots in art-archive/T-537/screenshots/ retaken (1280, 2560x1440, 960x540, God mode). docs/hud-and-menus.md updated.

QA round 2: all 6 criteria pass. Full sets green (game/tools and godot; tools set skipped, nothing under tools/ changed); the 3 earlier failures are fixed. New screenshot checked: Resume first in a column right of the settings, inside 1280x720.
- 2026-11-06, needs-playtest → done: The board played the combined build: lgtm.
