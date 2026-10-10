---
id: T-035
title: Challenges created during a run, for the kaiju's meteors
status: in-qa
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

- [ ] A test creates each of the 3 challenge designs during a run at a free spot and shows its boulders and green arrow corridor exist at the given position and rotation (QA: pass / fail)
- [ ] A test drives a stand-in body along a created challenge per the completion rule and shows the meteor-challenge signal fires once, with the right id. The arrow disappears and the boulders remain (QA: pass / fail)
- [ ] A test completes a preset (blue) challenge and shows the meteor-challenge signal does not fire (QA: pass / fail)
- [ ] A test shows the placement check rejects a spot overlapping a building, another boulder or the map edge, and accepts a free one (QA: pass / fail)
- [ ] A test creates two challenges at once and completes them one at a time, each signalling separately (QA: pass / fail)
- [ ] A screenshot shows a created challenge with its green arrow next to a preset challenge with its blue arrow (QA: pass / fail)
- [ ] `game/README.md` documents the functions and the signal for the Enemy Behavior Agent. `docs/level-design.md` describes them in Content without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

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
