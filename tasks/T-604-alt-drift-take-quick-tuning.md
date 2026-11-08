---
id: T-604
title: Quick tuning: a new practice playground and alt drift take, with the board
status: in-progress
from: project-lead
to: ui
lead: Rails
epic: hud
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/level-design.md]
files_to_read_first: [tasks/README.md, tasks/T-574-drift-slides-quick-tuning.md, docs/hud-and-menus.md, docs/level-design.md, game/docs/hud-and-menus/tutorial-slides.md, game/scripts/run/practice_session.gd, game/tools/build_practice_playground.py]
files_expected_to_change: [game/data/level/practice_playground.json, game/data/tutorial_takes/, game/tools/, game/tests/, game/docs/, docs/hud-and-menus.md, docs/level-design.md]
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

Quick tuning with the board (docs/working-with-the-board.md, "Quick tuning"). The board wants to change the tutorial's practice playground (game/data/level/practice_playground.json, Level design, "The practice playground") in the level creator and then re-record the alt drift take (game/data/tutorial_takes/alt_drift.json). In this folder only: (1) make the playground editable in the level creator and saved back to game/data/level/practice_playground.json (say how the board opens and saves it; if build_practice_playground.py would overwrite it, say so and stop it doing that); (2) bring back the take recording controls T-574 removed (F5 to F9 and their buttons, HUD and menus, Decisions, "The tutorial's recorded demos") so the board can re-record the alt drift take. Then tell the Project Lead it is ready, with the exact launch commands for the creator and the game. The board's tweaks come word for word through the Project Lead; write each in the result notes. When the board is happy: remove the recording controls again, keep the new playground and take, check every other tutorial take still does its trick on the new playground (say which ones it changed for, and that a take may need re-recording), update Level design Content and HUD and menus Content, and run the tests.

The board's review: play it from C:\solid-carbide-worktrees\T-604\game\project.godot: the tutorial's alt drift slide plays the new take on the new playground.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (reading is allowed). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The new playground and alt drift take are committed; the alt drift demo pays ALT DRIFT! on the new playground (a test or the recorder's EXPECT check). (QA: pass / fail)
- [ ] The recording controls are gone again (the T-574 tests that check they are gone pass). (QA: pass / fail)
- [ ] The other tutorial takes are checked on the new playground, with the result in the result notes. (QA: pass / fail)
- [ ] docs/level-design.md and docs/hud-and-menus.md Content describe the change. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A screenshot or GIF in art-archive/T-604/screenshots/ shows the alt drift slide with the new take, taken with bash game/tools/screenshot.sh. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the playground editable in the creator and the recording controls back, in this folder only.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Steps 1 and 2 (UI Agent, 2026-11-08): ready for the board's edits and recording, in this folder only.

Step 1, the playground in the level creator: the creator's level list shows only data/levels/, and a file opened from elsewhere was saved as a new file there. New launch argument: `-- --open=<path>` opens that level file straight in the editor, and Save writes back to that same file (LevelCreator.open_arg, open_editor_in_place; LevelCreatorEditor.save_in_place, save_path returns the opened file). Nothing is written in data/levels/. Back to list shows the level list as before; levels opened from the list behave as before. Launch: "C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path C:\solid-carbide-worktrees\T-604\game res://scenes/level_creator/level_creator.tscn -- --open=res://data/level/practice_playground.json . Saved with no edit, the file is written back unchanged (ground_style grid, spawn, rails, ramps, pairs, every key kept; test). Keep the Level name "Practice playground". build_practice_playground.py was already retired by T-574 (it refuses to run and writes nothing), so it cannot overwrite the board's playground. Tests: new test_creator_open_in_place.gd 5/5 (the arg, editor on that file, save back unchanged with nothing in the levels folder, still a grid level with a spawn, the old behaviour without the arg). Fixture: tests/fixtures/creator_practice_playground_demo.tscn.

Step 2, the take tools back (TEMPORARY, T-574 tweak 8 as it was): on each trick slide, in a dev build (run from the project folder or editor, never an export), the row above the practice window: the take state label and F5 Reset (reset the stage), F6 Record (reset and record), F7 Stop + save (saves data/tutorial_takes/<trick>.json, the previous one kept as <trick>.prev.json), F9 Play take; same keys on the keyboard. The alt drift take is recorded on slide 3/6 (ALT DRIFT): F6 to start, F7 to stop and save into data/tutorial_takes/alt_drift.json. The demo, Replay and Skip demo stay as T-574 left them. Code: tutorial_slides.gd (TAKE_KEYS, TAKE_BUTTONS, TAKE_STATE_TEXT, dev_tools_enabled, take_action, set_dev_tools, _process, _update_take_label, _build_take_panel), each marked T-604 TEMPORARY. Tests: T-574's dev-build take tools test is back in test_tutorial_slides.gd; test_the_take_tools_and_f_keys_are_gone is pending while the tools are back (it runs again when they go); test_shared_button counts the take buttons in a dev build. test_tutorial* 86 passed + 1 pending of 87, test_shared_button 12/12, test_practice* 45/45, test_standin_takes 4/4, test_creator* 292/292, test_level_list 6/6, test_editor* 37/37, test_play_level 15/15, all passing.

Screenshots: art-archive/T-604/screenshots/step1_creator_playground.png (the creator open on the playground, name Practice playground), step2_take_tools_alt_drift.png (the alt drift slide with the take tools row above the window).
