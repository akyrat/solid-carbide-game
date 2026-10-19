---
id: T-193
title: Elevation sample map: height data for three layers (stacked areas, ramps between rooftops) and a height-data validator
status: in-qa
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

### 2026-10-19, Open → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-193.

### 2026-10-19, In progress → In QA

Goal runner (G-004): the agent is done; QA is checking it.

## Result notes

Level/Challenge Design Agent, 2026-10-19.

- **Stacking field:** a platform's optional `on: "<platform id>"` names the area it stands on. `GroundHeight.load_file` keeps it as `on` ("" when missing); the query doesn't need it (the highest area at a point already wins), only the validator reads it.
- **Ramps between rooftops:** checked `height_at`, `ramp_at`, `area_index_at`, `side_normal`, `edge_between` and `car_height.gd` with a 3-to-6 ramp standing on a height-3 area. Nothing assumed a ramp's foot at street level, so no code fix was needed. The only change is in `edge_between`'s comment: a step's `height` is the difference between the two sides (3 from the height-6 area onto the height-3 one), not a platform's height.
- **Fixture** `game/tests/fixtures/height/three_layers.json`: roof_low (-20, -20, 40 x 40, height 3), roof_high on it (-10, -10, 16 x 16, height 6, `on: roof_low`), ramp_street_to_low (east of roof_low, x 20..32, y -4..4, 0 to 3) and ramp_low_to_high (east of roof_high, on roof_low, x 6..18, y -4..4, 3 to 6). All numbers are proposals.
- **GUT** `game/tests/unit/test_ground_height_layers.gd` (11 tests): street (0, empty ramp, -1), roof_low (3, index 0), roof_high (6, index 1), halfway up the 0-to-3 ramp (1.5, index 2) and the 3-to-6 ramp (4.5, index 3); the 3-to-6 ramp's foot and top with no jump; side normals; edges between layers (a drop of 3 from roof_high onto roof_low); street to second floor along the ramps is never a drop; and `car_height.gd` following both ramps up to 6, then falling off roof_high and landing on roof_low at 3.
- **Validator** `python game/tools/check_height_data.py <file>`: prints `OK` and exits 0, or prints one line per problem and exits 1. Beyond the ticket's list it also rejects an `on` naming an unknown or not-lower area, a ramp climbing to an unknown area, a ramp overlapping an area it doesn't stand on wholly, and missing or repeated ids and bad numbers. Both `elevation_test.json` and the fixture print OK. Tests: `game/tools/test_check_height_data.py` (17 tests). The rejection tests cover overlap with no stacking field, a top that doesn't touch, a top that runs past the side, a bottom_height that doesn't match (both on a rooftop and on the street), a top_height that doesn't match, an unknown side, a stacked area outside its base, unknown ids, a ramp half on an area, and bad JSON.
- **Unchanged:** `game/data/level/elevation_test.json`, `test_ground_height.gd`, `test_car_height.gd` and `test_elevation_edges.gd` (`git diff master` on them is empty).
- **Docs:** `game/README.md` has a new section "Elevation sample map (T-193)" with "Height data", which covers every field (old and new) and the validator. `docs/level-design.md` has Content, "Elevation sample map", **Height data**.
- **Tests:** GUT 1054/1054 passed (TESTS PASSED). Python tool tests: 303 OK (1 skipped). Project tool tests (`tools/`): 331 OK.
- **Screenshots:** none. This is data, a query and a validator with nothing on screen yet, so there is nothing to picture. The next ticket's sample map is the first thing on screen.
- PixelLab: 0 generations. Refusals: none.
