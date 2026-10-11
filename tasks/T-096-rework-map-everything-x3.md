---
id: T-096
title: Rework (T-094): the MVP map with everything three times bigger (240 by 240)
status: open
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-094]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-094-rework-map-240.md, tasks/T-019-build-mvp-map.md, tasks/T-035-runtime-meteor-challenges.md, game/README.md]
files_expected_to_change: [game/tools/build_mvp_map.py and its tests, game/data/level/mvp_map.json, the fitted versions next to the sketches, the map's tests, docs/level-design.md, docs/level-design/ (screenshots), game/README.md]
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

The board's feedback after the combined playtest (2026-10-11): the city should be bigger in every part so the car drives through the roads easily, not just have more small blocks. Level design, Decisions now says: **240 by 240 units**, the first plan's layout with everything three times bigger: a **24-unit** perimeter road, a **4 by 4** grid of **30 by 30** blocks, **24-unit** roads, and an **84 by 84** gravel centre. The boulders (3 units) and the challenges (3-unit corridor, the drawn car) stay sized to the car.

Rebuild the map with `game/tools/build_mvp_map.py`:
- The layout above (the size constants at the top of the script).
- **Re-fit the sketches to the wider roads.** The fitted versions were squeezed to fit 8-unit roads (the figure-eight most of all); on 24-unit roads they can follow the board's sketches more closely. Keep the rules: same boulders, same direction around each one, same overall path, corridors and boulders inside the road and clear of buildings.
- Place the pattern copies on the new roads and crossings (how many and where is your call; list them), with 30% of them as preset challenges, the same every run.
- Everything that uses the map keeps working: the run from the main menu (the car starts in the centre), the HUD timer, the trick popups, the meteor challenges (their designs come from the fitted versions), the overview scenes.
- Update the screenshots in `docs/level-design/` and the "MVP map" part of Content in `docs/level-design.md` (which still describes the 242 map).

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test reading the layout data shows the map is 240 by 240 units, with the 24-unit perimeter road, the 4 by 4 grid of 30 by 30 blocks, 24-unit roads, and the 84 by 84 gravel centre with no blocks (QA: pass / fail)
- [ ] A test shows every boulder is 3 units across, and each fitted version keeps its sketch's number of boulders and the arrow's direction around each one (QA: pass / fail)
- [ ] A test shows 30% of the pattern copies are preset challenges, rounded as before, the same every run, and no corridor or boulder overlaps a building or leaves the map (QA: pass / fail)
- [ ] The run, screen flow, HUD timer, trick popup and meteor challenge tests all pass, and a screenshot of a run started from the main menu shows the car in the centre (QA: pass / fail)
- [ ] New map screenshots (flat and isometric) are in `docs/level-design/`, and `docs/level-design.md` describes the new map in Content without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
