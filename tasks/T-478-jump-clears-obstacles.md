---
id: T-478
title: Jump: the Space hop clears obstacles lower than the car
status: done
from: project-lead
to: driving-drift
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, game/scripts/driving/car.gd, game/scripts/driving/car_height.gd, game/scripts/driving/jump_power_up.gd, game/data/power_ups.json, tasks/T-461-jump-space-makes-a-small-hop.md]
files_expected_to_change: [game/scripts/driving/, game/tests/unit/, docs/drifting.md]
model: sonnet
qa_rounds: 3
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

The board, 2026-11-01 (Drifting, Decisions, "The Jump clears obstacles"): with the Jump power-up, the car can hop over obstacles with Space. Today every obstacle (physics layer 1: boulders, buildings, walls, the map's edge) blocks the car at any height (car.gd, LAYER_OBSTACLES), so the hop (about 1 unit high at tier 1) can't clear anything. Enemies already work: the board confirmed the car takes no damage while above them.

Make the car pass over an obstacle while its height is above that obstacle's top, and meet it as a wall (the bounce, as today) when it is lower. The map's edge always blocks. Buildings and walls taller than the hop keep blocking. Find each obstacle's height where the game already has it (the ground's heights, boulder records); where an obstacle has none, propose one in the result notes and say which obstacles a tier-1 hop clears and which it doesn't. The car never lands inside an obstacle (as Content, "Elevation: the platform's sides", for platforms). Keep the jump's numbers. Never write, move or commit anything in game/data/levels/.

The board's review: own the Jump, hop over a boulder, and hit a tall building.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A test shows the car hopping (Jump power-up, tier 1) over a boulder lower than the hop's height, with no bounce and no hit_obstacle. (QA: pass; round 2: test_jump_real_run.gd loads game.tscn, start_run, Kaiju City map boulders; tier 1 hop pressed at the nose clears every clean-lane boulder, no hit)
- [ ] A test shows the same car, too low or on the ground, bouncing off that boulder as today. (QA: pass; round 2: same real drive with no press hits the boulder; a press 2.5 units late bounces)
- [ ] A test shows a building taller than the hop still blocks the car in the air, and the map's edge always does. (QA: pass; round 2: test_jump_clears_obstacles.gd wall and edge blocks in the air still green)
- [ ] A test shows the car never ends a physics step inside an obstacle when it lands. (QA: pass; round 2: real-run landing tests stand at the obstacle top height, drive off the far edge, no hit)
- [ ] The result notes list each obstacle kind with its height and whether each Jump tier clears it. (QA: pass; round 2: table updated with collision heights per tier)
- [ ] A GIF or screenshots of the car hopping over a boulder are saved and listed in the result notes. (QA: pass; round 2: real_run_hop_boulder_barrier_landing.gif is the real game, HUD and map boulders, car mid-hop)
- [ ] docs/drifting.md (Content) describes how the hop clears obstacles. (QA: pass)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass; round 2: GUT 2526/2526 in 213 scripts, game/tools 858 OK, tools 635 OK; round 3: GUT 2529/2529 in 214 scripts (first run hit the 1500 s limit on a loaded machine, rerun alone with 2400 s passed), Python sets green)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Started: the Jump clears obstacles lower than the car.

### 2026-11-01, Needs playtest

Passed QA: the Jump hops over boulders and low props; tall buildings and the map edge still block. Ready for the board to play.

### 2026-11-01, Needs playtest → In progress

Back to the Driving & Drift Agent: in your playtest the hop still doesn't clear barriers or boulders, and landing on one must work.

### 2026-11-01, Needs playtest → In progress

Jump works; back to the Driving & Drift Agent to draw the car over the obstacles it's jumping over.

### 2026-11-01, Needs playtest

Round 3 (draw order) passed QA: the car is drawn over obstacles while it jumps them. Ready to play.

### 2026-11-01, Needs playtest

The board: LGTM. Merging after the current batch.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (Driving & Drift Agent).** Findings first: the pass-over-by-height machinery already existed (T-405: `mvp_map.gd` `update_car_obstacles`, props and boulders as collision exceptions by height). What stopped the hop was the numbers: a boulder's height was its 3-unit diameter and the tier 1 hop peaks at 1.04, so nothing but the smallest props was clearable, and a car that landed over an obstacle was left inside it, sliding out.

**How it works now**
- Boulders (the map's and the meteors') are **0.8 units high** (`BOULDER_HEIGHT_UNITS`, proposal; width stays the 3-unit diameter), lower than the car's 1. The car passes over an obstacle once its height is at the top (minus 0.05) or above; lower, it meets it as a wall with the bounce and `hit_obstacle`, as before. Walls (skyscrapers) and the map's edge block at any height; 3-unit platforms (short buildings) keep their side-wall rule.
- Never landing inside (proposal): `mvp_map.gd obstacle_floor()` gives the top of the obstacle the car overlaps and is over; car.gd's `floor_query` asks it just before the height step, and `car_height.gd` (`floor_height`, `set_floor`) lands the car on that top, lets it drive along it, and makes it fall when it leaves the edge. Wired in run.gd and elevation_sample_map.gd.
- Jump numbers unchanged. Timing at tier 1: the hop reaches 0.75 about 0.2 s after Space, so Space must be pressed roughly 6 to 7 units short of a boulder at speed; later, it bounces (tested).

**Obstacle table** (hop peaks: tier 1 1.04, tier 2 1.5, tier 3 2.04, tier 4 2.67)
| Obstacle | Height | Clears |
|---|---|---|
| Boulder (map and meteor) | 0.8 (proposed) | all tiers |
| Props 0.9, 0.95 (creator_assets.json height_units) | 0.9, 0.95 | all tiers |
| Props 1.2 to 1.5 | 1.2 to 1.5 | tier 2 and up (1.5 is borderline at tier 2) |
| Prop 2.2 | 2.2 | tier 4 |
| Props 3.3 and 5.35 | 3.3, 5.35 | none |
| Short buildings (platforms) | 3.0 | none (side is a wall below 3) |
| Skyscrapers | 30 (wall) | none |
| Map's edge | infinite | never |

**Tests:** new `game/tests/unit/test_jump_clears_obstacles.gd` (8 tests: hop clears boulder with no hit and never inside; ground and too-late and no-power-up bounce; lands on top; wall and edge block in the air; table). Counts: GUT 2326/2326 (191 scripts); `game/tools` unittest 849 OK (1 skipped); `tools` unittest 633 OK.
**Files:** car.gd, car_height.gd, mvp_map.gd, run.gd, elevation_sample_map.gd, tests/fixtures/jump_boulder_demo.gd and jump_boulder_gif.tscn, docs/drifting.md (Content, "The Jump clears obstacles (task T-478)").
**GIF and screenshots:** `art-archive/T-478/screenshots/jump_over_boulder.gif`, `jump_over_boulder_montage.png`.
**Note for the board's playtest:** the boulder is drawn big (3 wide, taller than 0.8 looks), so a hop over it reads as flying over a tall rock; the car's sprite also draws behind the boulder sprite for a moment mid-hop (depth order, not changed here). If 0.8 feels wrong, it is one constant.
- 2026-11-01, in-progress → in-qa: Jump now clears boulders (0.8 high) and low props by height; lands on top, never inside; tests green, GIF saved.
- 2026-11-01, in-qa → needs-playtest: QA pass: 9/9 criteria; GUT 2510/2510 (210 scripts), Python 849 + 633 OK. Own the Jump, hop a boulder, hit a tall building.
- 2026-11-01, needs-playtest → in-progress: The board played it (2026-11-01): still can't jump over barrier obstacles or even boulders; account for the player landing on one of these obstacles and make it work as expected.


---

### Round 2 (the board's playtest, 2026-11-01: "i still cant jump over barrier obstacles or even boulders ... account for the player landing on one")

**What was wrong** (reproduced in the real run: `game.tscn`, Start, the Kaiju City map, Jump tier 1, the car driving at full speed, 16.5 units/s, at the map's real boulders and barriers). The run's obstacles do go through `update_car_obstacles` (82 props, 9 boulders, all on layer 1, heights from `obstacle_heights`; the walls and edge are separate bodies), so it was not a different system. Two things stopped the hop:
1. **Timing.** The first version needed the car at 0.75 units high before it touched the obstacle, i.e. Space pressed 5 or more units short of a boulder (probe: press 5, 7, 9 cleared, press 3 hit). A player presses when the drawn nose (the sprite is 3 long, the collision body 1x1, so contact comes 1 unit, 0.06 s, later) looks level with the obstacle. Pressed there, the car was at 0.27 units on contact and bounced (tested: "x -2.0, maxh 0.27, hit the boulder" on 8 of 8 street boulders).
2. **Heights.** The barrier is 1.2 and the parked cars 1.35, above a tier 1 peak of 1.04, so no press could clear them.

**The fix** (all numbers are proposals for the board):
- **Rising pass** (`mvp_map.gd` `_is_over`, `RISE_PASS_FRACTION` 0.1): a car that is rising, whose apex clears the obstacle's top, passes it once it is 10% of the way up from the foot. A Space pressed with the nose level with the obstacle clears it, and a press up to about 0.04 s later does too; later it bounces (tested).
- **Prop heights** (`PROP_HEIGHT_SCALE` 0.75): a prop's collision height is 0.75 of its `height_units`, so tier 1 (peak 1.04) clears barrier 0.9, cones 0.68, broken cars 0.71. Alternative if the board prefers: raise tier 1's takeoff speed from 5 to 6 (peak 1.5) and keep the real heights; that touches `power_ups.json` and the tier ladder, so I did not.
- **Landing on top** (`obstacle_floor`, now also for a car falling through an obstacle it passes, using the vertical speed; `car_height.gd` `floor_height`): the car lands on the top of a boulder or a barrier, stands at its height, drives along it and falls off its far edge to the street; it is never left inside, and never snapped sideways.

**Obstacle table on the Kaiju City map** (collision height; tier peaks 1.04 / 1.5 / 2.04 / 2.67)
| Obstacle | Collision height | Tiers that clear it |
|---|---|---|
| Boulder (9) | 0.8 | 1 to 4 |
| Barrier | 0.9 (1.2 x 0.75) | 1 to 4 |
| Cones | 0.68 | 1 to 4 |
| Broken cars | 0.71 | 1 to 4 |
| Parked cars | 1.01 | 2 to 4 |
| AC unit, roof vent (on rooftops, base 3) | about 1.1 | 2 to 4 (from the roof) |
| Crates | 1.65 | 3, 4 |
| Roof sign, water tank | 2.5 | 4 |
| Street lamp | 4.0 | none |
| Short-building platforms | 3.0 | none; their side is a wall |
| Skyscrapers, the map's edge | wall | none |

**Real-run tests** (`game/tests/unit/test_jump_real_run.gd`, 6 tests, the real game scene and the map's own boulders and barriers): a tier 1 hop pressed with the nose at the obstacle clears every street boulder with a clean lane and the barrier; the same drive with no press hits the obstacle; a press 2.5 units too late bounces; the car lands on a real boulder and on a real barrier, stands at the top height, drives along and off the far edge with no hit; heights of every boulder and barrier are lower than the car. Also kept: `test_jump_clears_obstacles.gd` (8 tests).
**Counts:** GUT 2526/2526 (after merging master); `game/tools` unittest 858 OK (1 skipped); `tools` unittest 635 OK.
**GIF and screenshots (real run):** `art-archive/T-478/screenshots/real_run_hop_boulder_barrier_landing.gif` (a hop over a boulder, over a barrier, and a hop that lands on a boulder and drives off it) and `real_run_montage.png` (12 frames from it). Fixture: `game/tests/fixtures/jump_boulder_gif.tscn`. The earlier fixture GIF was replaced.
**Files:** `game/scripts/level/mvp_map.gd`, `game/scripts/run/run.gd`, `game/scripts/level/elevation_sample_map.gd`, the tests and fixture above, `docs/drifting.md` (Content, "The Jump clears obstacles (task T-478)").
- 2026-11-01, in-progress → in-qa: Real-run fix: rising hop clears boulders and barriers at a natural press, lands on top; real-run tests and GIF; all tests green.
- 2026-11-01, in-qa → needs-playtest: QA round 2 pass: real-run Jump clears boulders and barriers, lands on top; GUT 2526, py 858+635 OK
- 2026-11-01, needs-playtest → in-progress: The board played round 2 (2026-11-01): 'it works but the obstacles are drawn over the car when jumping over them.'

### Round 3 (the board's playtest: "it works but the obstacles are drawn over the car when jumping over them")

**Cause:** the car's z_index in `elevation_layer.gd z_for` put it under every boulder and prop sprite that covers it on screen, whatever the car's height; and a sprite at the top z_index shares it with an uncovered car, so the tree order decided.
**Fix** (only the draw order): boulder and prop sprites got `top_units` (the collision top, `mvp_map.gd` `_BoulderSprite`, `level_props.gd` `PropSprite`); `ElevationLayer.car_over_sprite()` says a car is above a sprite when its height is at the top (within 0.05) or past half of the way up it (a hop's rise); `z_for` then draws the car one over that sprite (never over a building that covers it). A car on the ground behind an obstacle, and sprites with no height (alert signs), keep the old order; the car's shadow stays under the obstacle.
**Test:** `game/tests/unit/test_jump_draw_order.gd` (3 tests, the real run, a real boulder and a real barrier): on the ground behind it the car is under it; above it, landed on top and past half of its rise it is over it; a sprite with no height changes nothing.
**Tests run (only what changed, plus the depth tests):** test_jump_real_run 6, test_jump_draw_order 3, test_jump_clears_obstacles 8, test_short_platforms 16, test_boulder_art 10, test_see_through_map 15, test_kaiju_signs 7, test_creator_alert_signs 13, test_elevation_sample_depth 11, test_gift_drops_heights 9, test_gift_drops_shadow 4: all pass.
**GIF (real run, a hop over a boulder, over a barrier, and a landing on a boulder, the car drawn over them):** `art-archive/T-478/screenshots/real_run_car_over_obstacles.gif`; zoom of three hop frames: `art-archive/T-478/screenshots/real_run_car_over_boulder_zoom.png`. These replace the round 2 GIF and montage.
- 2026-11-01, in-progress → in-qa: Car now drawn over the obstacle it hops over or lands on; draw-order test and real-run GIF added.
- 2026-11-01, in-qa → needs-playtest: QA round 3 pass: car drawn over hopped obstacles, depth tests green; GUT 2529/2529, Python sets green
- 2026-11-01, needs-playtest → done: lgtm
