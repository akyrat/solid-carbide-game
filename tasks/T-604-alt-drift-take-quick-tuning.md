---
id: T-604
title: Quick tuning: a new practice playground and alt drift take, with the board
status: done
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

Quick tuning with the board (docs/working-with-the-board.md, "Quick tuning"). The board wants to change the tutorial's practice playground (game/data/level/practice_playground.json, Level design, "The practice playground") in the level creator and then re-record the alt drift take (game/data/tutorial_takes/alt_drift.json). In this folder only: (1) make the playground editable in the level creator and saved back to game/data/level/practice_playground.json (say how the board opens and saves it; if build_practice_playground.py would overwrite it, say so and stop it doing that); (2) bring back the take recording controls T-574 removed (F5 to F9 and their buttons, HUD and menus, Decisions, "The tutorial's recorded demos") so the board can re-record the alt drift take. Then tell the Project Lead it is ready, with the exact launch commands for the creator and the game. The board's tweaks come word for word through the Project Lead; write each in the result notes. When the board is happy: remove the recording controls again, keep the new playground and take, check every other tutorial take still does its trick on the new playground (say which ones it changed for, and that a take may need re-recording), update Level design Content and HUD and menus Content, and run the tests.

The board's review: play it from C:\solid-carbide-worktrees\T-604\game\project.godot: the tutorial's alt drift slide plays the new take on the new playground.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (reading is allowed). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The new playground and alt drift take are committed; the alt drift demo pays ALT DRIFT! on the new playground (a test or the recorder's EXPECT check). (QA: pass)
- [ ] The recording controls are gone again (the T-574 tests that check they are gone pass). (QA: pass)
- [ ] The other tutorial takes are checked on the new playground, with the result in the result notes. (QA: pass)
- [ ] docs/level-design.md and docs/hud-and-menus.md Content describe the change. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A screenshot or GIF in art-archive/T-604/screenshots/ shows the alt drift slide with the new take, taken with bash game/tools/screenshot.sh. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: the playground editable in the creator and the recording controls back, in this folder only.

### 2026-11-09, In progress

The board's playground and alt drift take are in. The take tools are removed again, and the tests pass. The air 360 and grind demos stray on the new map, and the grind demo no longer completes its goal. Held for the board to re-record those two in the morning.

### 2026-11-09, In progress → In QA

Agent done: the board's playground and takes are in, every demo lands its trick, recording removed; QA's checks passed.

### 2026-11-09, In QA → Needs playtest

QA passed all 6 criteria. Play the tutorial from C:\solid-carbide-worktrees\T-604\game.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Steps 1 and 2 (UI Agent, 2026-11-08): ready for the board's edits and recording, in this folder only.

Step 1, the playground in the level creator: the creator's level list shows only data/levels/, and a file opened from elsewhere was saved as a new file there. New launch argument: `-- --open=<path>` opens that level file straight in the editor, and Save writes back to that same file (LevelCreator.open_arg, open_editor_in_place; LevelCreatorEditor.save_in_place, save_path returns the opened file). Nothing is written in data/levels/. Back to list shows the level list as before; levels opened from the list behave as before. Launch: "C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" --path C:\solid-carbide-worktrees\T-604\game res://scenes/level_creator/level_creator.tscn -- --open=res://data/level/practice_playground.json . Saved with no edit, the file is written back unchanged (ground_style grid, spawn, rails, ramps, pairs, every key kept; test). Keep the Level name "Practice playground". build_practice_playground.py was already retired by T-574 (it refuses to run and writes nothing), so it cannot overwrite the board's playground. Tests: new test_creator_open_in_place.gd 5/5 (the arg, editor on that file, save back unchanged with nothing in the levels folder, still a grid level with a spawn, the old behaviour without the arg). Fixture: tests/fixtures/creator_practice_playground_demo.tscn.

Step 2, the take tools back (TEMPORARY, T-574 tweak 8 as it was): on each trick slide, in a dev build (run from the project folder or editor, never an export), the row above the practice window: the take state label and F5 Reset (reset the stage), F6 Record (reset and record), F7 Stop + save (saves data/tutorial_takes/<trick>.json, the previous one kept as <trick>.prev.json), F9 Play take; same keys on the keyboard. The alt drift take is recorded on slide 3/6 (ALT DRIFT): F6 to start, F7 to stop and save into data/tutorial_takes/alt_drift.json. The demo, Replay and Skip demo stay as T-574 left them. Code: tutorial_slides.gd (TAKE_KEYS, TAKE_BUTTONS, TAKE_STATE_TEXT, dev_tools_enabled, take_action, set_dev_tools, _process, _update_take_label, _build_take_panel), each marked T-604 TEMPORARY. Tests: T-574's dev-build take tools test is back in test_tutorial_slides.gd; test_the_take_tools_and_f_keys_are_gone is pending while the tools are back (it runs again when they go); test_shared_button counts the take buttons in a dev build. test_tutorial* 86 passed + 1 pending of 87, test_shared_button 12/12, test_practice* 45/45, test_standin_takes 4/4, test_creator* 292/292, test_level_list 6/6, test_editor* 37/37, test_play_level 15/15, all passing.

Screenshots: art-archive/T-604/screenshots/step1_creator_playground.png (the creator open on the playground, name Practice playground), step2_take_tools_alt_drift.png (the alt drift slide with the take tools row above the window).

Finishing steps (UI Agent, 2026-11-08, after the board's "ive rerecorded with the new level"):

1. The board's new playground and alt drift take are committed: game/data/level/practice_playground.json (saved from the creator: spawn moved from (-7, -1) to (-4.25, 1); jump ramp ramp-2 removed; 12 props moved and pairs 3, 4, 6, 7 re-made; a needle route route-1 (pairs 1, 6, 7, random); an empty "hints" list; rails and platforms unchanged) and game/data/tutorial_takes/alt_drift.json (5.38 s; the previous take kept as alt_drift.prev.json). On replay the alt drift take pays ALT DRIFT! three times and completes its goal, following its own checkpoints exactly (0.00 units off). New test tests/unit/run/test_check_takes.gd checks it (ALT DRIFT! at least once, did its trick, under 0.05 units off).

2. The recording controls are removed again: tutorial_slides.gd, test_tutorial_slides.gd and test_shared_button.gd are back to T-574's final versions (no TAKE_KEYS, buttons or dev_tools_enabled); T-574's test_the_take_tools_and_f_keys_are_gone runs and passes (no longer pending). The creator's --open=<path> (step 1) stays: it is how the board edits the playground.

3. The other takes on the new playground (new tool game/tools/check_takes.gd, which replays every take and changes nothing; run: "<godot>" --headless --path game -s res://tools/check_takes.gd). None was changed.
- drift (4.3 s): still completes its goal, but strays 3.4 units from its recorded path. Fine to keep.
- air_spin (7.2 s): still pays one AIR 360!, but strays 33.8 units from its path: the demo no longer drives what the board recorded. Re-record recommended.
- grind (15.8 s): pays 1 grind (was 5, goal done) and strays 18.7 units; the demo no longer completes the slide's goal. Re-record recommended.
On the old playground (checked by swapping the old file in and back) all three followed their path exactly (0.00), so the change is the moved spawn and props.

Tests changed for the new playground (the scripted routes and the spawn were the old layout's): test_practice_session.gd AIR_ROUTE now goes wide to (-32, 22.5) before turning east (from the new spawn the old turn made the car circle; slow until waypoint 4), GRIND_ROUTE's first two points moved ((2, 6), (-6, 7)); the pair test drives east across pair-1's new gap at y 4.25; test_practice_take.gd reads the spawn from the playground instead of (-7, -1); test_creator_hints.gd accepts an empty hints list on the playground; tools/standin_recorder.gd uses the same new routes (its stand-ins do their tricks again; no live take is a stand-in, so none was written).

4. Docs: Level design, Content, "The practice playground" (the board's layout now, how to open and save it with --open, takes recorded from the spawn); HUD and menus, Content, new "The recorded demos' takes" (the four takes, the alt drift re-recording, check_takes.gd and this check's result). Also game/docs/level/level-creator.md (opening a file to save in place) and game/docs/hud-and-menus/tutorial-slides.md (the T-604 entry).

6. Screenshot: art-archive/T-604/screenshots/alt_drift_new_take.png (the alt drift slide playing the board's new take on the new playground, no recording row; Skip demo and Replay under the window).

Fix found by the full run (code: game/scripts/run/practice_session.gd): the board's new needle route (route-1, random order) made take replays inexact. reset_stage() rebuilt the routes with a fresh random start each time, so whether a pass between pair-1's props paid THREAD THE NEEDLE! (and nudged the car) differed between a recording and its replay; test_a_charged_jump_replays_charged failed about half the time (0.018 units off). Now a reset stage seeds the routes with a fixed seed (NEEDLE_ROUTE_SEED 604, _fix_needle_routes), so every recording and replay start with the same active pairs. The demos still replay as checked above (the same results after the fix).

5. Tests: full Godot set (GUT_TIME_LIMIT=2400): 3257 of 3258 passed, 1 pending, 0 failing (231 s). game/tools Python set: 1193 tests OK (4 skipped). New tests: test_check_takes.gd 3/3; test_creator_open_in_place.gd 5/5.

Tweak (board, 2026-11-09): "I'm gonna need you to add back the recording buttons because the grind tutorial is really bad and I need to fix that. Everything else looks okay though, even the air spins, even though I don't complete the goal, it's okay. We just we should just make that be one spin for the mission for that one."

1. Take tools back (TEMPORARY, the same as step 2 before): the row above each trick slide's practice window, dev runs only, F5 Reset, F6 Record, F7 Stop + save, F9 Play take (keys and buttons). The grind take is recorded on slide 5/6 (Grind style): F6 to start, F7 to stop and save game/data/tutorial_takes/grind.json (the old one kept as grind.prev.json). T-574's "take tools are gone" test is pending again while they are back; the dev-build take tools test is back; test_shared_button counts the take buttons.

2. The air spin slide's goal is one (HUD and menus, Decisions, "The air spin slide asks for one spin"). Where it lives: game/scripts/run/practice_session.gd. GOAL (3) is still the default; new GOAL_BY_TRICK {"air_spin": 1} and goal_count(), used for the notebook mission's amount, progress, the completion, the stamp and the falling boxes. The notebook now reads "Air spins 0/1" and stamps on the first spin. The board's air spin take now completes the slide on replay (check_takes.gd: 1 success, completed true). Tests: new test_the_air_spin_goal_is_one_spin_and_the_others_three; _check_counts, the notebook-line test and the mission-amount test in test_practice_session.gd, and test_tutorial_practice_real.gd, read goal_count() instead of 3. test_practice* 46/46, test_tutorial* 86 + 1 pending of 87, test_shared_button 12/12, test_check_takes 3/3, test_standin_takes 4/4.

Text the Project Lead should look at (I wrote none):
- tutorial.airspin.instruction (the air spin slide's instruction band) says "AIR 180! or AIR 360! both count.", and the slide still counts AIR 180! (PracticeSession.COUNTED air_spin: air_one_eighty and air_three_sixty). The decision says "one AIR 360!". Either AIR 180! should stop counting (code) or the text and decision should allow both.
- tutorial.goal.airspin "Air spins {done}/{total}" shows "Air spins 0/1", plural with a goal of one. Could be fine; for Narrative Theme if not.
- Only _comment fields say "3 successes" (tutorial.goal.airspin_comment, tutorial.success_comment "after the third success"); they are not shown to players.

Settled (Project Lead, 2026-11-09): the board said "one spin", so AIR 180! and AIR 360! both still count, with the goal at 1. The instruction text stays true, and no text or code changes. The "Air spins 0/1" plural goes to the board through the Project Lead. Waiting for the board's grind take.

Final steps (UI Agent, 2026-11-09; the board: "I finished re-recording the grind demo."):

1. The board's new grind take (game/data/tutorial_takes/grind.json, 11.78 s; the previous one kept as grind.prev.json) completes its slide's goal on the new playground: 3 grinds of 3, following its path exactly (0.00 units off). check_takes.gd on every take: drift completes (3.4 off), alt_drift 3/3 (0.00 off), air_spin 1/1, so its goal is done (33.84 off, judged fine by the board), grind 3/3 (0.00 off). Every take does its trick and completes its slide's goal.
2. The recording controls are removed again: tutorial_slides.gd, test_tutorial_slides.gd and test_shared_button.gd are back to their versions without the tools (e313c88b). T-574's test_the_take_tools_and_f_keys_are_gone passes (not pending).
3. Docs: HUD and menus, Content, "The recorded demos' takes" (the grind re-recording, the air spin goal of 1 with AIR 180! and AIR 360! both counting, the final check) and the goal lines row (the air spin 1); game/docs/hud-and-menus/tutorial-slides.md (the 2026-11-09 entry); game/docs/game-loop/practice-session.md (completed() at the goal). HUD and menus, Decisions, "Interactive tutorial slides" still says "The goal on each is the trick 3 times". That is Decisions, so I left it for the Project Lead (the new decision line covers the air spin).
4. Tests: full Godot set (GUT_TIME_LIMIT=3600): 3258 of 3259 passed, 1 pending (the one that was pending before T-604), 0 failing (234 s). game/tools Python set: 1193 tests OK (4 skipped).
5. Screenshot: art-archive/T-604/screenshots/grind_new_take.png (the grind slide playing the board's new take, no recording row).
Note: a hook refused one combined command (git status plus Godot -s check_takes.gd) as a possible ticket write. I ran the read-only check_takes.gd on its own, as the hook's message said to, and it passed the hook.
- 2026-11-09, needs-playtest → done: The board played it: lgtm (2026-11-09).
