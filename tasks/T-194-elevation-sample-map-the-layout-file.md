---
id: T-194
title: Elevation sample map: the layout file, built by script from the MVP map, with rooftops at 3 and 6 and parking-garage ramps
status: in-qa
from: project-lead
to: level-challenge
lead: Goal-G-004
epic: level-challenges
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: no
depends_on: [T-193]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/tools/build_mvp_map.py, game/tools/test_build_mvp_map.py, game/data/level/mvp_map.json, game/scripts/level/ground_height.gd, game/tools/check_height_data.py, game/scripts/driving/car_height.gd]
files_expected_to_change: [game/tools/build_elevation_sample_map.py, game/tools/test_build_elevation_sample_map.py, game/data/level/elevation_sample_map.json, docs/level-design/elevation-sample-map.png, docs/level-design.md, game/README.md]
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

Level design, Decisions, 'Elevation sample map' (board, 2026-10-19), and Visual style, Decisions, 'Elevation sample map art'. Build the sample map's layout file with a script, the way build_mvp_map.py builds the MVP map.

`game/tools/build_elevation_sample_map.py` reads the MVP map's layout (mvp_map.json: roads, buildings, boulders, the gravel centre, the 240 by 240 size) and writes `game/data/level/elevation_sample_map.json`: the same layout keys mvp_map.gd reads (so the map script can load it in a later ticket), plus `platforms` and `ramps` in the height-data format from the previous ticket (D1). It adds:
- raised areas that are building rooftops: at least one at height 3 and at least one at height 6. A raised area stands where buildings would be, so the MVP buildings under its footprint are left out of the sample file (the board's earlier idea: a raised area about the size of the 2 by 2 grid of blocks, Decisions, 'Raised areas and ramps');
- parking-garage ramps: at least one from the street (0) up to a height-3 rooftop, and at least one from a height-3 rooftop up to a height-6 rooftop, so the car can drive street to 3 to 6 and jump off the top for more airtime;
- no boulder on a raised area's or a ramp's footprint (drop those boulders from the sample file), and no ramp foot blocked by a building, a boulder or the map's edge.
The heights used are exactly 0, 3 and 6. Size the ramps for the car (it is 1 by 3 units; roads are 24 wide); every size and position is the agent's proposal for the board's playtest.

The script has a check mode (it rebuilds in memory and says if the committed file differs), and it runs the D1 validator on its output. Python tests check the file: heights are exactly {0, 3, 6}; at least one area at 3 and one at 6; at least one 0-to-3 ramp and one 3-to-6 ramp; every height-6 area is reachable from the street by going up ramps (a graph walk over areas and ramps); no ramp foot is blocked; no boulder on any raised area or ramp; the validator accepts the file. mvp_map.json is not changed.

Draw an overview picture of the layout, flat, with the street, height 3 and height 6 in different colours and the ramps marked with their direction (docs/level-design/elevation-sample-map.png, also in art-archive/<task id>/screenshots/), and link it from docs/level-design.md, Content, 'Elevation sample map', with a short description of the layout. Mark every layout choice as a proposal for the board's playtest. If the docs leave something open (for example whether a boulder may sit on a rooftop), pick the safe option above and list it as an open question in the result notes; don't ask during the goal run.

The board's review: The layout of the elevation sample map (overview picture docs/level-design/elevation-sample-map.png), judged in the goal's final playtest.

## Acceptance criteria

- [ ] `python game/tools/build_elevation_sample_map.py` writes game/data/level/elevation_sample_map.json, and its check mode reports no difference against the committed file. (QA: pass)
- [ ] game/tools/test_build_elevation_sample_map.py passes and checks: the heights used are exactly {0, 3, 6}; at least one raised area at 3 and one at 6; at least one ramp with bottom 0 and top 3 and one with bottom 3 and top 6; every height-6 area is reachable from the street by going up ramps; no ramp foot overlaps a building, a boulder or lies outside the map; no boulder overlaps a raised area's or a ramp's footprint. (QA: pass)
- [ ] `python game/tools/check_height_data.py game/data/level/elevation_sample_map.json` exits with code 0. (QA: pass)
- [ ] The sample file keeps the MVP map's size and the layout keys mvp_map.gd reads (buildings, boulders and the rest), with no building inside a raised area's footprint. (QA: pass; covered by the 20 passing tests)
- [ ] game/data/level/mvp_map.json is unchanged (git diff against master is empty), and the existing test_build_mvp_map.py and test_mvp_map.gd tests pass. (QA: pass)
- [ ] docs/level-design/elevation-sample-map.png exists, shows the layout flat with heights 0, 3 and 6 in different colours and the ramps marked, is linked from docs/level-design.md (Content, 'Elevation sample map'), and a copy is in art-archive/<task id>/screenshots/. (QA: pass)
- [ ] docs/level-design.md and game/README.md describe the layout and how to rebuild it, with every layout choice marked as a proposal for the board's playtest. (QA: pass)
- [ ] All three test sets pass. (QA: pass: game/tools 323 OK, GUT TESTS PASSED; the tools/ suite ran very slowly in QA and was not seen to finish, but this ticket changes nothing under tools/, and the agent reported 331 OK)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-19, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-194.

### 2026-10-19, In progress → In QA

Goal runner (G-004): the agent is done; QA is checking it.

## Result notes

Written by the agent when it finishes.

**Level/Challenge Design Agent, 2026-10-19.** Done; every layout choice is a proposal for the board's playtest.

What was built:
- `game/tools/build_elevation_sample_map.py` reads `game/data/level/mvp_map.json` (unchanged) and writes `game/data/level/elevation_sample_map.json`: every MVP layout key mvp_map.gd reads (`map`, `gravel`, `buildings`, `pattern_copies`, `challenges`, `challenge_designs`, `ground_rows`, ...), same 240 by 240 size, plus `platforms` and `ramps` in the T-193 height-data format. It runs `check_height_data.check_data` on its output (refuses to write invalid data) and has `--check` (rebuilds in memory, exit 1 on a difference or invalid data). It also draws the overview PNG (standard library PNG writer).
- Layout (proposal): two parking garages, the second the first turned half a turn about the centre. North-west: first-floor rooftop (3) at x -96..-12, y -96..-66 (the top row's two west blocks and the road between); second-floor rooftop (6, `on` the first) at x -42..-12 (30 by 30), its N/E/S sides dropping 6 to the street. 0-to-3 ramp on the first floor's south side (x -86..-76, y -66..-54); 3-to-6 ramp on the first floor climbing the second floor's west side (x -54..-42, y -86..-76). Ramps 12 long per 3 of rise (test scene's slope), 10 wide. Drive: street → 3 → 6 → off the east edge onto the x 0 road.
- Left out of the sample file: 4 buildings under rooftops; 8 boulders on a rooftop, a ramp or the 6-unit strip in front of a ramp foot (copies 11, 16, 45, 50, all Two Boulders, which leaves them empty, so they are dropped); challenge-5 (on copy-16; challenges are off in the MVP). `ground_rows` rebuilt with the remaining buildings; `challenge_rule` counts updated.
- Tests: `game/tools/test_build_elevation_sample_map.py` (20 tests): heights exactly {0, 3, 6}; area at 3 and at 6; 0→3 and 3→6 ramps; reachability graph walk (every area, so every height-6 one, reachable from the street); ramp footprint and foot strip clear of buildings, boulders and the map edge, foot strip on the ramp's bottom ground; no boulder on a rooftop or ramp; no building under a rooftop; only those buildings/boulders dropped; MVP size and keys kept; validator accepts the file; check mode matches and catches a changed/missing file; picture uses distinct colours for 0, 3 and 6.

Test runs: `python -m unittest discover -s game/tools -p "test_*.py"`: 323 tests OK (1 skipped, pre-existing; this includes the existing test_build_mvp_map.py). `bash game/tools/run_tests.sh`: TESTS PASSED (includes test_mvp_map.gd). `python -m unittest discover -s tools -p "test_*.py"`: 331 tests OK. `python game/tools/check_height_data.py game/data/level/elevation_sample_map.json`: OK. `python game/tools/build_elevation_sample_map.py --check`: OK. mvp_map.json not touched.

Screenshots: nothing on screen yet (the map scene is a later ticket), so a picture drawn from the data by the script: `art-archive/T-194/screenshots/elevation-sample-map.png` (same as `docs/level-design/elevation-sample-map.png`, linked from Level design, Content, "Elevation sample map"). Grey street, tan gravel, purple buildings, light blue = height 3, amber = height 6, ramps shaded foot→top with a white arrowhead pointing uphill, orange dots = boulders.

Documents updated: `docs/level-design.md` (Content, "Elevation sample map": the layout, picture, proposals), `game/README.md` ("Elevation sample map", "The layout file (T-194)", how to rebuild and check).

Open questions for the board's playtest (settled with the safe option, not asked during the goal run):
- Boulders on rooftops: none (dropped every boulder on a rooftop, a ramp or in front of a ramp foot).
- Two garages instead of one, and 84 by 30 first floors rather than the 2 by 2 block size from "Raised areas and ramps": every 2 by 2 group of blocks includes a gravel-centre block, so a 2 by 2 rooftop would cover part of the gravel; the rooftops stay on building blocks and the road between them.
- The rooftops cover the road between their two blocks, so that stretch of road (x -66..-42 north, x 42..66 south) is no longer street.
- Ramp size 12 by 10 per 3 of rise; the 0→3 ramps take 12 of the 24-unit road in front of them, leaving 12 to drive past.
- `ground_rows` marks cells under a rooftop as road (`R`), since the legend has no rooftop letter; the heights come from `platforms`.

PixelLab: none used (0 generations). Refusals: none. Godot's line-ending-only `.import` changes from the test run were left uncommitted.
