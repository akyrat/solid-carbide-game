---
id: T-226
title: Enemies jump down off ledges to chase the car
status: in-progress
from: project-lead
to: enemy-behavior
lead: Coursework
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/README.md, tasks/T-207-enemies-on-the-elevation-map.md, game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/enemy_path_follower.gd, game/scripts/enemies/enemy_height.gd]
files_expected_to_change: [game/scripts/enemies/, game/tests/unit/, docs/enemies.md, game/README.md, art-archive/T-226/screenshots/]
model: opus
qa_rounds: 0
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

The board noticed in a playtest (2026-10-21) that enemies on a rooftop won't jump off its edge to chase a car below: they walk all the way round to a ramp. The board's decision (Enemies, Decisions, "Enemies jump down off ledges"): going down, enemies jump (drop) off a rooftop's edge to chase the car. Going up still needs a ramp, and an edge still blocks them from below (T-207).

Add one-way links in the pathfinding (`enemy_navigation.gd`, T-207's A* grid) from a rooftop's edge cells down to the cells below, so a path down can drop off an edge, and make the enemy fall to the lower level when it does, landing on the ground below (falling like the car does, with gravity, or a short drop: your proposal). Its height and depth order follow it as it falls. Enemies still never climb an edge, and still never end up inside a building. Keep it fast with as many enemies as the run spawns. Proposals for the playtest, in the result notes: how the drop looks, whether an enemy can hurt the car while falling, and whether the kaiju jumps down too.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots and a short GIF of enemies dropping off a rooftop to chase the car (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] In a GUT test with enemies on a height-6 rooftop and the car on the street beside it, the enemies drop off the nearest edge instead of walking to a ramp, and reach the car sooner than before (the test states both times) (QA: pass / fail)
- [ ] Tests show enemies still can't climb an edge from below, still use the ramps to go up, and never end up inside a building (QA: pass / fail)
- [ ] A falling enemy's height and depth order follow it down (test, and a GIF from a run in `art-archive/T-226/screenshots/`) (QA: pass / fail)
- [ ] A 2-minute scripted run on the elevation map has no errors during play, and the result notes give the frame time with the most enemies on screen (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run, go below enemies on a rooftop and watch them jump down after you.
Board review files: the GIF in `art-archive/T-226/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started: enemies drop off rooftop edges to chase a car below.

## Result notes

Written by the agent when it finishes.

### Enemy Behavior Agent, 2026-10-21

**What was built** (`game/scripts/enemies/`; how it is built: `game/README.md`, "Enemies drop off ledges (T-226)"; what the game does: `docs/enemies.md`, Content, "Enemies drop off ledges")
- `enemy_navigation.gd`: one-way drop links in T-207's A* grid, from every rooftop cell beside lower ground (more than 0.6 units lower, on one of its four sides, neither cell on a ramp) down to that cell. 238 on the elevation map. Nothing links back up, so going up is still by the ramps only. `is_drop()` tells a drop in a path from a ramp's two end points. `build_for_map(map, false)` builds T-207's grid without drops, used as the tests' "before".
- `enemy_path_follower.gd`: `dropping()` says when the enemy's path drops off the edge in front of it.
- `enemy_height.gd`: the edge rules take the body's height and a `drop` flag. Ground higher than the body is always a wall. Only an enemy dropping on purpose (or already falling) may walk out over an edge. Walking, pushing apart and a weapon's knockback never take an enemy over an edge.
- `enemy_fall.gd` (new): the fall, with the car's gravity (12 units/s²), from rest.
- `minion.gd`, `kaiju.gd`: `may_drop`, `fall`, `body_height()`, `is_falling()`. Contact damage uses the height in the air.
- `minion_spawner.gd`, `kaiju_boss.gd`: drawn at the height in the air, in the depth order at that height, with the falling animation on. `drops_total` counts drops for the soak.
- `minion_sprite.gd`, `kaiju_sprite.gd`: the falling animation (the board's addition to this ticket). It is a placeholder made by script from the walk frames: the legs flail (the walk cycle 3 times as fast, 2.5 for the kaiju), the body tips from side to side (0.35 rad for a minion, 0.15 for the kaiju) and the minion stretches a little. On landing there is a short squash. It plays from the moment the enemy leaves the edge until it lands. No Redgull red. The kaiju's ground shadow is hidden while it is in the air.
- **The art hook for T-227:** put sheets at `game/art/minion/minion_fall_<dir>.png` and `game/art/kaiju/kaiju_fall_<dir>.png`, with `<dir>` = e, se, s, ne, n (the other three are mirrored, as for the walk). Frames are the walk's frame size (48 px for the minion, 224 for the kaiju), in one row, as many as the sheet is wide, played at `FALL_FPS` (10 for the minion, 8 for the kaiju). A direction whose sheet exists is drawn from it without the scripted tilt, and one whose sheet is missing keeps the placeholder. No code change is needed. The constants are `FALL_SHEET_DIR` and `FALL_FPS` in both sprite scripts.
- **A bug found on the way and fixed:** every mirrored walk frame (facing west, south-west or north-west) was drawn one frame width to the right of the enemy. Godot draws a negative-width rect from its x towards +x, flipped. So the kaiju's art stood beside its own shadow and health bar (about 112 screen pixels at zoom 1), and minions were 24 px off. This was in the code since T-068/T-069, and it showed up in this ticket's recording. Both sprites now place the rect at `-size / 2`. Worth a look in the playtest: west-facing enemies now stand on their shadow and hitbox.

**Proposals for the playtest** (all in `docs/enemies.md`, "Enemies drop off ledges")
1. How the drop looks: the enemy walks out over the edge and falls like the car, from rest with the car's gravity. That takes about 0.7 s from height 3 and 1 s from height 6, and it keeps walking at its usual speed while falling, so it lands a few units out from the wall. While falling it plays the scripted flail and tilt placeholder, then a squash on landing.
2. Hurting the car while falling: yes, with the same level rule as on the ground but using its height in the air. It hits only when the car is within 1 unit of that height, so an enemy landing on the car hits it and one still high above doesn't.
3. The kaiju drops too, with the same rules, fall and animation (tilt 0.15 rad, squash 0.25 s, no ground shadow in the air).
4. Enemies never drop off a ramp's sides, only off rooftop edges (the decision names rooftop edges).
5. An enemy may step over an edge only when its own path drops there, and only within 3 units of the edge's path point. Pushing apart and knockback never drop it.
6. The animation numbers (flail speed, tilt, wobble 3 Hz / 1.5 Hz, stretch, squash 0.18 s / 0.25 s) and the gravity are numbers in the code, not balancing data.

**Before and after (AC 1)**, `test_minions_on_a_height_6_rooftop_drop_off_the_edge_to_a_car_below_sooner_than_by_the_ramps`: four minions on roof-nw-6, with the car on the street just south of its edge at (-20, -60).
- Before (T-207's grid, by the ramps): 22.7, 24.7, 21.8 and 25.0 s.
- After (dropping off the edge): 3.7, 1.9, 5.6 and 4.2 s. None of them walked on a ramp, all dropped, none was ever in a building, none climbed.
- The kaiju from roof-nw-6 to the same car: 6.5 s, by dropping.

**Frame time** (the 2-minute scripted run, `python game/tools/run_scene_headless.py res://tests/fixtures/run_elevation_soak_screen.tscn 150 --show`, headless, game-window screen size)
- First run, up to 18 minions on screen: physics step mean 2.92 ms, p99 8.63 ms, max 12.47 ms. With 17 or more on screen: physics 3.25 ms, minions' own step mean 1.63 ms (max 2.12 ms).
- Second run, which also counts drops: 15 on screen at most, physics mean 3.82 ms, p99 8.28 ms, max 12.87 ms. With 14 or more on screen: minions' step mean 2.14 ms (max 2.90 ms). Minions dropped off edges 24 times.
- T-207's numbers were mean 2.86 ms, p99 7.72 ms, and minions' step 1.62 ms at 15 or more on screen, so this is about the same. The machine was shared with other sessions, so the numbers are noisy. The navigation builds in 43 ms (T-207 measured 27 ms on a quieter machine; the drop links add one pass over the grid).
- AC 4: during play there are no error lines. The only error is the exit-time line `ERROR: 2 resources still in use at exit`, which T-207 recorded as "1 resources" (the engine sound). The full GUT run ends with the same "1 resources" line.
- `run_elevation_soak.tscn` (T-206's headless-screen variant) also ran with no errors during play, and minions dropped 51 times.

**Tests**
- New: `game/tests/unit/enemies/test_enemies_drop_off_ledges.gd`, 13 tests.
  - The drop links are one-way and present on every edge.
  - A path down drops once and is much shorter, and a path up still uses both ramps.
  - AC 1, with both times printed.
  - AC 2: with `may_drop` on, a minion still can't climb an edge from below. Without a drop on its path, it doesn't step off. Street minions still go up by both ramps, with no falls. Minions from every rooftop to cars around them never end up in a building and never climb.
  - AC 3: a falling minion's height only goes down, from 6 to the street over about 49 steps. Its drawing is lifted by that height, and it is in the depth order at that height, at every step. The falling animation plays exactly while it falls, then "land", then "walk".
  - The sprites' animation states. The falling art is absent, so the placeholder is used.
  - The fall time under the car's gravity (1 s from 6).
  - Contact damage while falling. Knockback never goes over an edge.
  - The kaiju drops, and its falling animation plays only while it falls.
- Changed in `test_enemies_on_heights.gd` (T-207), because the decision changed: "no link more than a step apart" is now "no link climbs more than a step, and every drop link is one-way"; "no link across a rooftop edge" is now "no link up a rooftop edge"; and the ramp-down test now runs with the drops left out. The other 19 are unchanged and pass.
- Full GUT suite: 1288/1288 passed.
- `python -m unittest discover -s tools -p "test_*.py"`: 439 tests, OK.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 388 tests, OK (1 skipped).

**Screenshots and recordings** (`art-archive/T-226/screenshots/`, from runs started from the main menu, recorded with Godot's movie maker from the new fixtures `game/tests/fixtures/enemies_drop_gif.tscn` and `enemies_drop_kaiju.tscn`, script `enemies_drop_demo.gd`; I looked at the frames)
- `enemies_drop_off_ledge_close.gif`: close-up, 2x, of six minions on roof-nw-6 dropping off its south edge, tilted and flailing in front of the wall, to the car parked below.
- `enemies_drop_off_ledge.gif`: the same, wider.
- `kaiju_drop_off_ledge.gif`: the kaiju walking to roof-nw-6's edge, falling in front of the wall and landing by the car.
- `enemies_drop_falling.png`, `enemies_drop_falling_2.png`: stills of minions mid-fall in front of the wall.
- `enemies_drop_landed_at_car.png`: the minions landed at the car.
- `kaiju_drop_falling.png`: the kaiju mid-fall. The pale yellow rings over it are its meteor windup, which happened to start then.
- `kaiju_drop_landed.png`: the kaiju landed by the car, standing on its shadow (with the mirror fix).
- There is also a still fixture, `enemies_drop_falling.tscn` (zoom 9, 2.1 s in).

**Documents affected:** `docs/enemies.md` (a new Content section, "Enemies drop off ledges"; T-207's "Edges are walls" and "Finding the way" bullets now point to it) and `game/README.md` (a new section, "Enemies drop off ledges (T-226)", with the art hook, plus T-207's test notes updated).

**Refused commands** (skipped and not retried in the same form):
- A Bash chain that started with `S=<scratchpad path> && ...` to build the GIF and contact sheets. The guard couldn't tell that a shell variable assignment wouldn't write a ticket. I ran the GIF tool on its own with full paths, as the refusal message suggested.
- A Bash chain with `rm -f <scratchpad>/drop/*` before recording again ("the guard can't read the command"). I recorded into new scratchpad folders instead and deleted nothing.
