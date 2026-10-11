---
id: T-097
title: Take the challenges out of the MVP map (no arrows, the boulders stay), and add meteor boulders
status: in-qa
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/game-loop-architecture.md, docs/enemies.md, tasks/T-096-rework-map-everything-x3.md, tasks/T-035-runtime-meteor-challenges.md, tasks/T-037-likes-and-levels.md, game/README.md]
files_expected_to_change: [the map's scripts and data, game/tools/build_mvp_map.py, tests, docs/level-design.md, game/README.md]
model: opus
qa_rounds: 0
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

The board has left challenges out of the MVP (Level design, Decisions, 2026-10-11) and might bring them back later.

1. **No challenges on the MVP map:** no challenge arrows are drawn and no challenges are tracked, so the map never sends `challenge_completed` and the run never sends `score`. Every obstacle pattern copy and its boulders stays exactly where it is, as plain obstacles the car bounces off.
2. **Keep the challenge code,** data and tests (the fitted designs, the completion rule, the arrows, the meteor challenge functions, the drivability check), unused, so challenges can come back. Say in `game/README.md` how to turn them back on.
3. **Meteor boulders, for the kaiju's attack (T-046):** the kaiju's meteors now leave plain boulders where they land (Enemies, Decisions). Add a map function that places one boulder at a position during a run, the same size, look and collision as the map's boulders, and a placement check that rejects a spot overlapping a building, another boulder or the map's edge. A new run builds a new map, so placed boulders go with the old one.
4. Update `docs/level-design.md` Content ("MVP map") and `game/README.md` to match. Don't change Summary, Decisions or Open questions.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test on the map from a run started from the main menu shows it has no challenges and draws no challenge arrows (QA: pass / fail)
- [ ] A test shows every pattern copy's boulders are still on the map, at the same positions as before this task (QA: pass / fail)
- [ ] A test drives through where the challenges were and shows the run never sends `score`; drifting still gives likes (QA: pass / fail)
- [ ] A test shows the new function places a boulder the car bounces off, and the placement check rejects a building, another boulder and the map's edge (QA: pass / fail)
- [ ] A screenshot of a run started from the main menu shows boulders and no arrows (QA: pass / fail)
- [ ] `game/README.md` says how to turn challenges back on and documents the new function. `docs/level-design.md` Content matches, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

**Level/Challenge Design Agent, 2026-10-11.** Built on branch `task/T-097-mvp-map-without-challenges`.

**Challenges off, kept for later.** One switch: `const CHALLENGES_ENABLED := false` in `game/scripts/level/mvp_map.gd`, read into each map's `challenges_enabled` (set before it enters the tree). When off, the map builds no trackers and no arrows, `challenge_ids()` is empty and `get_challenge()` returns {}, so it never sends `challenge_completed` and the run never sends `score`. The run (`run.gd`) has its own `challenges_enabled`, defaulting to the constant, which it hands to every map it builds. Nothing else changed: the pattern copies, their boulder bodies and the layout data are as before, and the challenge code (tracker, arrows, meteor challenge functions, the run's signal wiring, the popup, the drivability check) and the 18 challenges and 3 fitted designs in `mvp_map.json` are kept. **To turn challenges back on:** set `CHALLENGES_ENABLED` to true (written in `game/README.md`, "MVP map"); then the tests that check they are off need updating.

**Meteor boulders** (for T-046): `can_place_meteor_boulder(centre) -> bool` (wholly inside the map, no overlap with a building or any boulder already there; touching allowed) and `add_meteor_boulder(centre) -> StaticBody2D` (a 3-unit circle, size read from the map's own boulders, on a `StaticBody2D` on layer 1 under the map's `Physics`, drawn with the other boulders; also in `meteor_boulder_bodies`; listed in `meteor_boulders` and `all_boulders()`). A new run builds a new map, so they go with it.

**Tests.** New `game/tests/unit/test_mvp_map_no_challenges.gd` (9 tests): a run started from the main menu has no challenges, no trackers and no `ChallengeArrow` anywhere in the game (and a new run neither); the 60 copies' 96 boulder shapes are where the layout data puts them and identical to a map with challenges on; the run's car put along every one of the 18 former challenge arrows sends no `challenge_completed` and no `score`, while the same drive on a run with challenges on completes all 18; drifting in a run from the menu gives likes; the placement check rejects a building (inside and overlapping an edge), a map boulder, a meteor boulder and the map's edges, and accepts free and just-touching spots; a placed boulder matches the map's boulders (layer, mask, circle, size); the real car driving into one in a run hits it (`hit_obstacle` reports its body), bounces back and never passes through; a new run leaves meteor boulders behind. Kept tests switched challenges on in their `make_map()` (`test_mvp_map.gd`, `test_meteor_challenges.gd`); `test_run_scene.gd` now checks no challenges, with a new test that switching them on brings back 18 that reset on a new run; `test_run_likes.gd`, `test_challenge_popup.gd` and the challenge popup fixture take the challenge id from the layout data instead of `challenge_ids()`; the meteor challenge fixture switches challenges on.

- `bash game/tools/run_tests.sh`: TESTS PASSED, 294/294 (30 scripts). The one ERROR line is the expected one from `test_unknown_design_is_refused`.
- `python -m unittest discover -s game/tools -p "test_*.py"`: OK (67). `python -m unittest discover -s tools -p "test_*.py"`: OK (75).
- `build_mvp_map.py` reran with identical output (only a docstring note added); the layout data is unchanged.

**Checked by eye:** new fixture `game/tests/fixtures/map_from_menu_demo.tscn` opens `game.tscn`, presses Start, puts the car on the road at 4, -46 (by the crossing at 0, -54 where challenge-6 was), zooms to 20 and places a meteor boulder at -4, -47. It printed `challenges=0 arrows=0 meteor boulders=1`, and the screenshot (`bash game/tools/screenshot.sh res://tests/fixtures/map_from_menu_demo.tscn screenshots/map_from_menu.png 30`) shows the HUD at 8:00, the car, the crossing boulder, the meteor boulder, other copies' boulders and no arrows. Saved as `docs/level-design/meteor-boulder-run.png`. The map overviews (`docs/level-design/mvp-map.png`, `mvp-map-iso.png`) were retaken: boulders, no arrows. The meteor challenge pictures are kept as they were (that fixture switches challenges on).

No PixelLab call. Godot's `.import` line-ending changes and the build script's line-ending-only rewrites were not committed.

**Documents affected:**
- `docs/level-design.md`: Content only: "MVP map" (no challenges in the MVP, the parts about challenges marked as for when they come back, no blue arrows in the colours), a new "Meteor boulders" section with the run screenshot, and "Meteor challenges" marked off in the MVP, kept for later. Summary, Decisions and Open questions unchanged.
- `game/README.md`: "MVP map" (challenges off, what is kept, how to turn them back on, the meteor boulder functions, the new tests and fixture), "Collision layers" (`meteor_boulder_bodies`), "The run" (new runs drop meteor boulders; no challenge signals fire while off).

Also updated my working notes, `agent-notes/level-challenge.md`. The long GDD will be stale for level-design.md; regenerating it is the Project Lead's job.
