---
id: T-035
title: Challenges created during a run, for the kaiju's meteors
status: needs-playtest
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/enemies.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-019-build-mvp-map.md, game/README.md]
files_expected_to_change: [the challenge code, their tests, docs/level-design.md, game/README.md]
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

**Blocked until T-019 is done:** it builds the preset challenges, their completion rule and the "challenge completed" signal.

When the kaiju attacks, its meteors land and become obstacles laid out as one of the challenge designs. A guide arrow then appears for the player to complete (Enemies, Decisions). Completing one of these challenges is the only way to make the kaiju vulnerable. Their arrows are green; the map's preset challenges are blue (Visual style, Decisions).

This task builds the challenge side, so the Enemy Behavior Agent's meteor attack (a later task) can call it:

1. **Create a challenge during a run:** a function that places one of the 3 MVP challenge designs at a given position and rotation. It uses T-019's fitted versions and 3-unit boulders, and draws the arrow corridor in **green**. It returns an id for the new challenge.
2. **Same completion rule** as the preset challenges (Level design, Decisions). On completion the arrow disappears and the boulders stay as plain obstacles.
3. **A separate signal for these challenges**, carrying the challenge's id, so the kaiju's shield logic can tell them apart from the map's preset (blue) challenges. Completing a preset challenge must not send it.
4. **Placement check:** a function that says whether a design fits at a position: no overlap with buildings, other boulders or the map edge. The meteor attack needs it to choose where meteors land.
5. **Several at once:** more than one of these challenges can exist at a time, each completed separately. How many the kaiju may have open at once is decided elsewhere (Enemies, Decisions).

The meteor sprites, the falling animation and the red warning circle are not part of this task. Use T-019's placeholder boulders, with a flat green band for the arrow.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test creates each of the 3 challenge designs during a run at a free spot and shows its boulders and green arrow corridor exist at the given position and rotation (QA: pass)
- [x] A test drives a stand-in body along a created challenge per the completion rule and shows the meteor-challenge signal fires once, with the right id. The arrow disappears and the boulders remain (QA: pass)
- [x] A test completes a preset (blue) challenge and shows the meteor-challenge signal does not fire (QA: pass)
- [x] A test shows the placement check rejects a spot overlapping a building, another boulder or the map edge, and accepts a free one (QA: pass)
- [x] A test creates two challenges at once and completes them one at a time, each signalling separately (QA: pass)
- [x] A screenshot shows a created challenge with its green arrow next to a preset challenge with its blue arrow (QA: pass)
- [x] `game/README.md` documents the functions and the signal for the Enemy Behavior Agent. `docs/level-design.md` describes them in Content without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

## Result notes

**Level/Challenge Design Agent, 2026-10-10.** Built on branch `task/T-035-runtime-meteor-challenges`.

**What was built**

- `game/scripts/level/mvp_map.gd` (the map node) gains the meteor challenges: `challenge_design_ids()`, `can_place_meteor_challenge(design_id, centre, angle)` (the placement check), `add_meteor_challenge(design_id, centre, angle)` (returns `"meteor-1"`, `"meteor-2"`, ...), the signal `meteor_challenge_completed(challenge_id)`, and `meteor_challenge_ids()`, `open_meteor_challenge_ids()`, `get_meteor_challenge(id)`, `is_meteor_challenge(id)`, plus helpers `place_design`, `get_challenge_design`, `all_boulders`. Positions in units from the map's centre, angle in radians clockwise on screen (like `Node2D.rotation`). Each created challenge gets its boulders as a static body on layer 1 (`meteor_boulder_bodies`), a green placeholder arrow (the T-019 arrow node with green colours), and a T-019 completion tracker, so the rule is exactly the preset one. Preset challenges behave as before: same signal (`challenge_completed`), `boulder_bodies` and `challenge_ids()` still list only the map's own.
- The 3 designs are T-019's fitted versions, stored unplaced in `game/data/level/mvp_map.json` under `challenge_designs` (boulders, arrow points, centre line), written by `game/tools/build_mvp_map.py`.
- Screenshot fixture `game/tests/fixtures/meteor_challenge_demo.tscn` (and `_iso`): a meteor challenge (Single Boulder arrow 1, in the gravel at -6, -6) beside preset challenge-1. Screenshots in `docs/level-design/meteor-challenge.png` and `meteor-challenge-iso.png`, taken with `bash game/tools/screenshot.sh res://tests/fixtures/meteor_challenge_demo.tscn screenshots/meteor_challenge.png 10`.

**Choices made**

1. A meteor challenge sends only `meteor_challenge_completed`, never `challenge_completed`, so whatever hooks into the preset signal (XP, the HUD) does not count it. Whether completing one also gives XP is not decided in the documents; if it should, the Game Loop side can listen to both signals.
2. The placement check covers the design's boulders and its whole 3-unit corridor (sampled every 0.1 units): neither may overlap a building, any boulder already on the map (preset or meteor, open or completed) or the map's edge. It does not check other challenges' corridors, so a meteor challenge may land on a preset arrow; say if that should be refused too.
3. `add_meteor_challenge` does not run the placement check itself (the meteor attack calls it first); it refuses only an unknown design.
4. Angle 0 is the design as fitted (Two Boulders running along y).

**Fixed on the way:** `build_mvp_map.py` and its tests failed on `master` since T-021 added `arrow-*.driven.json` files next to the sketches (the script read them as sketches). It now skips any generated file there. Re-running it changes no existing data apart from the new `challenge_designs`.

**Tests (run before handing over):** `bash game/tools/run_tests.sh`: TESTS PASSED, 112/112, including the new `tests/unit/test_meteor_challenges.gd` (12 tests: the designs are the fitted versions; each design created at a position and angle with its boulders, colliders and green corridor; unknown design refused; driving each design with a stand-in body fires the meteor signal once with its id, arrow hidden, boulders kept; leaving midway; completing all preset challenges does not fire it; placement accepts free spots and rejects buildings, boulders (preset and meteor) and the map edge; two at once completed separately; the screenshot fixture). `test_mvp_map.gd` unchanged and passing. `python -m unittest discover -s game/tools -p "test_*.py"`: OK (61). `python -m unittest discover -s tools -p "test_*.py"`: OK. No PixelLab call.

**Drivability:** the designs are T-019's fitted versions, unchanged; their drivability check with T-021's tool is still the one listed in Level design.

**Documents affected:** `docs/level-design.md` (new `### Meteor challenges` under Content, with both screenshots; Summary, Decisions and Open questions unchanged) and `game/README.md` ("Meteor challenges" table in "MVP map", tests line). Also this agent's working notes, `agent-notes/level-challenge.md`. The long GDD will be stale for level-design.md until the Project Lead regenerates it.

### QA round 1

**QA/Integration Agent, 2026-10-10.** Checked in `C:\solid-carbide-worktrees\T-035` on `task/T-035-runtime-meteor-challenges` (commit a65dc8b). All 8 criteria pass.

1. **Each design created at a position and rotation, green corridor: pass.** `test_each_design_is_created_at_the_given_position_and_angle` places all 3 designs at (2, -1), 30 degrees, and checks every boulder (data and its collider on layer 1, 3 units across) and every centre-line point against the design rotated and moved, plus a visible arrow with a green band and line, while the preset arrows stay blue. `test_the_three_designs_are_the_fitted_versions` checks the stored designs against T-019's fitted files. Code read: `add_meteor_challenge` reuses T-019's `ChallengeTracker` and `ChallengeArrow` with only the colours changed.
2. **Same completion rule, signal once with the id, arrow gone, boulders stay: pass.** `test_driving_a_meteor_challenge_sends_its_signal_once` drives a 1 x 1 unit stand-in along each design (45 degrees): `meteor_challenge_completed` fires once with the returned id, not `challenge_completed`; the arrow is hidden, the boulder body and drawing remain; driving it again sends nothing. `test_leaving_a_meteor_challenge_midway_does_not_complete_it` covers leaving the corridor.
3. **Preset completion does not send the meteor signal: pass.** `test_completing_a_preset_challenge_does_not_send_the_meteor_signal` completes every preset challenge with a meteor challenge open: `challenge_completed` fires once per preset, the meteor signal never, and the meteor arrow stays.
4. **Placement check: pass.** Separate tests reject buildings (on a block, across a road into blocks, at a block corner), boulders (a pattern copy's boulder, a corridor reaching one, a meteor challenge's boulder only after it is created) and the map edge (3 spots per design), and accept free spots (gravel centre at 4 angles, a straight road).
5. **Two at once, completed separately: pass.** `test_two_meteor_challenges_complete_separately` creates two, completes the second first, then the first: each signals once with its own id, the other stays open and visible.
6. **Screenshot: pass.** My own screenshots (`screenshots/qa_meteor_challenge.png` and `_iso.png`, git-ignored) from `res://tests/fixtures/meteor_challenge_demo.tscn` show the green meteor challenge in the gravel beside preset challenge-1 with its blue arrow, flat and isometric, matching the ones in `docs/level-design/`.
7. **Documentation: pass.** `game/README.md` has a "Meteor challenges" table covering every function, the signal, units and angle convention. `git diff master...HEAD -- docs/level-design.md` adds only `### Meteor challenges` under Content (with both screenshots); Summary, Decisions and Open questions are unchanged.
8. **Full suites: pass.** `bash game/tools/run_tests.sh`: TESTS PASSED, 112/112 (12 scripts). `python -m unittest discover -s tools -p "test_*.py"`: OK (72). `python -m unittest discover -s game/tools -p "test_*.py"`: OK (61). T-019's `tests/unit/test_mvp_map.gd`, `challenge_tracker.gd` and `challenge_arrow.gd` are unchanged on this branch (`git diff master...HEAD` empty for them) and pass.

**Extra checks (a temporary probe test, run and then deleted, not committed):** 3,000 random placements (any design, angle and position, including off the map): of the 303 accepted, an independent geometry check found no boulder overlapping a building, another boulder or the map edge, no corridor point inside a building or past the edge, and boulder spacing kept under rotation. Six meteor challenges placed at random spots and angles were open at once; completed in reverse order, each signalled once with its own id (driven twice each), `challenge_completed` never fired, and a physics point query found a layer-1 collider at every meteor boulder.

**For the Project Lead (not fails):**
- `game/tools/build_mvp_map.py` and its tests overlap with T-087, merged on `master` since this branch was made: both fix the same sketch-reading bug in different ways. To resolve at merge; the merged script must still write `challenge_designs`.
- Per the agent's choices 1 and 2: completing a meteor challenge sends no `challenge_completed` (so no XP through that hook), and the placement check lets a meteor challenge land on a preset challenge's arrow corridor. Neither is decided in the documents; worth the board's view before the kaiju's attack is built.
- The long GDD is stale for `docs/level-design.md` (expected).

