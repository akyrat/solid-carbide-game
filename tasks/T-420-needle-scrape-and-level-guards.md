---
id: T-420
title: Thread the needle while scraping, and level data guards
status: needs-playtest
from: project-lead
to: level-challenge
lead: Audit
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, game/scripts/level/thread_the_needle.gd, game/scripts/driving/car.gd, game/scripts/level/ground_height.gd, game/scripts/level/level_spawn.gd, game/scripts/run/run.gd]
files_expected_to_change: [game/scripts/level/thread_the_needle.gd, game/scripts/level/ground_height.gd, game/scripts/run/run.gd]
model: sonnet
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Code holes, no new decisions. 1) Level design, Decisions, "Thread the needle": a touch within half a second before the crossing voids the pass. But touched() only runs on a new contact (car.gd hit_obstacle fires once per contact), so scraping along a paired barrier for more than 0.5 s and crossing while still touching pays. 2) ground_height.gd reads p.x, p.height and r.top_height without defaults (a missing key is a script error with half-loaded ground), an unknown ramp side falls through the match (a flat ramp), and a ramp with zero width or height divides by zero (NaN reaches car.height). 3) run.gd starts a level with no spawn at (0,0), while level_spawn.gd says the map's centre snapped to a cell, and never runs LevelSpawn.problem().

Bad level files for the tests go in a test fixtures folder under game/tests/, never in game/data/levels/ (the board's levels: nothing there is written, moved or committed).

The board's review: scrape along a paired barrier through its gap and see no pass paid.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Crossing the gap line while still in contact with a paired obstacle pays nothing, however long the contact. (QA: pass)
- [ ] A level file with a missing key, an unknown ramp side or a zero-size ramp loads with a clear error naming the piece, and no NaN height (test with bad level files). (QA: pass)
- [ ] A level with no spawn starts the car where level_spawn.gd says; a spawn inside geometry is reported. (QA: pass)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Build J (Audit): started on playtest/audit-world (with T-418 in), worktree C:\solid-carbide-worktrees\T-420, Level/Challenge Design Agent.

### 2026-10-30, In progress → In QA

Build J (Audit): the agent finished. Scraping a paired obstacle voids the pass, bad level files load with a clear error and no NaN, a level without a spawn starts at the map's centre. Beyond the listed files: car.gd and thread_the_needle.gd. In QA now.

### 2026-10-30, In QA → Needs playtest

Build J (Audit): QA passed all 4 criteria and the tests; screenshots in art-archive/T-420/screenshots/. Merged into playtest/audit-world, waiting for the board's playtest of build J.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Done by the Level/Challenge Design Agent, in the task's folder. No docs needed changing (documents_affected is empty; Level design already decides all three rules).

**What changed**
- Scraping (criterion 1): `car.gd` keeps the body and shape of each held contact (`_contact_bodies`, same keys and lifetime as `_contacts`) and exposes `held_contacts()`. `thread_the_needle.gd` has a new `touching(contacts)` that counts every step of a held contact as a touch. `run.gd` `_on_car_needle_step` calls it before `observe`, so a crossing while still touching a paired obstacle is inside the 0.5 s window however long the scrape lasted. Verified the new run test fails without the call (the pass paid at 2.7 s) and passes with it.
- Ground data guards (criterion 2): `ground_height.gd` `load_data` now validates before loading anything: every platform needs x, y, w, h, height and every ramp x, y, w, h, top_height as numbers (not NaN or inf), a ramp's w and h above 0, and its side one of east, west, south, north. A bad piece sets `GroundHeight.error` (for example `ramp ramp-1: unknown side "up" ...`, `platform roof-1: missing "height"`), calls `push_error` with it, returns false and leaves the ground flat (no half-loaded ground). `_ramp_t` also returns 1.0 for a hand-built zero-size ramp, so no NaN reaches `car.height`.
- Spawn (criterion 3): `run.gd` starts a level from a file (`current_layout_path()` other than the game's own map) at `LevelSpawn.position_of` and `rotation_of` even with no spawn, which is the map's centre snapped to a cell (the game's own map keeps its (0, 0) start, as the doc says). It runs `LevelSpawn.problem()` on the start, stores it in `run.spawn_problem` ("" / `blocked` / `off_map`) and `push_warning`s it.
- Existing test changed: `test_creator_spawn.gd` `test_a_run_on_an_old_level_starts_at_the_centre` asserted the old (0, 0) start and heading as -PI/2; it now expects `LevelSpawn.centre_of(data)` and the same heading (compared as an angle difference), which is what Level design, Decisions, "The car's spawn point" says ("a level saved before this has it there too"). The game's own map is still asserted at (0, 0) by `test_the_games_own_map_keeps_its_start`.
- Everything touching `game/data/levels/`: nothing written, moved or committed. The bad level files are in `game/tests/fixtures/t420/`.

**Files**: `game/scripts/driving/car.gd`, `game/scripts/level/thread_the_needle.gd`, `game/scripts/level/ground_height.gd`, `game/scripts/run/run.gd`, new `game/tests/unit/run/test_t420_needle_scrape_and_level_guards.gd` (15 tests), new `game/tests/fixtures/t420/*.json` (7 files), new `game/tests/fixtures/t420_scrape_demo.gd/.tscn`, edited `game/tests/unit/level_creator/test_creator_spawn.gd`. (`car.gd` and `thread_the_needle.gd` were not in the ticket's files_expected_to_change; needed because only the car knows which contacts it still holds.)

**Tests** (all three sets, in this folder)
- `python -m unittest discover -s game/tools`: 722 run, OK (1 skipped).
- `python -m unittest discover -s tools`: 582 run, OK.
- Godot GUT full run, after the changes: 2151 tests, 174 scripts, 2150 passing, 1 failing: `test_creator_spawn.gd` `test_a_run_on_an_old_level_starts_at_the_centre` (the old assertion above). After fixing that test, `test_creator_spawn` alone: 23 of 23 pass. The full GUT run was not repeated after that one-test fix (it takes about 12 minutes under load); the rest of the suite had passed in the full run.
- `test_run_likes.gd` (drift timing, known to fail under load) alone: first run 34 passing and 3 failing (clock, combo, popup amount), second run 36 passing and 1 failing, third run 37 of 37 passing. It passed in the full run. Not touched by this ticket.
- New file `test_t420_needle_scrape_and_level_guards.gd`: 15 of 15 pass (scrape rule on its own, held contact of an unpaired obstacle not counting, a real run scraping a paired barrier pays nothing and has exactly one hit_obstacle, each bad fixture, no NaN, spawn start, spawn reported blocked and off the map, the game's own map unchanged).

**Screenshots** in `art-archive/T-420/screenshots/` (made by `game/tests/fixtures/t420_scrape_demo.tscn`, two 40-unit paired barriers with a 3-unit gap): `scrape_1_before.png`, `scrape_2_crossing.png`, `scrape_3_after.png` (the car scrapes the west barrier through the gap; the log says it crossed the gap line with 1 held contact and 0 passes paid; no popup) and `clean_1_before.png`, `clean_2_crossing.png`, `clean_3_after.png` (the control: a clean pass through the middle pays, THREAD THE NEEDLE! popup). `scrape_full.png` and `clean_full.png` are the screenshot tool's own last frame.

Board review files: art-archive/T-420/screenshots/scrape_2_crossing.png, art-archive/T-420/screenshots/scrape_3_after.png, art-archive/T-420/screenshots/clean_3_after.png

**Not done / notes**: a `rm` of old screenshot files was refused by the safety check, so nothing was removed (not needed). The scrape demo's barrier geometry is a test setup, not a level.

### QA report (round 1)

- qa_check (base playtest/audit-world): PASS tests (3 test sets, full GUT suite green after the test_creator_spawn fix), PASS documents (none listed), PASS screenshots (8 files).
- Criterion 1 pass: car.held_contacts() + needle.touching() called each step in run.gd; the new run test scrapes a paired barrier and pays nothing.
- Criterion 2 pass: 7 fixtures in game/tests/fixtures/t420/; ground_height.gd validates and names the piece, flat ground on error, no NaN.
- Criterion 3 pass: the changed test_creator_spawn assertion matches Level design ("a level saved before this has it [at the map's centre] too") and LevelSpawn.centre_of; the game's own map still asserted at (0, 0). Spawn problem reported (blocked / off_map). Not a bent test.
- Criterion 4 pass: new file 15 of 15 (rerun alone: 69 asserts); driving and combo tests are in the green full suite. Nothing in game/data/levels/ changed (git diff, 0 files).
- Test counts: qa_check does not print them; its full Godot run exited 0. Agent reported 2151 tests; unittest 722 (game/tools) and 582 (tools).

**Merge of master into playtest/audit-world (coordinator request)**: one conflict in game/scripts/run/run.gd near line 139, where my `spawn_problem` declaration and master T-413 `_tricks_before_wreck` declaration sat together. Kept both, each with its comment. No semantic clash: T-420 only changes the start in `_build_world` (spawn position and `spawn_problem`), while T-413 changes the wreck and revive code (`_tricks_before_wreck`, `car.detect_tricks`), which do not touch each other. Merge committed in C:\solid-carbide-worktrees\playtest-audit-world (f53d5854); test counts are in the reply to the coordinator.
