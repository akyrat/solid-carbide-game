---
id: T-403
title: The car flashes red when it takes damage
status: needs-playtest
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/docs/game-loop/the-run.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/data/run.json, game/scripts/data/run_data.gd]
files_expected_to_change: [game/scripts/, game/data/run.json, game/tests/unit/, game/docs/game-loop/the-run.md, docs/game-loop-architecture.md, art-archive/]
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

The board's decision (Game loop architecture, Decisions, "A red flash when the car takes damage", 2026-10-30): "add a red effect on the player when they take damage." When the car loses a heart (a minion, a meteor, the kaiju), it flashes red. It must read clearly together with the existing 1-second invulnerability blink (for example red on the first visible phases, then the plain blink), and must not fire on hits ignored during the invulnerability. Write the flash as one small reusable helper (a shader or modulate tween) that T-404 reuses for the enemies, so both look the same; its length and colour go in `game/data/run.json` as proposals. Code only, no new art. Don't touch the goal G-007's areas (tutorial slides, pause screen).

The board's review: play a run, take hits from minions and a meteor, and watch the car.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] When the car loses a heart it flashes red, with the length and colour read from `game/data/run.json` (tests). (QA: pass)
- [ ] A hit ignored during the invulnerability does not flash (test), and the blink still works as before (existing tests). (QA: pass)
- [ ] The flash is a reusable helper, named in the result notes for T-404. (QA: pass)
- [ ] Game loop architecture (Content) and game/docs/game-loop/the-run.md describe it and its numbers. (QA: pass)
- [ ] A GIF of the car taking a hit is in `art-archive/<id>/screenshots/`. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; all three sets green on rerun, counts as in the result notes: 1944 / 668 / 576)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the car's red flash on damage.

### 2026-10-30, In progress → In QA

The car now flashes red when it loses a heart (0.4 s, from run.json), shown on the blink's visible phases; reusable HitFlash helper for the enemies; tests pass, GIF in art-archive/T-403.

### 2026-10-30, In QA → Needs playtest

QA passed all six criteria (3 test sets green, GIF and docs present); ready for the board to play.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built. The helper is `HitFlash` (`game/scripts/run/hit_flash.gd`, class_name `HitFlash`). For T-404: `var flash := HitFlash.from_data()` (reads run.json `hit_flash`); `flash.trigger()` on a hit that counts (a new hit restarts it); `flash.advance(delta)` each step; `flash.apply_to(canvas_item)` sets `modulate` (red while it lasts, white after); `flash.reset()`. Numbers (proposals) in `game/data/run.json` `hit_flash`: `seconds` 0.4, `color` [1.0, 0.25, 0.25], read through `RunData.hit_flash_seconds()` / `hit_flash_color()`.

The car: `run.gd` has `car_flash`, triggered on `state.car_damaged` (never emitted for ignored hits), advanced and applied to `car_sprite.modulate` in `_on_car_moved()`, cleared in `start_run()`. The blink starts hidden, so the red shows on the visible phases 0.1 to 0.2 s and 0.3 to 0.4 s, then the plain blink goes on.

Tests: new `game/tests/unit/run/test_hit_flash.gd` (5 tests: numbers from the file, helper timing and restart, car flashes with the blink working, ignored hit does not flash, new run clears it). Results: Godot/GUT 1944 tests passing (158 scripts); `game/tools` unittest 668 OK (1 skipped); `tools` unittest 576 OK.

Screenshot: `art-archive/T-403/screenshots/car_red_flash.gif` (the hearts demo, 75 frames; red shows at frames 10 and 13, checked by counting red pixels). Docs updated: `docs/game-loop-architecture.md`, `game/docs/game-loop/the-run.md`. Note: the worktree has no `.env`, so I passed `GODOT_BIN` (the line from the main checkout's `.env`) as an environment variable.
