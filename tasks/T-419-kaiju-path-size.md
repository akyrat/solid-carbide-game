---
id: T-419
title: The kaiju only takes paths it fits through
status: in-progress
from: project-lead
to: enemy-behavior
lead: Audit
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/kaiju_boss.gd, game/scripts/enemies/kaiju.gd, game/scripts/enemies/enemy_path_follower.gd, tasks/T-379-minions-twice-as-big.md]
files_expected_to_change: [game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/kaiju_boss.gd]
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

Enemies, Decisions: "The kaiju only takes paths it fits through". Bug: enemy_navigation.gd closes cells only 0.5 units around buildings (BUILDING_MARGIN, CELL 2.0), sized for minions, but the kaiju's radius is 2.0. Its path goes through gaps it can't fit and to waypoints under 1 unit from a wall, which it can never reach (REACH 1.0), so it slides on the wall and re-plans every second, mostly when the car is on a rooftop. Plan per body size. T-379 (open, another session) doubles the minions' size and will need the same; build it so the size comes from each enemy.

The board's review: stand on a rooftop on the board's level while the kaiju is out, and see it walk round buildings without getting stuck.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] On the board's level, every waypoint of the kaiju's planned path is at least its radius from every building (test over 50 start/target pairs). (QA: pass / fail)
- [ ] A gap narrower than the kaiju's diameter is never on its path; minions still use it. (QA: pass / fail)
- [ ] In a scripted run, the kaiju reaches a target behind two buildings within 30 s without stopping for more than 2 s. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Build J (Audit): started on playtest/audit-world, worktree C:\solid-carbide-worktrees\T-419, Enemy Behavior Agent.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Enemy Behavior Agent, 2026-10-30: done.**

What changed:
- `game/scripts/enemies/enemy_navigation.gd`: one navigation per body size. `for_map(map, radius = -1, fit_edges = false)` keeps each on the map (`meta_key()`; the minions' keeps the old key). `building_margin` = the body's radius: the minions' from `minion_radius()` (BASE_MARGIN x `minion.size_scale`, T-379), the kaiju's `RADIUS_UNITS` (2). Cells strictly nearer than the radius to the map's edge are closed too (minions unchanged: their cells sit exactly 1 unit off it). With `fit_edges` (the kaiju) cells where its body would hang over a rooftop's or ramp's edge are closed (`EnemyHeight.fits`, only near area boundaries), and drop links span up to `drop_span` (3) cells, from the last cell it fits on above to the first below (`is_drop` allows that distance). Where a ramp's end point doesn't fit (Kaiju City: an AC unit prop sits right on ramp-12's top point), the path keeps its own cells over that ramp. `clearance()` / `_fits_at()` added.
- `game/scripts/enemies/kaiju_boss.gd`: `for_map(map, KaijuScript.RADIUS_UNITS, true)`.
- `game/scripts/enemies/enemy_path_follower.gd` (not in files_expected_to_change; needed): while the target is a drop's landing, the follower keeps its path for up to another REPATH_SECONDS. Without it the kaiju's drop (which starts 3 units back from the edge, over a second's walk) re-planned from over the edge back up to the top point and walked to and fro (caught by the existing kaiju drop test).
- Why the edges too: with only the building margin the 50-pair check passed, but 139 of 2640 kaiju waypoints still put its body over a rooftop edge, and 5 of 10 scripted runs to a car on roof-1 jammed for the whole 60 s (the reported "stuck when the car is on a rooftop"). With the edge fit: 0, and 10 of 10 reach the car.
- Minions: their grid is unchanged (edge_radius 0, drop_span 1); the only change they see is the ramp-end fallback where a prop is on the ramp's end point, and the drop commitment.
- Build time on Kaiju City: minions about 75 ms, kaiju about 115 ms, both at the run's start.
- Tool: `game/tools/draw_kaiju_nav.gd` / `.sh` draws a level's kaiju grid and paths (old in red, new in cyan).
- Docs: `docs/enemies.md`, Content, "Enemies on rooftops and ramps": a bullet for T-419 (the decision itself unchanged). `game/docs/enemies/ledges-and-rooftops.md`: new section "A way planned for each body's size (T-419)".

Tests: `game/tests/unit/enemies/test_kaiju_path_size.gd` (new, 6 tests; the board's level tests skip with a message when `res://data/levels/kaiju_city.json` is missing):
- Criterion 1: 50 seeded start/target pairs on Kaiju City (9 to rooftops, 3094 waypoints): nearest waypoint to any building, prop or boulder 2.00 units; 0 waypoints over an edge.
- Criterion 2: synthetic map, 3 and 3.5-unit gaps: minions go through, the kaiju goes round the wall's end; a 6-unit gap is used by the kaiju through its middle.
- Criterion 3: a street spot to a car on a rooftop with two buildings on the line between (searched, seeded): reached in 20.7 s, longest stop (staying within 1 unit of a spot) 0.72 s. Also a car on roof-1 from ten street spots: all reached, longest stop under 0.8 s. Kaiju City has no street-to-street pair with two buildings between and a path under 78 units, so the target is on a rooftop (the reported case).
- `test_enemies_on_heights.gd`: the navigation test now checks that the kaiju has its own (renamed `test_one_navigation_per_map_for_the_minions_and_one_for_the_kaiju`).

Test runs (all three sets, on this branch): Godot GUT 2131/2131 passed (173 scripts, 752 s; test_run_likes passed in the full run); `game/tools` Python 722 OK (1 skipped); `tools` Python 582 OK.

Screenshots: `art-archive/T-419/screenshots/kaiju_nav_roof.png`, drawn from the data by `bash game/tools/draw_kaiju_nav.sh` (Kaiju City, 4 px per unit, the car on roof-1 as the white square): orange cells are open to minions and closed to the kaiju; red lines are the kaiju's paths on the old (minions') grid, hugging walls and edges; cyan the paths now, at least 2 units off.

Board review files: art-archive/T-419/screenshots/kaiju_nav_roof.png
