---
id: T-015
title: Escape pauses the game, with a simple pause screen and the camera zoom slider
status: done
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-012, T-047]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, tasks/T-047-text-pause-screen.md, docs/hud-and-menus.md, docs/drifting.md, game/README.md, tasks/T-012-godot-drift-prototype.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [the pause screen scene and script, the saved zoom setting, their tests, the input map in game/project.godot, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: in-progress | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-047 (the pause screen's text) is done.** T-012 is done (2026-10-08): the drift prototype is the first thing there is to pause. Use exactly T-047's text for the screen's words and the slider's label (`tasks/README.md`, "User-facing text and visuals").

Escape pauses the game (HUD and menus, Decisions). For the MVP the pause screen is as simple as possible: the word "Paused", a hint that Escape resumes, and **one setting: the camera zoom slider** (board, 2026-10-08; Drifting, Decisions). Pressing Escape again resumes. A full pause menu with more settings comes later (T-016, final release); do not build it here.

**The zoom slider:** range 6 to 20, default 14.4, the same as the prototype's tuning-panel zoom slider (T-012). Moving it changes the camera zoom straight away (the prototype already has a function to set the zoom). The player's choice is saved between sessions, as in the Unity prototype: write it to a small settings file under `user://` and read it when the game starts. The tuning panel's zoom slider and the pause screen's slider show the same value.

- While paused, everything in the game stops: the car's physics and any timers.
- Escape is a named action in the input map, so the final-release menu can reuse it.
- Plain text is enough for now; the look follows the Visual style document once it has content.
- The prototype's tuning panel (Tab, from T-012) does not need to work while paused.
- T-029 (new driving defaults) may run at the same time and also edits `game/project.godot` (physics settings); keep your changes there to the input map.

## Acceptance criteria

- [ ] A test shows that pressing Escape pauses the game: the car's position and velocity do not change over several frames while paused (QA: pass / fail)
- [ ] A test shows that pressing Escape again resumes, and the car continues from exactly where it was (QA: pass / fail)
- [ ] A screenshot of the paused game shows T-047's title and hint, and the zoom slider with T-047's label (QA: pass / fail)
- [ ] A test shows the slider runs from 6 to 20 with a default of 14.4, and that moving it changes the camera zoom (QA: pass / fail)
- [ ] A test shows the chosen zoom is saved and read back when the game starts again (for example: set it, save, then a new instance reads the same value), and that with no settings file the zoom is 14.4 (QA: pass / fail)
- [ ] Escape is an action in the input map in `game/project.godot` (QA: pass / fail)
- [ ] `game/README.md` lists Escape under the prototype's keys and mentions the zoom slider (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Built (UI Agent): Escape (`pause` action in `game/project.godot`, the only change there) pauses and resumes the whole tree. The pause screen (`game/scripts/ui/pause_screen.gd`) shows T-047's title "Paused", hint "Press Escape to get back to the stream." and zoom label "Camera zoom, for the fans", over a dimmed game, with a 6 to 20 slider (default 14.4). It sets the zoom through the prototype's `set_zoom` and refreshes the tuning panel's slider, so both show the same value. The zoom is saved to `user://settings.cfg` by `game/scripts/ui/game_settings.gd` and read at start (no file or bad value gives 14.4). The prototype's on-screen key hint now ends with "Esc: pause" (not in T-047's list; a short key reminder like the existing ones, flag to the Project Lead if text for it is wanted).

Tests: `game/tests/unit/test_pause_screen.gd` (8 tests: action in input map, pause freezes position, velocity and rotation over 8 physics frames, resume continues from the same spot, texts, slider range, default and camera zoom, panel and pause slider agree, save and read back by a new instance, default with no file, bad values). `test_drift_prototype.gd` now points the settings at a missing file so it starts at the default. Full GUT suite: 108 tests passed. Python tool tests: 3 failures in `test_build_mvp_map.py` (KeyError 'boulders' reading the sketches), which also fail without my changes and are unrelated to this task.

Screenshot: `bash game/tools/screenshot.sh res://tests/fixtures/pause_screen_demo.tscn screenshots/pause_screen.png 300` (shows title, hint, label and slider; the car drawn behind the text is part of the dimmed game).

Documents affected: `game/README.md` (Escape in the keys table, new "Pause screen" section).

### QA round 1

Checked independently in the T-015 worktree. Full GUT suite: 108 of 108 passed (TESTS PASSED). Python tests: `tools` 72 OK; `game/tools` 51 run, 3 failures, all in `test_build_mvp_map.py` (KeyError 'boulders' x2, 12 != 6). The same 3 fail identically on master (tracked in T-087), so they are not this task's fault and do not count against the criterion. Own screenshot taken with `screenshot.sh` on the demo fixture: shows "Paused", "Press Escape to get back to the stream.", "Camera zoom, for the fans" and a slider at 14.4. Texts match T-047 exactly (checked in `pause_screen.gd` constants and on screen).

- [x] Escape pauses, car position and velocity unchanged over frames: PASS (`test_escape_pauses_and_the_car_stops_then_resumes_exactly`, passes)
- [x] Escape again resumes from exactly where the car was: PASS (same test)
- [x] Screenshot shows T-047's title, hint and slider label: PASS (own screenshot)
- [x] Slider 6 to 20, default 14.4, moves the camera zoom: PASS (`test_slider_range_default_and_it_moves_the_camera`; code: min 6, max 20)
- [x] Zoom saved and read back by a new instance; no file gives 14.4: PASS (`test_zoom_is_saved_and_read_back_by_a_new_instance`, `test_no_settings_file_gives_default_zoom`; `game_settings.gd` read)
- [x] Escape is an input action in `game/project.godot`: PASS (`git diff master...HEAD` adds only the `pause` action, 5 lines, nothing else)
- [x] `game/README.md` lists Escape under keys and mentions the zoom slider: PASS (keys table row and "Pause screen" section)
- [x] Full GUT suite and all Python tool tests pass: PASS (all pass except the 3 known pre-existing T-087 failures, identical on master)

Note for the Project Lead: the on-screen key hint now ends with "Esc: pause", which is not in T-047's approved list (the UI Agent flagged it). The `git status` of the worktree shows modified `.import` files from running Godot; they are not part of the branch commit.

### Board review

Merged on QA's pass (no board review needed), 2026-10-10. The drift prototype's key hint now also says "Esc: pause"; it is a developer key reminder in the tuning tool, not player-facing game text.
