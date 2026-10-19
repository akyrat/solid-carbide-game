---
id: T-194
title: Elevation sample map: the layout file, built by script from the MVP map, with rooftops at 3 and 6 and parking-garage ramps
status: in-progress
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

- [ ] `python game/tools/build_elevation_sample_map.py` writes game/data/level/elevation_sample_map.json, and its check mode reports no difference against the committed file. (QA: pass / fail)
- [ ] game/tools/test_build_elevation_sample_map.py passes and checks: the heights used are exactly {0, 3, 6}; at least one raised area at 3 and one at 6; at least one ramp with bottom 0 and top 3 and one with bottom 3 and top 6; every height-6 area is reachable from the street by going up ramps; no ramp foot overlaps a building, a boulder or lies outside the map; no boulder overlaps a raised area's or a ramp's footprint. (QA: pass / fail)
- [ ] `python game/tools/check_height_data.py game/data/level/elevation_sample_map.json` exits with code 0. (QA: pass / fail)
- [ ] The sample file keeps the MVP map's size and the layout keys mvp_map.gd reads (buildings, boulders and the rest), with no building inside a raised area's footprint. (QA: pass / fail)
- [ ] game/data/level/mvp_map.json is unchanged (git diff against master is empty), and the existing test_build_mvp_map.py and test_mvp_map.gd tests pass. (QA: pass / fail)
- [ ] docs/level-design/elevation-sample-map.png exists, shows the layout flat with heights 0, 3 and 6 in different colours and the ramps marked, is linked from docs/level-design.md (Content, 'Elevation sample map'), and a copy is in art-archive/<task id>/screenshots/. (QA: pass / fail)
- [ ] docs/level-design.md and game/README.md describe the layout and how to rebuild it, with every layout choice marked as a proposal for the board's playtest. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-19, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-194.

## Result notes

Written by the agent when it finishes.
