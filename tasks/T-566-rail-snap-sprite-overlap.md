---
id: T-566
title: Snap to a rail when the car's sprite crosses the rail's sprite, whatever the height
status: in-progress
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
files_to_read_first: [tasks/README.md, docs/drifting.md, game/docs/driving/rail-grind.md, tasks/T-551-grind-overhaul-driving.md]
files_expected_to_change: [game/scripts/driving/, game/data/rail_grind.json, game/tests/, game/docs/driving/, docs/drifting.md]
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

Build Drifting, Decisions, "A grind starts when the car's drawing crosses the rail's": while Space is held in the air, the car snaps onto a rail as soon as the car's sprite as drawn on screen (its drawn rectangle or pixels, lifted by its height, as the player sees it) crosses the rail's drawn sprite, whatever the car's height above or below the rail; it then grinds at the rail's height as today. This replaces the catch reach (2.5) and any height window. Propose how the overlap is measured (bounding boxes or a tighter shape) so it matches what the player sees without catching rails the car only seems near, and what happens if two rails overlap the car (the nearest on screen). The rest of the grind overhaul stays (Space held to grind, release to launch, landing boost). Update the GRIND! practice slide's checks if they assumed the old reach.

The board's review: play it from C:\solid-carbide-worktrees\T-566\game\project.godot on the Kaiju City map (and the tutorial's grind slide once it is in the combined build), hold Space in the air and cross a rail's drawing at different heights.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Holding Space in the air, the car snaps onto a rail when its drawn sprite crosses the rail's drawn sprite, also when the car is well above or below the rail's height (tests at several heights). (QA: pass)
- [ ] Without Space held, or with the sprites not crossing, it does not snap (tests). (QA: pass)
- [ ] The rest of the grind (release to launch, landing boost) works as before (the existing tests pass). (QA: pass)
- [ ] docs/drifting.md Content and game/docs/driving/ describe the rule and the overlap measure, with reasons. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] A GIF in art-archive/T-566/screenshots/ shows a snap from well above a rail and one from below. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: holding Space in the air, the car snaps to a rail when its sprite crosses the rail's, at any height.

### 2026-11-07, In progress → In QA

Built: snaps when the car's drawn pixels cross the rail's, at any height. Open question: a square-on crossing doesn't catch yet. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (6/6), square-on included. Into the tutorial build; also playable from its own folder.

### 2026-11-07, Needs playtest → In progress

T-559..T-565 merged. T-566 broke 3 popup tests in the merge run, so it's back with Driving & Drift to fix; then QA, merge and the itch push.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

### Driving & Drift Agent, 2026-11-07

Done. With Space held in the air, the car now snaps onto a rail on the first step in which its drawing on screen crosses the rail's drawn bar, at any height above or below the bar. Once it is on the rail it grinds at the bar's height as before. The catch reach (2.5), the end margin and the height window (`catch_above`, `catch_below`) are gone from the code and from `rail_grind.json`. Holding Space to grind, letting go to launch, the landing boost and joints are unchanged.

**How the overlap is measured (proposals for the playtest; reasons in Drifting, Content, "The rail snap on the drawing (task T-566)")**
- The car: its own opaque pixels, not a bounding box. For each frame it is drawn with in the air (the shadowless sheet, and the tilt sheet's 3 rows), the shape is each pixel row from its leftmost to its rightmost opaque pixel. The frame shown is picked from its heading and tilt step, and the shape is placed and lifted exactly as `car_sprite.gd` draws it. A box would catch rails passing the empty corners of a diagonal car. The shape comes from `game/art/car/car_iso_outline.json`, built from the PNGs by `game/tools/build_car_outline.py` (`--check` says whether it is up to date). It is not read from the image at run time, so there is no hitch and nothing breaks on the web.
- The rail: its bar, 3 px thick, from end to end. The posts don't count.
- At the bar's height, a car flying along the rail now catches it from about 1.2 units beside it (the old reach was 2.5). In the isometric view, a car d units nearer the viewer and d units higher than a bar is drawn on it, so a car several units over or under a bar catches it when it is beside it by as much.
- Where it lands: on the point of the bar nearest the car's drawn centre on screen. The drawing moves only onto the bar, at most about 20 px (measured 19.7 in the test). The map position can jump several units, which the player doesn't see.
- Two bars crossed: the bar nearest the car's drawn centre on screen wins.
- A rising car now catches too (before, it had to be falling or level), so a hop from under a high rail catches it.
- Kept: moving within 60 degrees of the rail at 2 units/s or more. Only the speed along the rail is kept, so a car crossing square-on would stop dead and drop off. Open question for the board's playtest: should a square-on crossing catch too?
- Not handled: a bar hidden behind a building still catches if the drawings cross. No rail on the map is placed like that.

**The GRIND! practice slide:** T-561 and T-562 are still open and not built, so there were no checks to update. They will use this rule.

**Code:** `game/scripts/driving/car_outline.gd` (new), `game/scripts/driving/rail_grind.gd` (`find()`, `snap_t()`, `BAR_HALF_PX`), `game/scripts/driving/car.gd` (passes the heading and tilt step to `find()`), `game/data/rail_grind.json`, `game/art/car/car_iso_outline.json` (new, generated), `game/tools/build_car_outline.py` (new).

**Tests (run by me, in the foreground, one file at a time):**
- `test_rail_snap_drawing.gd` (new): 11/11 tests, 54 asserts.
  - catches at heights from 5 under to 8 over the bar, and not when the drawing is 3 units' worth clear of it
  - a car falling from 6 over and one hopping from 5 under both snap and grind at the bar's height
  - no snap without Space, when the drawings never cross, or when crossing square-on
  - a rail through the frame's empty corner is not caught
  - the nearest bar on screen wins
  - the projection is the rails' drawing
  - the outline file matches the PNGs row by row
  - the frame follows the heading as the sprite does
- Updated files: `test_rail_grind.gd` 36/36 (198 asserts), `test_rail_joints_and_heights.gd` 14/14 (59).
- Other files that touch rails, all passing: `test_run_rails.gd` 5/5 (225), `test_grind_overhaul.gd` 16/16 (65), `test_game_map.gd` 13/13 (61), `test_creator_rails.gd` 26/26 (225), `test_trick_list_recipes.gd` 12/12 (275), `test_tutorial_clips.gd` 7/7 (79), `test_camera_options.gd` 20/20 (522).
- Python: `game/tools/test_build_car_outline.py` 4/4.
- I did not run the full sets; that is QA's run.

**GIFs and stills (`art-archive/T-566/screenshots/`):**
- `rail_snap_below_then_above.gif`: both snaps in one run.
- `rail_snap_from_below.gif`: a hop from the street snaps up onto a bar at 5 from 4.0 units under it.
- `rail_snap_from_above.gif`: off that rail's end with Space held, the falling car snaps down onto a bar at 1 from 4.0 units over it.
- `below_just_before_snap.png`, `below_just_after_snap.png`, `above_just_before_snap.png`, `above_just_after_snap.png`.
- Fixture: `game/tests/fixtures/t566_snap_gif.tscn`. It uses its own two rails on a copy of the Kaiju City map in user://. A readout shows the height and how far over or under the bar each snap started.

**Docs:**
- `docs/drifting.md`, Content: new section "The rail snap on the drawing (task T-566)". The T-541 "Locking on" and T-551 "Starting a grind" bullets now point to it.
- `game/docs/driving/rail-grind.md`: new section "The rail snap on the drawing (T-566)", and the table rows are updated.

**Refusals:** the PreToolUse guard ("Task statuses change only through the status script") refused two read-only PowerShell commands: a Select-String over `tasks/T-56[0-3]*.md` and one over `mvp_map.gd`, because they used `$_.Filename` and `$_.LineNumber`. Nothing was written. I did those reads with the Grep tool instead, as the guard's message allows for reads. I did not retry the refused commands. The Project Lead may want to know that the guard flags read-only Select-String pipelines.

### Driving & Drift Agent, 2026-11-07: the board's tweak, square-on crossings catch

Built the board's answer word for word: "yes, square-on crossings should catch too".
- Any crossing angle now catches. The 60-degree limit `max_angle_deg` is gone from the code and from `rail_grind.json`. So is the minimum flat speed, so a hop in place under a bar catches too.
- A car moving along the rail at 2 units/s or more (`min_start_speed`) grinds its own way along it at its speed along it, as before.
- A car slower than that along the rail (square-on) grinds the way its nose points along the rail at `square_start_speed` = 6 units/s, whatever way it was flying, then gets the landing boost (10 in all).
  - If the nose is exactly square to the rail, the car goes the way its flight goes along the rail. If both are square, it goes toward end b.
  - Proposal for the speed: 6 is `jump_speed`, the speed a launch leaves a rail at. So a launch that crosses the next rail square-on rides it at the speed it left the last one. 10 with the boost is just under cruise (11). It lasts about 4 s before the car drops off below 2, so even a short ride pays GRIND!.
- Code: `game/scripts/driving/rail_grind.gd` (`find()` and the new `start_speed_along()`) and `game/data/rail_grind.json` (`square_start_speed` and `_square_comment`).

**Tests (foreground, one file at a time):**
- `test_rail_snap_drawing.gd`: 14/14 tests, 71 asserts. Three tests are new:
  - square-on east and west at 6 + 4, still sliding 10 steps later
  - crossing tail first goes where the nose points; `start_speed_along()`'s cases
  - a standing hop under a bar catches
- `test_rail_grind.gd`: 36/36 (199). "Landing across a rail locks on too", and the "too slow" case now catches at the set speed.
- Other rail tests, all passing: `test_rail_joints_and_heights.gd` 14/14 (59), `test_run_rails.gd` 5/5 (225), `test_grind_overhaul.gd` 16/16 (65), `test_game_map.gd` 13/13 (61), `test_creator_rails.gd` 26/26 (225), `test_trick_list_recipes.gd` 12/12 (275), `test_tutorial_clips.gd` 7/7 (79), `test_camera_options.gd` 20/20 (522).

**GIF:**
- `art-archive/T-566/screenshots/rail_snap_square_on.gif` (fixture `T566_SCENE=square`). The car flies straight north (velocity (0, -16.5)), D turns its nose 38 degrees east in the air, it catches the bar square-on, and it grinds east at 10.0.
- Stills: `square_on_just_before_snap.png`, `square_on_grinding_east.png`.

**Docs:**
- `docs/drifting.md`, Content, "The rail snap on the drawing (task T-566)": a new bullet "Any crossing angle catches".
- `game/docs/driving/rail-grind.md`: the `find()` row, the data row, the tests and the recordings.

**Refusal:** Claude Code's built-in safety check refused `rm -f "$D"/*.png` (clearing my own scratchpad frame folder before re-recording), because the target is a shell variable. Nothing was deleted. I did not retry the removal. I recorded into a new empty folder instead (scratchpad `t566sq2`), so the old frames in scratchpad `t566sq` are still there. They are scratch files and harmless.

### Driving & Drift Agent, 2026-11-07: the practice playground test (combined tutorial build)

Fixed the one red test that came from the snap rule meeting T-560's practice playground: game/tests/unit/level/test_practice_playground.gd, test_every_rail_is_caught_from_the_ramp. In the lane one over (y 3.5), the car flies high off the ramp, and a car 3.5 units nearer the viewer and 3.5 units higher than a bar is drawn on it. So with Space held from the takeoff, it now catches rail-1 instead of rail-3. That is the new rule working as intended.

I changed the drive, not the rails. I did not move any of the playground's rails. _drive() takes a new optional space_from_x (default 11, as before). The lane drive holds Space only from x 37, past rail-1's end at 34, and catches rail-3 at x 38.7. This is what a player would do to pick rail-3. The middle drive (rail-2) and the cruise drive (rail-1) are unchanged. The test still checks that every rail can be caught from the ramp.

Tests (foreground, one at a time): test_practice_playground.gd 9/9 (50 asserts), test_tutorial_practice_real.gd 6/6 (77), test_practice_session.gd 28/28 (186). Rechecked after the merge: test_rail_snap_drawing.gd 14/14 (71), test_rail_grind.gd 36/36 (199).
- 2026-11-07, needs-playtest → in-progress: Merge test run failed: 3 Godot tests (test_trick_popups_follow.gd, test_drift_guide_label_text.gd, weapons/test_starting_gun.gd) hit null textures in trick_popups.gd (lines 267, 418, 446) only when T-566 is merged on top of T-559..T-565. Log: .board/merge_batch-20261107-191753.log

### Driving & Drift Agent, 2026-11-07: the merge run's 3 red popup tests

**Cause.** The cause is not in T-566's rail code. It is a race in the popup baking that is already on master (T-480's worker threads, scripts/hud/trick_popup_art.gd). The baking font (a fresh duplicate of the comic font) makes its text server data the first time get_rids() is called. The first bakes of a process ran on several worker threads at once, and one of them could find no data yet: 'Out of bounds get index 0 (on base: Array[RID])' at _letter:336, in test_starting_gun (merge log line 19394). Its bake returned null, and poll() pinned ImageTexture.create_from_image(null) = null ('Invalid image: null', p_image.is_null) for the rest of that Godot process. Later tests in the same shard then drew the null popup ('get_size on a null value', trick_popups.gd:267). T-566 only set it off: it adds a test script (test_rail_snap_drawing.gd), which reshuffles run_tests_parallel.py's 12 shards, so a popup test landed in a process whose first bake happened on worker threads.

**Fix.**
- TrickPopupArt._get_font() now calls get_rids() once when it makes the font. request() warms the font on the main thread before any worker starts, so the font's data exists before any worker reads it.
- TrickPopupArt.poll() and ComboBrokenArt.poll() no longer keep a failed bake (a null image). Nothing is cached, and drawing bakes the popup again on the spot.
- Test: game/tests/unit/test_trick_popup_threads.gd (new). The font data exists once warmed. 20 rounds of a fresh font with 32 requests each on worker threads all come back with pictures. A failed bake is not kept and is baked again when drawn.

**Merge.** I merged master (20dcc99f) into the branch. There were no conflicts.

**Tests (foreground, after the merge):**
- Full Godot set (run_tests.sh): 267 scripts, 3055 tests, 3054 passing, 0 failing, 1 risky/pending. The pending test is not one of mine. The log has none of the 3 errors.
- -gselect=test_trick_popup: 61/61 passing.
- python game/tools: 1047 tests OK (4 skipped).
- python tools: 640 tests OK.

**Process slip:** I sent the two Python runs in the same message, so for a few seconds they overlapped. I then ran game/tools again on its own, and it passed. No job is left running.

**Files:** game/scripts/hud/trick_popup_art.gd, game/scripts/hud/combo_broken_art.gd, game/tests/unit/test_trick_popup_threads.gd. No documents affected.
