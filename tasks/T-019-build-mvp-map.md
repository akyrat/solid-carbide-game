---
id: T-019
title: Build the MVP map: city grid, obstacle patterns and preset challenges
status: done
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, game/README.md]
files_expected_to_change: [the map scene and its scripts, the map's layout data file, their tests, screenshots, docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/level-design.md, docs/level-design/, docs/game-loop-architecture.md, docs/visual-style.md, docs/drifting.md, game/README.md, .claude/agents/level-challenge.md, docs/extended-narrative.md]
model: opus
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The rule for completing a challenge is in Level design, Decisions (2026-10-08): the drawn car touches the corridor continuously from the arrow's start to its end, in the arrow's direction; leaving it midway means starting again.

Build the MVP map in Godot as Level design describes it, with flat placeholder colours (no PixelLab): the board will look at the layout and the challenges before any art.

- **The city grid** (Level design, Decisions): 80 by 80 units, 1 unit = the car's width; an 8-unit perimeter road with a hard stop at the edges; 10 by 10 building blocks in a 4 by 4 grid with 8-unit roads; the 28 by 28 gravel centre with no blocks. Buildings and the map edge block the car, which bounces off them slightly (Drifting, Decisions). The map must be easy to drop the T-012 car into later (same units and physics rate); it does not need the car to be finished.
- **Obstacle patterns and fitting the sketches:** the board's drawings in `docs/level-design/` are rough sketches of the general shape (Level design, Decisions). Make fitted versions that work on the map: as drawn they measure about 11 by 12, 11 by 13 and 11 by 20 units with their 3-unit corridors, and the roads are 8 units wide. Adjust size, spacing and how tight the loops are as needed, but keep the shape: the number of boulders (3 units across), which way the arrow goes around each boulder, and the overall path. Save each fitted version next to its sketch (for example `arrow-1.fitted.json` and `.svg`) and leave the sketches unchanged. Place copies of the 2 patterns. How many copies and where is this agent's call (Level design, Decisions); list them with their positions in the result notes so the board can adjust. Boulders block the car.
- **Preset challenges:** choose 30% of the pattern copies to be challenges, the same on every run (round to the nearest whole number, at least 1, and say how in the result notes). For a Single Boulder challenge, pick one of its 2 arrows. Each challenge shows its arrow on the ground as a 3-unit-wide corridor (a flat placeholder band with an arrowhead is fine; the painted animation comes later).
- **Completing a challenge** (rule in Level design, Decisions): the arrow disappears, the boulders stay as plain obstacles for the rest of the run, and the map sends a clear "challenge completed" signal that XP and the HUD will hook into later. Awarding XP itself is not part of this task.
- **Layout data:** save the placed buildings, pattern copies, boulders and challenges (with their arrow points in map units) to one data file, so tests, the drivability check (T-021) and the board can read the map without opening Godot.
- **Docs:** `game/README.md` explains how to open the map scene. In `docs/level-design.md`, add a `### MVP map` subsection under Content (what was built, where the patterns and challenges are, with a screenshot) and link the layout data in References; do not change Summary, Decisions or Open questions. Follow `docs/README.md`.

Before handing challenges over, this agent normally checks they are drivable with the Driving & Drift Agent's script. That script is T-021 and needs the Godot car (T-012), so here, list which challenges still need that check; the check happens when T-021 is done.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test reading the layout data shows the map is 80 by 80 units, with the perimeter road, the 16 blocks minus the centre ones, the 8-unit roads and the 28 by 28 gravel centre at the positions Level design gives (QA: pass)
- [x] A test shows every boulder is 3 units across, and every pattern copy matches its fitted version; a test shows each fitted version keeps its sketch's number of boulders and the arrow's direction around each boulder (QA: pass)
- [x] A test shows the number of challenges is 30% of the pattern copies, rounded as the result notes say, and the same on every run (QA: pass)
- [x] A test shows no challenge corridor and no boulder overlaps a building or lies outside the map (QA: pass)
- [x] A test drives a stand-in body along one challenge per the completion rule and shows the "challenge completed" signal fires once, the arrow disappears, and the boulders remain (QA: pass)
- [x] A screenshot of the whole map (with the T-001 screenshot tool) shows the grid, the boulders and the challenge arrows (QA: pass)
- [x] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` is unchanged (QA: pass)
- [x] `game/README.md` explains how to open the map; `docs/level-design.md` has the `### MVP map` subsection and links the layout data, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: look at the map screenshot and the list of pattern copies and challenges, and adjust if needed.

Board review files: [docs/level-design/mvp-map.png, docs/level-design/mvp-map-iso.png, game/scenes/level/mvp_map_overview.tscn, game/data/level/mvp_map.json]

## Result notes

**Level/Challenge Design Agent, 2026-10-09.** Built on branch `task/T-019-build-mvp-map`.

**What was built**

- `game/tools/build_mvp_map.py` (Python, standard library) reads the board's sketches (unchanged) and writes the fitted versions next to them (`docs/level-design/single-boulder/arrow-1.fitted.json/.svg`, `arrow-2.fitted.*`, `docs/level-design/two-boulders/arrow-1.fitted.*`) and the layout data `game/data/level/mvp_map.json`: map size, buildings, an 80 x 80 grid of ground cells (R/G/B, the sketches' legend), the 12 pattern copies with their boulders, and the 4 challenges with their arrow points and centre lines, all in map units. Running it twice gives identical files.
- `game/scripts/level/mvp_map.gd` + `game/scenes/level/mvp_map.tscn`: the map in Godot, built from the data. 16 px per unit and the flat physics world, like the T-012 car; static bodies (12 buildings, 4 edge walls, one body per copy for its boulders) on collision layer 1; drawing flat or isometric (`set_view`). Give it the car (`map.car = car`) or call `update_car()` per physics step; on completion the arrow is hidden, the boulders stay, and `challenge_completed(challenge_id)` fires once.
- `challenge_tracker.gd` (the completion rule), `challenge_arrow.gd` (placeholder arrow: a blue 3-unit band, white start dot, arrowhead), and `map_overview.gd` with the overview scenes `mvp_map_overview.tscn` (flat) and `mvp_map_overview_iso.tscn`, for viewing and screenshots.
- Screenshots: `docs/level-design/mvp-map.png` (flat) and `mvp-map-iso.png`, taken with the T-001 tool (`bash game/tools/screenshot.sh res://scenes/level/mvp_map_overview.tscn screenshots/mvp_map.png 10`).

**Pattern copies and challenges** (centre in units from the map's centre, x right, y down; rotation clockwise on screen):

| Copy | Pattern | Centre | Rotation | Challenge |
|---|---|---|---|---|
| copy-01 | Single Boulder | -18, -18 | 0 | challenge-1, arrow 1 (clockwise) |
| copy-02 | Single Boulder | 0, -18 | 0 | |
| copy-03 | Single Boulder | 18, -18 | 0 | |
| copy-04 | Single Boulder | -18, 0 | 0 | |
| copy-05 | Single Boulder | 18, 0 | 0 | |
| copy-06 | Single Boulder | -18, 18 | 0 | |
| copy-07 | Single Boulder | 0, 18 | 0 | |
| copy-08 | Single Boulder | 18, 18 | 0 | challenge-2, arrow 2 (counter-clockwise) |
| copy-09 | Two Boulders | 0, -36 | 90 | challenge-3 |
| copy-10 | Two Boulders | 36, 0 | 0 | |
| copy-11 | Two Boulders | 0, 36 | 90 | challenge-4 |
| copy-12 | Two Boulders | -36, 0 | 0 | |

**Rounding:** challenges = 30% of the copies, rounded half up (floor(n x 0.3 + 0.5)), at least 1. 12 copies: 3.6, so 4 challenges.

**Choices made for the board to review** (Level design left these open):

1. Coordinates: units from the map's centre (as Crash City Grid), so the map is -40 to 40; the map's centre is the Godot node's origin.
2. Copies: Single Boulder on all 8 road crossings inside the perimeter road (the centre crossing is gravel); Two Boulders in the middle of each side of the perimeter road, running along it. 12 copies in all.
3. Challenges: Single Boulder at -18, -18 (arrow 1) and 18, 18 (arrow 2), and the Two Boulders on the top and bottom sides, so they are spread over the map and both Single Boulder arrows are used.
4. Fitting: the Single Boulder is fitted to a road crossing (more room than a straight road); the Two Boulders to a straight 8-unit road, so it is squeezed across the road (loops 4.5 units wide at the centre line instead of about 8) and keeps its length and its 7-unit boulder spacing. Arrow points were moved as little as possible so the centre line stays 2 units from each boulder's centre and the corridor 0.25 units from buildings. Directions are kept: Single Boulder arrow 1 clockwise 387 degrees (sketch 389), arrow 2 counter-clockwise 400 (sketch 431), Two Boulders clockwise 408 then counter-clockwise 339 (sketch 422 and 332).
5. The corridor's centre line is the same curve the sketches' pictures draw (quadratic curves through the midpoints between the arrow points), stored in the data as `centre_line`.
6. Completion rule details: the drawn car is a 3 x 1 unit rectangle centred on the car's position, nose along its rotation. A run starts when it touches the corridor at the arrow's start point; progress only moves forward and only along the stretch of arrow within 8 units of the furthest point reached (so a figure-eight crossing or a loop's start and end can't skip ahead); one physics step without touching the corridor at all resets it.
7. Placeholder colours: dark grey roads, tan gravel, purple buildings, dark boulders with an orange rim, blue arrows (Visual style: map challenge arrows are blue). The map's edge is 4 invisible walls 8 units thick.
8. Not done here: the car's bounce off buildings, edges and boulders is the car's collision response (Driving & Drift; `car.gd` has no collisions yet). The map provides the colliders.

**Drivability:** not checked yet; it needs the Driving & Drift Agent's script (T-021). All 4 challenges (challenge-1 to challenge-4) need that check.

**Tests (run before handing over):** `bash game/tools/run_tests.sh`: TESTS PASSED, 73/73, including `tests/unit/test_mvp_map.gd` (19 tests: grid, blocks, ground cells, roads, colliders, boulder size, copies vs fitted versions, fitted vs sketches, 30% rule, same every run, no overlap or leaving the map, a stand-in body completing a challenge once with the arrow hidden and boulders kept, every challenge completable, leaving midway, driving backwards, starting midway). `python -m unittest discover -s game/tools -p "test_*.py"`: OK (includes 15 new tests in `test_build_mvp_map.py`, which also fail if the generated files are out of date). `python -m unittest discover -s tools -p "test_*.py"`: OK. No PixelLab call was made.

**Documents affected:** `docs/level-design.md` (new `### MVP map` under Content, layout data linked in References; Summary, Decisions and Open questions unchanged) and `game/README.md` (new "MVP map" section, folder table). `python tools/generate_long_gdd.py --check` reports the long GDD stale for level-design.md (exit 1, no structure problem); regenerating it is the Project Lead's. Also updated this agent's working notes, `agent-notes/level-challenge.md`.

### QA round 1

2026-10-09, QA/Integration Agent, in `C:\solid-carbide-worktrees\T-019` on `task/T-019-build-mvp-map`. All 9 criteria pass. Everything was re-run; the builder's results were not relied on. Besides the agent's tests, an independent QA script (not committed) re-checked the layout data from scratch.

1. **City grid: pass.** `test_mvp_map.gd` checks size, the 12 blocks, every one of the 6400 ground cells, the 8-unit perimeter and inner roads, and the 16 colliders (12 buildings + 4 edges). Independently: `mvp_map.json` is 80 x 80 (rect -40..40), the 12 buildings are exactly the 10 x 10 blocks at -32, -14, 4, 22 on each axis minus the 4 centre ones, the gravel is -14..14 (28 x 28), and every ground cell matches the rule (0 mismatches). This matches Level design, Decisions.
2. **Boulders and fitted patterns: pass.** All 16 boulders are 3.0 across (data and colliders, radius 1.5 units). Every copy's boulders match its fitted version moved and turned; each challenge's arrow points match its fitted arrow. Independent winding check (sketch vs fitted, + is clockwise): Single Boulder arrow 1 +389 / +387, arrow 2 -431 / -400, Two Boulders +422 / +408 and -332 / -339. Boulder counts are 1, 1 and 2 in both. `git diff --name-status master...HEAD -- docs/level-design/` lists only added files (the 3 fitted pairs and the 2 screenshots), so the board's sketches are unchanged.
3. **30% rule: pass.** 12 copies, floor(12 x 0.3 + 0.5) = 4 challenges, at least 1, as the result notes say; 4 copies are marked as challenges. Two map instances give identical challenges. `python game/tools/build_mvp_map.py` re-run by QA produced no diff (deterministic, and the data on disk is current).
4. **No overlap, inside the map: pass.** Sampling each centre line every 0.05 units: corridor clearance to the nearest building is 0.300 (challenge-1), 0.261 (challenge-2), 0.250 (challenge-3 and 4); to the map edge at least 0.250. Every boulder is clear of buildings, inside the map, and on a road cell.
5. **Completion with a stand-in body: pass.** `test_driving_a_challenge_completes_it_once` drives a 1 x 1 unit CharacterBody2D along challenge-1: `challenge_completed("challenge-1")` fires exactly once (also after driving it again), the arrow is hidden, all boulder bodies remain in the tree with their shapes, and the other challenges are untouched. Further tests cover all 4 challenges completing, leaving midway (reset), driving backwards and starting midway (no completion).
6. **Screenshot: pass.** QA took its own with the T-001 tool: `bash game/tools/screenshot.sh res://scenes/level/mvp_map_overview.tscn <scratch>/qa_mvp_map.png 10` (and the `_iso` scene). Both 1152 x 648. Viewed: the grid of 12 purple blocks, the tan gravel centre, the 16 boulders, and 4 blue arrows with start dots and arrowheads, at the positions in the table above. They match `docs/level-design/mvp-map.png` and `mvp-map-iso.png`.
7. **No PixelLab call: pass.** `game/art/pixellab-generation-log.jsonl` has no change on the branch (`git diff master...HEAD`) or in the working tree, and no commit on the branch touches it.
8. **Docs: pass.** `game/README.md` has an "MVP map" section saying how to open the overview scenes (F6) and take a screenshot. `docs/level-design.md` has `### MVP map` under Content with both screenshots, and links `game/data/level/mvp_map.json` in References. Its `##` headings are still Summary, Decisions, Content, Open questions, References, and the diff only adds lines in Content and References, so Summary, Decisions and Open questions are unchanged.
9. **Tests: pass.** `bash game/tools/run_tests.sh`: TESTS PASSED, 8 scripts, 73/73 tests (19130 asserts), `test_mvp_map.gd` 19/19. `python -m unittest discover -s game/tools -p "test_*.py"`: 60 tests OK. `python -m unittest discover -s tools -p "test_*.py"`: 70 tests OK.

Observations for the Project Lead and the board (not failures):

- The car's bounce off buildings is T-033, and the long GDD is stale for `level-design.md` until the Project Lead regenerates it; neither was counted.
- The Two Boulders copies are squeezed into an 8-unit road: their centre line runs 2.25 units from each boulder's centre, so the 3-unit blue band covers part of each boulder, and the corridor is only 0.25 units from the map edge and the buildings. Whether a real car can drive it is the T-021 check (all 4 challenges still need it); this is the tightest one.
- challenge-3 and challenge-4 sit on the top and bottom sides of the perimeter road where the centre inner road joins it (x = 0), so the car can enter them from below as well as along the road.
- Running Godot touches many `.import` files in the working tree (line-ending only; `git diff` shows no content change). They were left uncommitted.

### Board review

Approved by the board on 2026-10-10 on QA's pass. The layout can be adjusted after playing it. The fitted challenges still need the drivability check (T-021's tool).
