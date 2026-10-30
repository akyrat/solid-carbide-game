---
id: T-404
title: Enemies flash red when they take damage
status: done
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/docs/enemies/]
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/game-loop-architecture.md, tasks/T-403-car-red-damage-flash.md, game/scripts/enemies/]
files_expected_to_change: [game/scripts/enemies/, game/tests/unit/, game/docs/enemies/, docs/enemies.md, art-archive/]
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

The board's decision (Enemies, Decisions, "A red flash when an enemy takes damage", 2026-10-30): "and same for the enemies." Every enemy, minions and the kaiju, flashes red when a weapon or the car hits it, reusing T-403's helper so it looks the same as the car's (its worktree is branched from T-403's branch once T-403 passes QA, so the board plays both together). A hit that kills a minion may skip the flash if its death effect plays at once (your proposal). For the kaiju, whether it flashes on every hit or only in its vulnerable window is a proposal. With many minions hit at once it must stay cheap (no per-enemy material copies if a shared shader parameter works). Code only, no new art.

The board's review: play a run, hit minions with each weapon and the car, and hit the kaiju.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] Minions and the kaiju flash red when a weapon or the car damages them, using T-403's helper (tests). (QA: pass - tests in test_minions/test_kaiju green)
- [x] The proposals for kills and the kaiju are in the result notes, and behave as written (tests). (QA: pass)
- [x] Many minions flashing at once keep the frame time as before, measured in the result notes. (QA: pass - 4.166 vs 4.180 ms in the notes)
- [x] Enemies (Content) and game/docs/enemies/ describe it. (QA: pass - docs/enemies.md and game/docs/enemies/minions.md changed; qa_check's "documents" line is a directory-path false alarm)
- [x] A GIF of minions and the kaiju being hit is in `art-archive/<id>/screenshots/`. (QA: pass - enemy_red_flash.gif present, 11.6 MB)
- [x] All three test sets pass, with the counts in the result notes. (QA: pass - rerun by QA: GUT 1946 passing, 158 scripts, TESTS PASSED, exit 0; counts match the notes)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build F, on top of T-403's HitFlash helper.

### 2026-10-30, In progress → In QA

Minions and the kaiju now flash the car's red (T-072's tint unified with HitFlash); kills skip it, kaiju flashes on every hit; frame time unchanged; GIF in art-archive/T-404.

### 2026-10-30, In QA → Needs playtest

QA passed all six criteria; GUT 1946 passing, all tests green. Ready for the board: hit minions with each weapon and the car, and the kaiju.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Built. T-072's pale 0.12 s tint (`HitTint`, `scripts/enemies/hit_tint.gd`) already did most of it, so it is unified with T-403's `HitFlash` rather than doubled: `HitTint` keeps its API (`attach`, `flash`, `is_active`) but now runs one `HitFlash` per enemy (made at its first hit). Minions and the kaiju flash the car's red, 0.4 s, `run.json` `hit_flash`. `DURATION` and `TINT` are removed; `HitTint.proto()` reads the numbers once for all enemies (no run.json load per minion). Cheap: no material, `_process` switched off when idle. Another tint on the sprite (the flamethrower's orange burn) still wins.

Proposals (for the playtest): (1) a hit that kills skips the flash, the enemy is gone at once; (2) the kaiju flashes on every hit, not only in its vulnerable window (it can be damaged at any time); (3) a new hit restarts the flash, so a weapon that hits every tick keeps an enemy red; (4) 0.4 s is the car's length, so it is longer than the old 0.12 s; if it is too much on minions, `hit_flash.seconds` is one number (it also changes the car).

Tests: updated T-072 tests in `test_minions.gd` and `test_kaiju.gd` (red from run.json, back to white, kaiju flashes, orange left alone) and new ones (kill skips flash and uses the car's numbers; 30 minions share one proto, flash, and stop processing; a new hit restarts). Results: GUT 1946 passing (158 scripts); `game/tools` unittest 668 OK (1 skipped); `tools` unittest 579 OK. No .env in the worktree, GODOT_BIN passed from the main checkout.

Frame time (windowed, 100 minions, `FLASH_MEASURE=100` on `enemy_flash_gif_demo.tscn`, 300 frames each): 4.166 ms with no flashes, 4.180 ms with all 100 re-hit every 0.3 s and flashing (the window is capped near 240 Hz, so the cost is below what shows); same on a second run.

GIF: `art-archive/T-404/screenshots/enemy_red_flash.gif` (6 minions hit one by one, the kaiju twice, then all together; red-pixel count jumps at the kaiju hits, frames 24 and 26). Recorder: `game/tools/record_enemy_flash_gif.sh`, fixture `game/tests/fixtures/enemy_flash_gif_demo.*`.

Documents: `docs/enemies.md` (Decisions, new Content section "The red flash"), `game/docs/enemies/minions.md`.
- 2026-10-30, needs-playtest → done: Build F LGTM by the board
