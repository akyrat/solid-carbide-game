---
id: T-182
title: Elevation test scene: ground-height data (one platform, one ramp, drop-off edges) and a ground-height query
status: open
from: project-lead
to: level-challenge
lead: Goal-G-003
epic: level-challenges
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, game/README.md, game/data/level/mvp_map.json, game/scripts/driving/test_room.gd]
files_expected_to_change: [game/data/level/elevation_test.json, game/scripts/level/ground_height.gd, game/tests/unit/test_ground_height.gd, game/README.md, docs/level-design.md]
model: sonnet
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

The board's go-ahead for elevation (2026-10-19): docs/level-design.md, Decisions, 'Raised areas and ramps', and docs/drifting.md, Decisions, 'Elevation'. This task builds only the ground side of the elevation test scene: data and a query, no drawing and no car changes.

1. Store the test scene's layout as data in `game/data/level/elevation_test.json`, in the flat top-down world's units (the same units as the car and the drift prototype): one raised platform about the size the docs give as an example (a 2 by 2 grid of blocks is the map's scale; for the test scene a platform the car can drive onto and across comfortably, roughly 16 by 16 units, is a proposal), with its outline (an axis-aligned rectangle in the flat world) and its height in units; and one ramp on one of its sides, with its footprint (rectangle), the side of the platform it climbs (north/east/south/west in the flat world), its bottom height (0) and its top height (the platform's). Every other platform edge is a drop-off. The docs say the map's data format must leave room for heights and ramps for the board's later level editor, so keep the format general: a list of platforms and a list of ramps, not hard-coded single objects. Heights and sizes are proposals for the board's playtest.
2. Write `game/scripts/level/ground_height.gd` (a RefCounted loaded from that file) with: `height_at(point: Vector2) -> float` (0 off the platform, the platform's height on top, a straight rise along the ramp from 0 at its foot to the platform's height at its top); and a way to tell a ramp from a drop-off, for example `is_ramp(point)` and `edge_between(a: Vector2, b: Vector2)` returning whether moving from a to b crosses a drop-off step (and its height) or not. The car work in the next tasks (elevation physics, edges) builds on this query, so keep it free of nodes and physics.
3. GUT tests in `game/tests/unit/test_ground_height.gd`.
4. Describe the format in `game/README.md` (a new 'Elevation test scene' section, 'Ground-height data' part) and describe the test platform, ramp and drop-off edges and the height data format in `docs/level-design.md`, Content (a new 'Elevation test scene' section), marking every number as a proposal.

## Acceptance criteria

- [ ] `game/data/level/elevation_test.json` exists and holds one platform (outline and height) and one ramp (footprint, the side it climbs, bottom height 0 and top height equal to the platform's), as lists so more can be added later. (QA: pass / fail)
- [ ] `game/scripts/level/ground_height.gd` loads that file and `height_at()` returns 0 off the platform, the platform's height on top, and a straight rise along the ramp; GUT tests check a point off the platform, a point on top, the ramp's foot, the ramp's middle (half the platform's height) and the ramp's top. (QA: pass / fail)
- [ ] GUT tests show the query tells a ramp from a drop-off: moving in small steps across the ramp's climbing direction changes the height gradually (no step bigger than the step's share of the slope), while crossing any other platform edge is reported as a drop-off step of the platform's height. (QA: pass / fail)
- [ ] `game/README.md` has an 'Elevation test scene' section describing the data file's format and the query's functions. (QA: pass / fail)
- [ ] `docs/level-design.md`, Content, describes the test platform, the ramp, the drop-off edges and the height data format, with each number marked as a proposal. (QA: pass / fail)
- [ ] The full GUT suite passes headless (`game/tools/run_tests.sh` or `.ps1`), with no existing test changed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
