---
id: T-094
title: Rework (T-019): the MVP map, three times bigger (240 by 240)
status: in-progress
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, tasks/T-019-build-mvp-map.md, tasks/T-035-runtime-meteor-challenges.md, tasks/T-087-fix-map-generator-reads-driven-files.md, game/README.md]
files_expected_to_change: [game/tools/build_mvp_map.py and its tests, game/data/level/mvp_map.json, the map's code and tests, docs/level-design.md, docs/level-design/ (screenshots), game/README.md]
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

After Playtest 1 the board found the map far too small (2026-10-11). Level design, Decisions now says: the MVP map is **240 by 240 units**, with the same 8-unit perimeter road, 10 by 10 blocks and 8-unit roads, just many more blocks (about 13 in each direction), and a bigger open gravel centre (about three times as wide). Boulders, the obstacle patterns, the challenges and their fitted versions stay exactly the same size.

Rebuild the map with `game/tools/build_mvp_map.py`:
- The grid: fit the block count and the centre square to 240 by 240 (say what you chose).
- Pattern copies: place more of them across the bigger city (how many and where is your call, as before; list them), and keep 30% of them as preset challenges, the same every run.
- Everything that uses the map keeps working: the run (the car still starts in the centre), the meteor challenges (T-035's placement check and designs), the see-through work to come, and the map overview scenes (fit the whole map).
- Update the map screenshots in `docs/level-design/` and the "MVP map" part of Content in `docs/level-design.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test reading the layout data shows the map is 240 by 240 units, with the 8-unit perimeter road, 10 by 10 blocks and 8-unit roads, and an open gravel centre with no blocks (QA: pass / fail)
- [ ] A test shows every boulder is 3 units across and every pattern copy matches its fitted version, unchanged from T-019 (QA: pass / fail)
- [ ] A test shows the number of preset challenges is 30% of the pattern copies, rounded as before, and the same on every run (QA: pass / fail)
- [ ] A test shows no challenge corridor or boulder overlaps a building or lies outside the map (QA: pass / fail)
- [ ] The run, the screen flow and the meteor challenges' tests all pass on the bigger map, and a screenshot of the run shows the car in the centre (QA: pass / fail)
- [ ] New map screenshots (flat and isometric) are in `docs/level-design/`, and `docs/level-design.md` describes the bigger map in Content without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
