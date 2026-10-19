---
id: T-193
title: Elevation sample map: height data for three layers (stacked areas, ramps between rooftops) and a height-data validator
status: open
from: project-lead
to: level-challenge
lead: Goal-G-004
epic: level-challenges
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: no
depends_on: [T-182]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, game/README.md, game/scripts/level/ground_height.gd, game/data/level/elevation_test.json, game/tests/unit/test_ground_height.gd, game/scripts/driving/car_height.gd]
files_expected_to_change: [game/scripts/level/ground_height.gd, game/tests/unit/test_ground_height_layers.gd, game/tests/fixtures/height/three_layers.json, game/tools/check_height_data.py, game/tools/test_check_height_data.py, game/README.md, docs/level-design.md]
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

Level design, Decisions, 'Elevation sample map' (board, 2026-10-19): a drive-only city-sized map with three layers, the street (height 0), a first floor (height 3) and a second floor (height 6), joined by ramps from the street to the first floor and from the first floor to the second. This ticket gets the height data and the ground-height query ready for it. It does not build the sample map itself (that is the next ticket). No tricks, no level editor.

What exists: GroundHeight (game/scripts/level/ground_height.gd, T-182/T-184) already reads lists of platforms and ramps, and a ramp already has bottom_height. What is missing:

1. Stacking. A height-6 area may stand on a height-3 area (a higher rooftop on a lower one). Add an optional, documented field to a platform naming the area it stands on (for example `on: "<platform id>"`), so a deliberate overlap can be told from a mistake. height_at and area_index_at must still give the highest area at a point (this already holds; keep it and test it).
2. Ramps between rooftops. A ramp with bottom_height 3 standing on a height-3 area and climbing to a height-6 area. Its `platform` field names the area it climbs to. Check that height_at, ramp_at, area_index_at, side_normal and edge_between give the right answers there, and fix anything that assumes a ramp's foot is at street level.
3. A validator: `game/tools/check_height_data.py <file>` (exit code 0 if valid, non-zero with one line per problem if not), with Python tests. It rejects: two areas that overlap when neither is marked as standing on the other; a platform marked as standing on an area that doesn't contain its whole footprint; a ramp whose top side doesn't touch the area it names; a ramp whose bottom_height doesn't match the ground at its foot (the street's 0, or the height of the area its foot is on), or whose top_height doesn't match the area it climbs to; an unknown ramp side. It accepts game/data/level/elevation_test.json and a hand-made three-layer fixture (game/tests/fixtures/height/three_layers.json: one height-3 area, one height-6 area on it, a 0-to-3 ramp and a 3-to-6 ramp). The next ticket runs it on the sample map file.
4. GUT tests (test_ground_height_layers.gd) on the fixture: height_at, ramp_at and area_index_at for a point on the street, on the height-3 area, on the height-6 area, halfway up the 0-to-3 ramp (1.5) and halfway up the 3-to-6 ramp (4.5).

Keep the file format a list of areas a level editor could later edit (Level design, Decisions). The elevation test scene must not change: elevation_test.json is not edited and its tests pass unchanged. Document every field (old and new) in game/README.md and in docs/level-design.md, Content (a new 'Elevation sample map' subsection, 'Height data' part). Every number is a proposal for the board's playtest. Nothing to picture: say so in the result notes in one line.

## Acceptance criteria

- [ ] game/tests/fixtures/height/three_layers.json has a height-3 area, a height-6 area marked as standing on it, a ramp with bottom_height 0 and top_height 3, and a ramp with bottom_height 3 and top_height 6 standing on the height-3 area. (QA: pass / fail)
- [ ] GUT tests in game/tests/unit/test_ground_height_layers.gd check height_at, ramp_at and area_index_at on that fixture for a point on the street (0, empty ramp, -1), on the height-3 area (3), on the height-6 area (6), halfway up the 0-to-3 ramp (1.5) and halfway up the 3-to-6 ramp (4.5), and they pass. (QA: pass / fail)
- [ ] `python game/tools/check_height_data.py game/data/level/elevation_test.json` and the same on the three-layer fixture exit with code 0. (QA: pass / fail)
- [ ] game/tools/test_check_height_data.py has tests where the validator rejects (non-zero exit, a message naming the problem): two overlapping areas with no stacking field; a ramp whose top side doesn't touch the area it names; a ramp whose bottom_height doesn't match the ground at its foot; a ramp whose top_height doesn't match the area it climbs to. The Python tool tests pass. (QA: pass / fail)
- [ ] game/data/level/elevation_test.json is unchanged (git diff against master is empty), and test_ground_height.gd, test_car_height.gd and test_elevation_edges.gd pass unchanged. (QA: pass / fail)
- [ ] game/README.md and docs/level-design.md (Content, 'Elevation sample map') document every height-data field, including the new stacking field and a ramp's bottom_height, and how to run the validator. (QA: pass / fail)
- [ ] All three test sets (GUT, Python tools, headless scene run) pass; the result notes say in one line that there is nothing to picture. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
