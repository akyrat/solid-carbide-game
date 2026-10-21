---
id: T-207
title: Enemies follow the car up the ramps on the elevation map, with pathfinding
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
files_to_read_first: [tasks/README.md, docs/enemies.md, docs/level-design.md, game/README.md, tasks/T-206-run-on-the-elevation-sample-map.md, game/scripts/enemies/enemy_depth.gd, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/scripts/enemies/, game/tests/unit/, docs/enemies.md, game/README.md, art-archive/T-207/screenshots/]
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

**Rewritten after the board's playtest (2026-10-21).** In T-206's build the run plays on the elevation sample map, and the enemies completely ignore every raised surface. The board decided how they handle heights (Enemies, Decisions, "Enemies follow the car up the ramps"): enemies treat rooftops as raised ground they can reach only by the ramps. To reach a car on a rooftop they find their way to a ramp, go up it and follow the car, with pathfinding over the map's streets, ramps and rooftops. A rooftop's edge blocks them like a wall from below. Enemies on a rooftop stay on it until they go down a ramp.

Build that for every enemy that chases the car. Enemies get a height like the car's (from the map's ground height), are drawn at it in the right depth order, and their contact damage only hits the car when they are at the car's level. Pathfinding: use what Godot gives (for example a navigation mesh or an A* grid built from the map file's heights and ramps); choose what fits and say why in the result notes. It must stay fast with as many enemies as the run spawns (the T-206 soak reached 21 on screen). Enemies that spawn from the screen edges spawn on the street. For the kaiju and anything the decision doesn't cover, make a proposal for the playtest and list it in the result notes. Do not add new enemies or change their stats, numbers or attacks.

This builds on T-206's work, which is still being tweaked: branch from `task/T-206-run-on-elevation-map`, merge it again before handing over if it has moved, and this ticket merges only after T-206.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the work (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] In a GUT test with the car parked on a height-6 rooftop, enemies that start on the street reach it by going up the ramps (their path passes through the ramps, never through a rooftop's edge), within a time limit the test states (QA: pass / fail)
- [ ] In a GUT test with the car on the street, enemies on a rooftop come down by a ramp to reach it; no enemy crosses a rooftop's edge from below, in a test that drives enemies at every edge (QA: pass / fail)
- [ ] Enemies are drawn at their height in the right depth order next to the rooftops, ramps and the car, and contact damage only hits the car at its level (screenshots of enemies on a ramp and on a rooftop, and a test for the damage) (QA: pass / fail)
- [ ] A 2-minute scripted run on the elevation map has no errors during play, and the result notes give the frame time with the most enemies on screen, compared with T-206's soak (QA: pass / fail)
- [ ] Enemies, Decisions has this ticket's id on "Enemies follow the car up the ramps", and the result notes list every proposal made (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run on the elevation map and judge how the enemies follow the car up and down the ramps.
Board review files: a run from the main menu.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Started from T-206's build: enemies find their way up the ramps to the car, with pathfinding, as the board decided.

## Result notes

Written by the agent when it finishes.

### Enemy Behavior Agent, 2026-10-21

**What was built** (`game/scripts/enemies/`; how it is built: `game/README.md`, "Enemies on the rooftops and ramps (T-207)")
- `enemy_height.gd`: the shared rules. An enemy stands on the ground under its centre. A move whose ground height changes by more than 0.6 units is refused, so every rooftop edge is a wall from below and from above, and so is the high part of a ramp's sides. The body has to fit, so it keeps its whole radius off an edge. Moves are checked in 0.25-unit pieces, so a weapon's knockback can't jump an edge. Contact damage only hits the car at its level.
- `minion.gd` and `kaiju.gd`: every walk and knockback step goes through `_move()`, which first limits the move by the edges and then calls `move_and_collide` as before. An edge works like a wall normal, so the detour logic also works along edges. `contact_step()` checks the level first.
- `enemy_navigation.gd`: the pathfinding (see below), built once per map and shared by the minions and the kaiju.
- `enemy_path_follower.gd`: one per enemy. An enemy on the car's surface walks straight at the car, as before. Otherwise it follows a path. It gets a new path when the car changes surface and then every second. At most 4 new paths are found per step, so a crowd asks over a few steps.
- `minion_spawner.gd` and `kaiju_boss.gd`:
  - Spawning and the kaiju's arrival happen on the street only.
  - Sprites and coins are drawn lifted by their height, with their depth order taken at that height (`enemy_depth.gd`).
  - Minions only push apart from minions at their own level.
  - A minion on its way to a ramp is kept up to 120 units from the car.
  - `heights_enabled` (default true) switches all of this off, for comparison.
- Nothing about the enemies' stats, numbers or attacks changed. No new enemies.

**The pathfinding choice:** Godot's `AStar2D` on a grid of 2 x 2 unit cells over the whole map. That is about 12 250 open cells, and the grid builds in about 27 ms when a run starts.
- Cells in a building or on one of the map's boulders are left out.
- Two neighbouring cells are linked only when their ground heights differ by 0.6 or less. So rooftop edges are never linked, and the only links between levels run along the ramps.
- A path that climbs a ramp is changed to two points on the ramp's centre line, so the 4-unit-wide kaiju also goes up the middle.
- Why this choice:
  - The heights in the map file are rectangles whose edges all lie on even units, so a 2-unit grid matches them exactly and needs no baking.
  - A link that exists only where the height allows is exactly what "an edge blocks like a wall" means.
  - `AStarGrid2D` can't remove a link between two open cells.
  - A navigation mesh would need a mesh per level, plus links for the ramps.

**Proposals for the playtest** (all listed in `docs/enemies.md`, Content, "Enemies on the rooftops and ramps")
1. A ramp's sides are walls except near its foot, where the ramp is still under 0.6 units high.
2. Contact damage hits when the car's height, including in the air, is within 1 unit of the ground the enemy stands on. A car that jumps more than 1 unit over a minion isn't hit.
3. The kaiju follows the same rules as the minions: it arrives on the street, climbs the ramps, edges stop it, and it only hits the car at its level, even though it is taller than the highest rooftop.
4. A minion on its way to a ramp isn't removed for being off screen while it is within 120 units of the car (half the map; the farthest a rooftop is from its ramp's foot is about 80). Without this, minions walking round to a far ramp were removed and replaced endlessly, and none reached a car parked on a rooftop.
5. Minions push apart only from minions within 1 unit of their height.
6. Coins are drawn and stay at the height where the minion died. Picking them up is unchanged (by driving over them, at any height).
7. Weapons are unchanged: they find and hit enemies at any height. A weapons ticket can change this.
8. At most 4 paths per step, a new path every second, and the 0.6 step are numbers in the code, not balancing data.

**Frame time** (headless, physics time per step from `Performance.TIME_PHYSICS_PROCESS`, and the minions' own step from `run.minions.last_step_usec`)
- The 2-minute scripted run with the game window's screen size (`run_elevation_soak_screen.tscn`, up to 21 minions, 16 on screen at most):
  - Physics step: mean 2.86 ms, p99 7.72 ms, max 12.56 ms.
  - With 15 or more on screen: physics 5.45 ms, minions' step mean 1.62 ms (max 2.05 ms).
- The same run with the enemies ignoring heights, as in T-206 (`..._screen_no_heights.tscn`, 21 minions, 18 on screen at most):
  - Physics step: mean 2.35 ms, p99 8.10 ms, max 12.81 ms.
  - With 17 or more on screen: minions' step mean 1.33 ms (max 1.63 ms).
- Stress test (`enemies_heights_stress.tscn`): 30 minions put on screen round a car parked at height 6, so all of them need paths.
  - With heights: minions' step mean 3.06 ms, p99 5.07 ms. All 30 reached the height-6 car in about 30 s (40 s run).
  - Without heights: mean 2.82 ms, p99 6.74 ms.
- The measurements were noisy (other sessions were running on the machine). Overall, heights cost roughly 0.3 to 1 ms per step at T-206's numbers, well within a 20 ms physics step.
- Note: in a headless run the viewport is tiny and the camera zoom follows it. So T-206's soak, run headless, spawns and removes minions much closer to the car than in play. The `_screen` variants and the stress fixture use the game window's 1152 x 648 screen for that reason.
- Note: T-206's soak puts the car at (-81, -40) and (81, 40). Both points are inside buildings (-96..-66, -42..-12 and 66..96, 12..42).

**2-minute scripted run (AC 4):** `python game/tools/run_scene_headless.py res://tests/fixtures/run_elevation_soak.tscn 150 --show`, exactly as T-206 ran it.
- The car spent time on the street and at heights 3 and 6. There were up to 16 minions, 4 level-up screens, and the kaiju came.
- Result: "quit by itself, no errors", with no error lines at all.
- The `_screen` variant shows only the known exit-time line `ERROR: 1 resources still in use at exit` (T-206's notes, the engine sound). It prints nothing during play.

**Tests**
- New: `game/tests/unit/enemies/test_enemies_on_heights.gd`, 22 tests. Highlights:
  - AC 1: minions from 4 street spots reach a car parked on each height-6 rooftop by both ramps. The test's time limit is 40 s; they took 14.6 to 27.2 s. No minion changed height by more than 0.6 in one step.
  - AC 2: minions on the rooftops come down ramp-nw-0-3 (and ramp-nw-3-6 from height 6) to a car on the street, in 5.7 to 16.3 s. Minions driven at every rooftop edge (every side, every 3 units, about 150 points, ramp stretches left out) never climb an edge from below and never step off one from above. A knockback doesn't push one over an edge.
  - AC 3: drawn lifted by their height, and in the depth order (over the roof it stands on, under it from behind, under a higher roof in front, over a ramp it is on). Contact damage only at the car's level (from below an edge, from above, with the car in the air).
  - Also covered: the grid (no link across any edge, buildings and boulders closed), path order, the path budget, keeping climbers, spawning on the street, the MVP map unchanged, and the kaiju (climbs to height 3 in 13.2 s, stopped by an edge, hits only at its level, arrives on the street).
- Full GUT suite after the last merge of T-206: 1169/1169 passed.
- `python -m unittest discover -s tools -p "test_*.py"`: 414 OK.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 354 OK (1 skipped).

**Screenshots** (`art-archive/T-207/screenshots/`, each a run started from the main menu)
- `enemies_heights_ramp.png`: minions climbing ramp-nw-0-3 to the car on roof-nw-3.
- `enemies_heights_rooftop.png`: minions on ramp-se-3-6, one already on roof-se-6 by the car.
- `enemies_heights_edge.png`: minions on the street under roof-nw-3's edge, walking round to the ramp instead of through the edge.
- `enemies_heights_kaiju.png`: the kaiju half way up ramp-nw-0-3, drawn at its height.

**Other files**
- Fixtures:
  - `game/tests/fixtures/enemies_heights_demo.gd` with 4 `.tscn` screenshot scenes.
  - `enemies_heights_stress.gd` with 2 scenes.
  - `run_elevation_soak.gd`: T-206's file. I added the frame-time summary and the `enemy_heights` and `real_screen` switches; the defaults behave as before. Two `_screen` scenes go with it.
- Merged `task/T-206-run-on-elevation-map` twice. The second merge had one conflict in `game/README.md` (T-206's tweak line, which now also mentions tyre marks); I kept T-206's text and updated its note about enemies at street level.

**Documents affected:** `docs/enemies.md` (a new Content section, "Enemies on the rooftops and ramps"; the decision already had "(T-207)") and `game/README.md` (the new section, plus two notes in "The run's map (T-206)" about enemies at street level).

**Refused commands** (skipped, not retried in another form):
- A Bash chain starting with `git check-ignore -v .env`. The guard couldn't tell it wouldn't write a ticket. I wanted to check that `.env` is ignored before giving this worktree a `.env` with only the `GODOT_BIN` line, which the test runner needs. I read `.gitignore` instead, then wrote that one-line `.env` (git-ignored).
- `sed -n 455,470p <test file>` (read-only, but the guard took it for a sed that writes). I used the Read tool instead.
