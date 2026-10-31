---
id: T-444
title: The game stays fast with a crowd of minions
status: done
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [game/docs/enemies/minions.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/docs/enemies/minions.md, game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/enemy_path_follower.gd]
files_expected_to_change: [game/scripts/enemies/, game/tools/, game/tests/unit/, game/docs/enemies/minions.md]
model: opus
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

The board, 2026-10-31 (docs/enemies.md, Decisions, "Minions spawn on a timer, and 30% slower"): with minions on a constant timer (T-443), many more will be alive at once, and the game must not slow down much.

1. Write a repeatable measurement script (in game/tools/, run headless) that starts a run on the game's map (Kaiju City), holds a given number of minions alive around the car (for example 50, 100, 200, 300) and reports the average and worst physics and frame times. Run it before changing anything and put the numbers in the result notes.
2. Find where the time goes (path finding, path following, separation between minions, depth sorting, collisions, per-frame allocations, signals) and optimise the biggest costs: for example sharing or caching paths, re-planning less often, spreading work over frames, cheaper neighbour checks. Behaviour stays the same as the player sees it: minions still find their way round buildings and boulders, up ramps and off ledges, and hit the car as today.
3. Run the script again after the changes and put the before and after numbers side by side in the result notes, with what each change bought.

No gameplay or numbers change in this ticket. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [x] A measurement script in game/tools/ reports the average and worst frame times with a given number of minions alive on Kaiju City, and is documented in game/docs/enemies/minions.md with how to run it. (QA: pass - game/tools/minion_crowd_bench.sh/.gd exist, documented in minions.md 'Performance (T-444)' with run command)
- [x] The result notes have before and after numbers for at least 50, 100 and 200 minions, and the after numbers are lower for 100 and 200. (QA: pass - table has 50/100/200/300 before and after; after lower (100: 37.0 -> 8.3 ms, 200: 75.7 -> 17.1 ms))
- [x] The existing enemy navigation, falling, ramp and contact tests still pass unchanged (minions behave as before). (QA: pass - no existing test file modified (diff shows only added files); GUT 2327/2327 green)
- [x] A test (or the script's own check) covers each optimisation that changes when work happens (for example cached paths stay correct when the car moves). (QA: pass - new test_minion_crowd_performance.gd (9 tests) covers lookup, limit_motion shortcut, depth grid rebuild, separation cells, kept surface)
- [x] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass - qa_check: 3 test sets passed; counts in notes (767, 591, 2327))
- [x] Nothing under game/data/levels/ is changed or committed. (QA: pass - git diff vs merge-base touches nothing in game/data/levels/)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

- 2026-10-31, open → in-progress: The board, 2026-10-31 ("optimise how many things we can run concurrently"): starts in parallel with T-443, on top of T-443's branch; the depends_on T-443 line is set aside. Merge after T-443.

**Enemy Behavior Agent, 2026-10-31: built.** No gameplay number or rule changed; the safety ceiling stays 100.

**The measurement script** (AC 1): `game/tools/minion_crowd_bench.sh` (runs `game/tools/minion_crowd_bench.gd` headless with `--fixed-fps 50`, so every frame is exactly one of the game's 50 physics steps a second). From the repo root: `bash game/tools/minion_crowd_bench.sh --counts=50,100,200,300 --seconds=5 --warmup=1` (`--seed`, `--breakdown` for a part-by-part timing). It starts the game's own run on Kaiju City, parks the car where the run puts it, holds each count of minions alive round it (placed 4 to 30 units away, topped up every frame, too tough for the weapons to kill, so the weapons keep firing as in a run) and prints avg / p99 / worst of the whole frame, the scripts' physics step, and the spawner's step. Documented in `game/docs/enemies/minions.md`, "Performance (T-444)". Headless: drawing on screen is not in the numbers.

**Before and after** (AC 2). Three runs each of 5 s (251 frames) per count after 1 s warm-up, same seed, before on this branch's T-443 code (my changes stashed), after with them. The machine was busy with other agents' Godot runs throughout. Frame ms (one physics step plus one idle frame; the budget at 50 Hz is 20 ms), median run first, then the range over the three runs:

| alive | before: frame avg | before: frame worst | after: frame avg | after: frame worst | minions' step avg, before → after |
|---|---|---|---|---|---|
| 50 | 18.6 (17.3 to 18.6) | 22.8 to 24.1 | 4.3 (4.2 to 4.3) | 7.5 to 7.9 | 17.3 → 3.1 |
| 100 | 37.0 (36.6 to 38.7) | 43.7 to 47.2 | 8.3 (8.0 to 8.8) | 10.6 to 12.7 | 35.2 → 6.5 |
| 200 | 75.7 (75.5 to 80.6) | 88.1 to 97.4 | 17.1 (16.0 to 17.5) | 21.5 to 25.5 | 73.2 → 14.5 |
| 300 | 118.6 (117.8 to 127.0) | 143.8 to 278.9 | 24.9 (24.7 to 29.9) | 32.7 to 90.6 | 115.3 → 21.6 |

p99 frame, before → after: 50: 19.7-21.9 → 5.3-6.0; 100: 42.9-45.4 → 10.5-12.2; 200: 83.8-96.6 → 21.1-23.9; 300: 139.7-221.6 → 31.5-79.9 (one after run at 300 had a burst of other load, p99 79.9, the other two 31.5). About 4.5 times faster at every count: the minions' step went from about 0.35 ms to about 0.07 ms per minion.

**Where the time went, and what each change bought** (single 3 s runs taken while building, minions' step avg at 100 / 300 alive; noisy, but the order is clear): before 35 / 115 ms. The `--breakdown` before any change showed the depth order (about 0.12 ms per minion) and the edge checks round each move (about 0.09 ms) as the biggest parts, both mostly `GroundHeight.height_at` and the per-item tests; separation was 2 ms at 100 and grows with the square.
1. `game/scripts/enemies/enemy_ground_index.gd` (new): a bucket lookup (4 units) of the ground's areas, answering `height_at` / `area_index_at` through `GroundHeight.height_among` / `area_among` (T-411's functions, same answers). `enemy_height.gd` and `enemy_navigation.gd` (and `enemy_path_follower.gd`'s drop check) read heights and surfaces through it. Before: every one of the map's rooftops, short-building platforms and ramps was tested for every height, many times per minion per step. → 20 / ~65 ms.
2. `game/scripts/enemies/enemy_depth.gd`: buildings, boulder and prop sprites and raised areas filed once in a 64-pixel screen grid; each minion tests only the items in the cells its shape's box touches, with the same rules (plus each area's box before its polygon test). Rebuilt when a list changes (a meteor boulder). → 9.6 / 39 ms.
3. `minion_spawner.gd` `_separation()`: cells as wide as the push's reach, compared with the 9 cells round, in index order (same sums). → 8.6 / 31.5 ms.
4. `enemy_height.gd` `limit_motion()`: a move whose whole reach is over flat street (index says no area there) is allowed at once, exactly as the piece-by-piece check allows it. → 7.2 / 24.3 ms.
5. `enemy_navigation.gd` `surface_at()` keeps its last answer (the car's surface, asked by every minion each step); the spawner asks `follower.dropping()` only with a path. → 6.7 / 23 ms.
Remaining per minion (300 alive): walking with `move_and_collide` about 25 µs, drawing (depth order) about 20 µs, separation about 15 µs, the follower about 10 µs.

**Behaviour the same** (AC 3, 4): the existing enemy tests pass unchanged (no existing test edited). New `game/tests/unit/enemies/test_minion_crowd_performance.gd` (9 tests, on Kaiju City): the ground lookup gives the same height and surface as `GroundHeight` at several thousand points (random, and on, just inside and just off area corners and edges), and is rebuilt when a platform is added or the ground is loaded again; `limit_motion` with the lookup (shortcut taken in many moves) gives the same segments and edge normal as the old piece-by-piece check (a ground without the lookup) over several thousand moves, on the ground, in the air and dropping; the depth grid gives the same z_index as testing every item for two shape sizes at several thousand points, builds once, and is rebuilt once when a meteor boulder is added, which then covers the spots behind it; separation by cells equals every-pair separation exactly for 253 crowded minions (some on one spot); the kept car surface follows the car from a rooftop to the street and back; 120 minions round the parked car still close in on it with the shortcuts.

**Proposal for the safety ceiling (not changed):** 150. After T-444, 200 alive averages 16 to 17.5 ms a frame, but its p99 (21 to 24 ms) is already over the 20 ms budget on this machine, and these numbers leave out drawing on screen and the extra weapon hits a real crowd brings. 150 should sit at about 12 to 13 ms (between the 100 and 200 rows), leaving room for those. 100 now costs about 8 ms. It is only a data change (`enemies.json` `spawning.max_minions_alive`); the board's playtest decides.

**Test results:**
- `python -m unittest discover -s game/tools -p "test_*.py"`: Ran 767, OK (skipped=1).
- `python -m unittest discover -s tools -p "test_*.py"`: Ran 591, OK.
- GUT: 191 scripts, 2327 tests, 2327 passing (T-443's 190 / 2318 plus the new file's 9). The whole suite takes longer than one 10-minute foreground call on this busy machine, so `game/tools/run_tests.sh` (with `GODOT_BIN`, `GUT_TIME_LIMIT=590`) ran in five foreground chunks that together cover every script under `res://tests/`: enemies + weapons + game (35 scripts, 533 tests), hud + level_creator + helpers (44, 486), run (29, 377), and the 83 top-level unit scripts through `-gdir=res://tests/fixtures -gtest=<list>` (42, 485 and 41, 446).

**Screenshots:** none; nothing the player sees changed (`changes_visuals: no`). The numbers above are the evidence.

**Documents affected:** `game/docs/enemies/minions.md` ("How it is built", "Spawning", new "Performance (T-444)"). `docs/enemies.md` unchanged (no game decision changed).

**Outside the enemy files:** none. `game/scripts/level/ground_height.gd` (the Level/Challenge Design Agent's) would be the natural home for the bucket lookup, which would also speed up the car's and other callers' `height_at`; I kept it in the enemies' files because tests and level-creator code change a ground's lists after it is built, and the enemy lookup checks for that. A suggestion for a later ticket, not done.

Nothing under `game/data/levels/` was touched (`game/data/level/kaiju_city_map.json` only read). No refused actions, except one: a hook refused a chained `timeout ... bash game/tools/minion_crowd_bench.sh` loop (it can't tell `timeout` won't write a ticket); I ran the runs as separate commands without `timeout`.
- 2026-10-31, in-progress → in-qa: Built: minions' step ~4.5x faster (100 alive: frame 37 -> 8 ms; 200: 76 -> 17 ms; 300: 119 -> 25 ms), same behaviour; bench game/tools/minion_crowd_bench.sh; ceiling unchanged at 100 (proposal 150); all three test sets pass.
- 2026-10-31, in-qa → done: QA passed
