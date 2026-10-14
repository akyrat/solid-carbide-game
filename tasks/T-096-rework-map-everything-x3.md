---
id: T-096
title: Rework (T-094): the MVP map with everything three times bigger (240 by 240)
status: done
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-094]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-094-rework-map-240.md, tasks/T-019-build-mvp-map.md, tasks/T-035-runtime-meteor-challenges.md, game/README.md]
files_expected_to_change: [game/tools/build_mvp_map.py and its tests, game/data/level/mvp_map.json, the fitted versions next to the sketches, the map's tests, docs/level-design.md, docs/level-design/ (screenshots), game/README.md]
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

The board's feedback after the combined playtest (2026-10-11): the city should be bigger in every part so the car drives through the roads easily, not just have more small blocks. Level design, Decisions now says: **240 by 240 units**, the first plan's layout with everything three times bigger: a **24-unit** perimeter road, a **4 by 4** grid of **30 by 30** blocks, **24-unit** roads, and an **84 by 84** gravel centre. The boulders (3 units) and the challenges (3-unit corridor, the drawn car) stay sized to the car.

Rebuild the map with `game/tools/build_mvp_map.py`:
- The layout above (the size constants at the top of the script).
- **Re-fit the sketches to the wider roads.** The fitted versions were squeezed to fit 8-unit roads (the figure-eight most of all); on 24-unit roads they can follow the board's sketches more closely. Keep the rules: same boulders, same direction around each one, same overall path, corridors and boulders inside the road and clear of buildings.
- Place the pattern copies on the new roads and crossings (how many and where is your call; list them), with 30% of them as preset challenges, the same every run.
- Everything that uses the map keeps working: the run from the main menu (the car starts in the centre), the HUD timer, the trick popups, the meteor challenges (their designs come from the fitted versions), the overview scenes.
- Update the screenshots in `docs/level-design/` and the "MVP map" part of Content in `docs/level-design.md` (which still describes the 242 map).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test reading the layout data shows the map is 240 by 240 units, with the 24-unit perimeter road, the 4 by 4 grid of 30 by 30 blocks, 24-unit roads, and the 84 by 84 gravel centre with no blocks (QA: pass)
- [x] A test shows every boulder is 3 units across, and each fitted version keeps its sketch's number of boulders and the arrow's direction around each one (QA: pass)
- [x] A test shows 30% of the pattern copies are preset challenges, rounded as before, the same every run, and no corridor or boulder overlaps a building or leaves the map (QA: pass)
- [x] The run, screen flow, HUD timer, trick popup and meteor challenge tests all pass, and a screenshot of a run started from the main menu shows the car in the centre (QA: pass)
- [x] New map screenshots (flat and isometric) are in `docs/level-design/`, and `docs/level-design.md` describes the new map in Content without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

**Level/Challenge Design Agent, 2026-10-11.** Built on branch `task/T-096-rework-map-everything-x3`.

**The layout** (`game/tools/build_mvp_map.py`: `MAP_SIZE = 240`, `PERIMETER_ROAD = 24`, `BLOCK = 30`, `ROAD = 24`, `BLOCKS_PER_SIDE = 4`, `GRAVEL = 84`): 24 + 4 x 30 + 3 x 24 + 24 = 240, exactly as Level design, Decisions says. Blocks start at -96, -42, 12 and 66 on each axis; the gravel is -42 to 42 (the middle 2 by 2 blocks and the road between them), leaving 12 blocks. Road centre lines are at -108 and 108 (perimeter road) and -54, 0, 54 (inner roads).

**The fitted versions:** the fitting rule is unchanged (centre line at least 2 units from each boulder's centre, corridor at least 0.25 units from every building), but its places are now a crossing of two 24-unit roads and a straight 24-unit road (the context reads `ROAD`). On those, every sketch already fits, so no arrow point is moved: each fitted version is the board's sketch exactly, only shifted so its boulders sit on the crossing's centre (Single Boulder) or the road's centre line (Two Boulders, 7 units apart, shifted 0.5 units). Same boulders, same directions and the same turns as the sketches: Single Boulder arrow 1 clockwise 389 degrees (was 387), arrow 2 counter-clockwise 431 (was 400), Two Boulders clockwise 422 then counter-clockwise 332 (was 408 and 339). The figure-eight is no longer squeezed (its loops are about 8 units wide again, not 4.5). The sketches themselves are unchanged. The fitted pictures now show a 32-unit square, so the edges of the buildings are visible around the wider road.

**Pattern copies (my call):** 60, 24 Single Boulder and 36 Two Boulders, none in the gravel.
- A Single Boulder wherever two road centre lines meet: the 8 inner crossings, the 12 junctions with the perimeter road and its 4 corners.
- A Two Boulders on the middle of every stretch of road between those (the middle of each block side), turned to run along the road.
- Neighbouring copies are 27 units apart along a road. Every copy, with any of its pattern's arrows, stays clear of buildings, the edge and the other copies (Python test), so the challenge choice can change without moving anything.

**Challenges:** 30% of 60 = 18 (same rounding, floor(n x 0.3 + 0.5), at least 1), the same every run: 12 Two Boulders, 6 Single Boulder (3 arrow 1, 3 arrow 2), picked evenly through the copies in reading order as before. Full list with centres and rotations: `docs/level-design.md`, Content, "MVP map".

**What changed**
- `game/tools/build_mvp_map.py`: the constants above, `make_copies()` rewritten for the new roads (with `road_lines()` and `block_middles()`), the fitting contexts sized from `ROAD`.
- Regenerated: `game/data/level/mvp_map.json` and the 3 fitted versions (`docs/level-design/*/arrow-*.fitted.json` and `.svg`).
- Tests: `game/tools/test_build_mvp_map.py` (240 layout, 60 copies on road centre lines, 18 challenges, and a new test that each fitted version is its sketch moved with the same turns), `game/tests/unit/test_mvp_map.gd` (the 4 by 4 grid, 24-unit roads, 84 gravel), `game/tests/unit/test_meteor_challenges.gd` (placement spots moved to the new roads; one now lays a Two Boulders across the 24-unit perimeter road), `game/tests/unit/run/test_run_scene.gd` (18 challenges).
- The meteor screenshot fixture (`game/tests/fixtures/meteor_challenge_demo.gd`) now shows preset challenge-6 (a Single Boulder on the crossing at 0, -54) with the meteor challenge in the gravel just below it.
- The map's code (`mvp_map.gd`, `map_overview.gd`, the run) reads everything from the data and needed no change.
- Screenshots replaced in `docs/level-design/`: `mvp-map.png`, `mvp-map-iso.png`, `meteor-challenge.png`, `meteor-challenge-iso.png`.

**Checked by eye:** a run started from the main menu (a temporary fixture opening `scenes/game/game.tscn` and pressing Start, deleted afterwards): the car at 0, 0 units, centred on the gravel, HUD timer at 8:00. The overview screenshots show the 4 by 4 blocks, wide roads, the gravel centre, 60 copies and 18 blue arrows.

**Tests (run before handing over):**
- `bash game/tools/run_tests.sh`: TESTS PASSED, 233/233 (24 scripts), including screen flow, run scene, HUD timer, trick popups, meteor challenges and the map.
- `python -m unittest discover -s game/tools -p "test_*.py"`: OK (67).
- `python -m unittest discover -s tools -p "test_*.py"`: OK (75).

No PixelLab call. Godot's `.import` line-ending changes were not committed. No pause-screen (T-095) file touched.

**Drivability:** the fitted versions are now the sketches unchanged, which T-021's check found drivable; the fitted versions themselves still have not been run through that check.

**Documents affected:**
- `docs/level-design.md`: Content, "MVP map" rewritten for the 240 map, plus the meteor screenshot's caption and the drivability line. Summary, Decisions and Open questions unchanged.
- `game/README.md`: the "MVP map" section (size, ground grid, the size constants).

Also updated my working notes, `agent-notes/level-challenge.md`. The long GDD will be stale for level-design.md; regenerating it is the Project Lead's job.

### QA round 1

**QA/Integration Agent, 2026-10-11.** Checked in `C:\solid-carbide-worktrees\T-096` on `task/T-096-rework-map-everything-x3` (head `aed87de`). All six criteria pass.

1. **Layout: pass.** My own script (outside the repo) read `game/data/level/mvp_map.json` and compared every one of the 240 by 240 ground cells with the layout built from Level design, Decisions: 0 mismatches. Map 240 by 240 (-120 to 120), a 24-unit perimeter road, a 4 by 4 grid of 30 by 30 blocks starting at -96, -42, 12 and 66, 24-unit roads between them, the gravel -42 to 42 (84 by 84) with no building in it, 12 buildings left. The branch's own tests (`test_mvp_map.gd`, `test_build_mvp_map.py`) also pass.
2. **Boulders and fitted versions: pass.** All 96 map boulders and the design boulders are 3 units across. Each fitted version keeps its sketch's number of boulders (1, 1, 2). I worked out each arrow's turn around each boulder myself from the points: Single Boulder arrow 1 clockwise 389 degrees, arrow 2 counter-clockwise 431, Two Boulders clockwise 422 then counter-clockwise 332, the same in the sketch and the fitted version. Each fitted version is its sketch moved, with no other change (points and boulders shifted by (-2.5, 4.5), (-2.5, 4.5) and (-0.5, 0)). The `challenge_designs` in the map data match the fitted files. `git diff master...HEAD` shows no change to the board's sketches (`arrow-N.json` and `.svg`).
3. **30% challenges, no overlaps: pass.** 18 of 60 copies are challenges (floor(60 x 0.3 + 0.5) = 18), each linked to its copy. I ran `build_mvp_map.py` twice and the generated files did not change (`git status` clean), so the choice is the same every run. Every challenge corridor (3 units wide, checked along its centre line) is at least 6.7 units clear of every building and inside the map. Every boulder is clear of buildings, inside the map and outside the gravel. No two challenge corridors overlap.
4. **Run, flow, timer, popups, meteors, run from the menu: pass.** In the full GUT run, `test_screen_flow` passed 19/19, `test_run_scene` 4/4, `test_hud_timer` 5/5, `test_trick_popups` 6/6 and `test_meteor_challenges` 12/12. Its one ERROR line is the expected error from `test_unknown_design_is_refused`. To check by eye, I made a temporary fixture that opens `scenes/game/game.tscn` and presses Start, then deleted it. It printed the car at (0, 0), the camera at (0, 0), the timer at 479.8 seconds and the HUD visible. The screenshot shows the car in the middle of the gravel and the timer at 8:00. Overview screenshots (flat and iso) show the 4 by 4 blocks, the wide roads, the gravel centre, the copies and 18 blue arrows.
5. **Screenshots and Level design: pass.** `docs/level-design/mvp-map.png`, `mvp-map-iso.png`, `meteor-challenge.png` and `meteor-challenge-iso.png` are replaced, and they match my own overview screenshots. In `git diff master...HEAD -- docs/level-design.md` there are only two hunks, both inside Content ("MVP map" from line 71, and the meteor caption from line 197). Summary, Decisions and Open questions are unchanged. Content describes the 240 map, and no "242" remains outside the Decision that records it was replaced.
6. **Full test suites: pass.** `bash game/tools/run_tests.sh`: TESTS PASSED, 233/233 across 24 scripts. Its one warning is the existing GUT note about the inner class `TestRoom`. `python -m unittest discover -s game/tools -p "test_*.py"`: OK (67). `python -m unittest discover -s tools -p "test_*.py"`: OK (75).

**Merge with master:** `git merge-tree --write-tree master HEAD` exits 0 with no conflicts (T-095's pause strip merges cleanly). The run screenshot comes from this branch, so it does not show the pause strip.

**Notes for the Project Lead:** the overview scenes print a Godot warning that was already there before this branch ("Camera2D overridden to physics process mode", `map_overview.gd:24`). It is harmless. The fitted versions themselves still have not been through T-021's drivability check, as the result notes say. No `.import` changes were committed.

### Board review

Merged on QA's pass, 2026-10-11, for the board's next playtest.
