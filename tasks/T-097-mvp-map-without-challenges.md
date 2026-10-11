---
id: T-097
title: Take the challenges out of the MVP map (no arrows, the boulders stay), and add meteor boulders
status: open
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

Written by the agent when it finishes.
