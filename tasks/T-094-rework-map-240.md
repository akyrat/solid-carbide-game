---
id: T-094
title: Rework (T-019): the MVP map, three times bigger (240 by 240)
status: done
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-019-build-mvp-map.md, tasks/T-035-runtime-meteor-challenges.md, tasks/T-087-fix-map-generator-reads-driven-files.md, game/README.md]
files_expected_to_change: [game/tools/build_mvp_map.py and its tests, game/data/level/mvp_map.json, the map's code and tests, docs/level-design.md, docs/level-design/ (screenshots), game/README.md]
model: opus
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

After Playtest 1 the board found the map far too small (2026-10-11). Level design, Decisions now says: the MVP map is **240 by 240 units**, with the same 8-unit perimeter road, 10 by 10 blocks and 8-unit roads, just many more blocks (about 13 in each direction), and a bigger open gravel centre (about three times as wide). Boulders, the obstacle patterns, the challenges and their fitted versions stay exactly the same size.

Rebuild the map with `game/tools/build_mvp_map.py`:
- The grid: fit the block count and the centre square to 240 by 240 (say what you chose).
- Pattern copies: place more of them across the bigger city (how many and where is your call, as before; list them), and keep 30% of them as preset challenges, the same every run.
- Everything that uses the map keeps working: the run (the car still starts in the centre), the meteor challenges (T-035's placement check and designs), the see-through work to come, and the map overview scenes (fit the whole map).
- Update the map screenshots in `docs/level-design/` and the "MVP map" part of Content in `docs/level-design.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test reading the layout data shows the map is 240 by 240 units, with the 8-unit perimeter road, 10 by 10 blocks and 8-unit roads, and an open gravel centre with no blocks (QA: pass)
- [x] A test shows every boulder is 3 units across and every pattern copy matches its fitted version, unchanged from T-019 (QA: pass)
- [x] A test shows the number of preset challenges is 30% of the pattern copies, rounded as before, and the same on every run (QA: pass)
- [x] A test shows no challenge corridor or boulder overlaps a building or lies outside the map (QA: pass)
- [x] The run, the screen flow and the meteor challenges' tests all pass on the bigger map, and a screenshot of the run shows the car in the centre (QA: pass)
- [x] New map screenshots (flat and isometric) are in `docs/level-design/`, and `docs/level-design.md` describes the bigger map in Content without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

**Level/Challenge Design Agent, 2026-10-11.** Built on branch `task/T-094-rework-map-240`.

**For the Project Lead and the board first: the map is 242 by 242, not 240.** With the 8-unit perimeter road, 10 by 10 blocks and 8-unit roads all kept (Decisions, and this task's rule that only the city grows), a grid of N blocks is 18 N + 8 units across (N = 4 gave 80). 240 is not reachable: 12 blocks give 224 and 13 give 242. I chose 13 blocks, 242 by 242, so every road, block, boulder and fitted pattern stays exactly the same size. The other ways to reach exactly 240 each break another Decision: a 7-unit perimeter road (the Two Boulders copies no longer fit on it), a 9-unit block row, or two narrower inner roads. Level design, Decisions still says 240; if 242 is accepted, Decisions needs the Project Lead's edit. This means criterion 1's "240 by 240" is met as 242. Changing the size is three constants at the top of `game/tools/build_mvp_map.py`.

**What changed**

- `game/tools/build_mvp_map.py`: `MAP_SIZE = 242`, `BLOCKS_PER_SIDE = 13`, `GRAVEL = 82`. The fixed copy and challenge lists are replaced by rules, `make_copies()` and `make_challenges()` (below). The fitting, the fitted versions and `challenge_designs` are unchanged; rerunning it changes the fitted files only in line endings, so those were not committed.
- `game/data/level/mvp_map.json`: regenerated, with 144 buildings, a 242 x 242 ground grid, 80 copies and 24 challenges.
- The map's code (`mvp_map.gd`, `map_overview.gd`) already read everything from the data and needed no change. The overview scenes fit the whole bigger map, and the run still starts the car at 0, 0, in the gravel.
- Tests updated for the new layout: `game/tools/test_build_mvp_map.py`, `game/tests/unit/test_mvp_map.gd`, `game/tests/unit/test_meteor_challenges.gd` (placement spots moved to the new grid), `game/tests/unit/run/test_run_scene.gd` (the challenge count, 4 to 24) and the screenshot fixture `game/tests/fixtures/meteor_challenge_demo.gd`. The fixture now shows the meteor challenge in the gravel corner beside preset challenge-8 (a Two Boulders at -45, -45), because challenge-1 is no longer next to the gravel.
- Screenshots replaced in `docs/level-design/`: `mvp-map.png`, `mvp-map-iso.png`, `meteor-challenge.png` and `meteor-challenge-iso.png`.

**The grid and the centre:** 13 by 13 blocks starting at -113, then every 18 units. The gravel centre is the middle 5 by 5 blocks and the roads between them: -41 to 41, 82 by 82 units, against 28 before, so about 2.9 times as wide. That leaves 144 blocks. The road crossings inside the perimeter road are at -99, -81, ..., 99 (12 per axis, numbered 0 to 11), and the perimeter road's centre line is at plus or minus 117.

**Pattern copies (my call, as before):** 80 in all, 32 Single Boulder and 48 Two Boulders.
- A Single Boulder on every crossing whose two numbers are both even.
- A Two Boulders on every crossing whose two numbers are both odd, running along y or x in alternate pairs.
- The other crossings are empty, so the next copy along a road is 36 units away.
- On each side of the perimeter road, a Two Boulders running along it at crossings 1, 4, 7 and 10.
- None in the gravel.

The full list, with centres and rotations, is in `docs/level-design.md`, Content, "MVP map". A Python test checks that every copy, with any of its pattern's arrows, stays clear of buildings, the edge and every other copy, so the challenge choice can change without moving anything.

**Challenges:** 30% of 80 = 24, using the same rounding as before (floor(n x 0.3 + 0.5), at least 1). The split is 10 Single Boulder (5 with arrow 1, 5 with arrow 2) and 14 Two Boulders. They are picked evenly through the copies in reading order (copy number (k + 0.5) x 80 / 24), which spreads them over the whole map, and the Single Boulder ones alternate arrow 1 and arrow 2. They are fixed in the data, the same every run, and listed in Level design.

**Checked:** the screen flow test (`test_screen_flow.gd`, main menu to run and back) and the HUD timer test pass on the bigger map. A screenshot of `res://scenes/run/run.tscn` (30 frames) shows the car at the centre on the gravel with the HUD timer at 8:00. Viewed the new overview screenshots: the 13 x 13 grid, the 82-unit gravel centre, the 80 copies and 24 blue arrows.

**Tests (run before handing over):**
- `bash game/tools/run_tests.sh`: TESTS PASSED, 223/223 (23 scripts).
- `python -m unittest discover -s game/tools -p "test_*.py"`: OK (66).
- `python -m unittest discover -s tools -p "test_*.py"`: OK (75).

No PixelLab call. The `.import` line-ending changes Godot made were not committed.

**Drivability:** the 24 challenges are copies of the 3 fitted versions, which still need T-021's check, as before.

**Documents affected:**
- `docs/level-design.md`: Content, "MVP map" rewritten for the bigger map, plus one image caption and the drivability line in "Meteor challenges". Summary, Decisions and Open questions are unchanged.
- `game/README.md`: the "MVP map" section (size, ground grid, how to change copies and challenges).

Also updated my working notes, `agent-notes/level-challenge.md`. `python tools/generate_long_gdd.py --check` reports the long GDD stale for level-design.md, as expected; regenerating it is the Project Lead's job.

### QA round 1

**QA/Integration Agent, 2026-10-11.** Checked on branch `task/T-094-rework-map-240` in `C:\solid-carbide-worktrees\T-094`. Criterion 1's "240 by 240" read as 242 by 242, per the Project Lead's ruling (master's Level design, Decisions now says 242). All 7 criteria pass.

1. **Pass.** Own script over `mvp_map.json`: map and ground grid 242 x 242; every cell less than 8 from the edge is road; 144 buildings, all 10 x 10, on 13 columns and rows starting at -113, 18 apart (8-unit roads), the first and last right against the perimeter road; gravel -41 to 41 (82 x 82) with no building in it (169 - 25 = 144); every ground cell matches buildings, gravel and roads (0 mismatches). Branch tests `test_map_is_242_by_242_centred_on_the_origin`, `test_blocks_are_the_13_by_13_grid_minus_the_centre`, `test_perimeter_road_is_8_wide_and_roads_are_8_wide` and the Python `test_map_is_242_by_242_with_8_unit_roads_and_10_unit_blocks` pass.
2. **Pass.** All 128 boulders are 3 units. Each of the 80 copies' boulders, and each of the 24 challenges' arrow points, equal its fitted version rotated and placed (own check, tolerance 0.001); the 3 `challenge_designs` equal the fitted files. `git diff master...HEAD` shows no change to the sketches or fitted versions in `docs/level-design/single-boulder/` and `two-boulders/`, and the worktree is clean there after running the Python tests.
3. **Pass.** 24 challenges = floor(80 x 0.3 + 0.5), on 24 distinct copies, matching the copies flagged as challenges (14 Two Boulders, 5 Single Boulder arrow 1, 5 arrow 2). Same every run: `build()` called twice gives identical output, equal byte for byte to the file on disk; the GUT test `test_challenges_are_the_same_every_run` passes.
4. **Pass.** Own check (corridor = centre line sampled every 0.1 unit, 1.5 either side): smallest gap from any challenge corridor to a building or the map edge is 0.25 units; for every copy with any of its pattern's arrows also 0.25; boulders at least 2.5 units clear of buildings and the edge; no boulders overlap (closest centres 7 units apart); no copy in the gravel.
5. **Pass.** In the full suite: `test_screen_flow.gd` 16/16, `test_run_scene.gd` 4/4, `test_hud_timer.gd` 5/5, `test_meteor_challenges.gd` 12/12, `test_mvp_map.gd` 19/19. I launched the main scene (`scenes/game/game.tscn`) through a temporary fixture (not committed, deleted after) that pressed the menu's Start button after 10 frames: the run came up with the car at 0, 0 units, centred on screen on the gravel, and the HUD timer showing 8:00. Whole-map overview screenshots (flat and isometric) show the 13 x 13 grid, the gravel centre and the blue challenge arrows, and match the committed ones. (The overview prints Godot's "Camera2D overridden to physics process mode" warning; `map_overview.gd` is unchanged since T-019, so not new.)
6. **Pass.** `mvp-map.png`, `mvp-map-iso.png`, `meteor-challenge.png` and `meteor-challenge-iso.png` replaced (1152 x 648), showing the bigger map and the meteor challenge beside preset challenge-8. `git diff master...HEAD -- docs/level-design.md` touches only Content ("MVP map" and one caption plus the drivability line in "Meteor challenges"); Summary, Decisions and Open questions are unchanged by this branch. `git merge-tree` reports a clean merge with master's own Decisions edit. Note for the Project Lead: Content's "Size" paragraph says 242 is "the nearest size to the 240 in Decisions"; once merged, Decisions says 242, so that wording could be tidied.
7. **Pass.** `bash game/tools/run_tests.sh`: TESTS PASSED, 223/223 in 23 scripts (the 1 warning is GUT ignoring the inner class TestRoom, as before). `python -m unittest discover -s game/tools -p "test_*.py"`: OK (66). `python -m unittest discover -s tools -p "test_*.py"`: OK (75).

No command was blocked. Godot's `.import` line-ending changes in the worktree were left uncommitted.

### Board review

Merged on QA's pass, 2026-10-11 (the map is 242 by 242, recorded in Level design). The board checks it in its combined playtest.
