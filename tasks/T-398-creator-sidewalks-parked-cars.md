---
id: T-398
title: Level creator: sidewalks painted with automatic curbs, and parked and broken cars as obstacles at four facings (placeholders)
status: open
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-396, T-393, T-394]
documents_affected: [docs/level-design.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/data/level/creator_texts.json]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/data/level/, game/tools/check_level.py, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
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

Build the pieces with code-drawn placeholders in the city's palette; T-399 swaps the final art in. It starts after T-393 (object heights) and T-394 (chained pairs) are merged, since it touches the same creator code.
1. **Sidewalk** (Ground): painted with a brush like roads. Wherever a sidewalk tile meets a road the editor adds the curb edge itself (straights, outer and inner corners), as roads join themselves. In the run the car drives up over the curb: the sidewalk is a step under the 0.1-unit curb rule (Drifting, Decisions, "Curbs"), not a wall. Enemies cross it as they do today's ground.
2. **Parked car** and **broken car** (Obstacles): a few looks each (chosen by key, like other pieces' looks), each at four facings, top right, bottom right, bottom left, top left (turned by key). Solid obstacles like boulders: the car crashes into them, they cut the combo, and they can be paired (and chained) for thread the needle. They respect what they stand on (T-393's fix).
3. Names from T-396 into `creator_texts.json`. Saved levels keep the new pieces; levels saved before open unchanged; `check_level.py` accepts them. The game's own map is unchanged.

The board's review: paint sidewalks along roads and place parked and broken cars at each facing in the creator, then press Play and drive over the curbs and into the cars.

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", 2026-10-30). The board: "add sidewalk assets that fit with the road ... and the buildings and other assets that we have, and make sure that it works well, consider the curb as well. And I also want a few different car assets that are just sitting parked, just normal, boring kind of cars. Generate some broken ones as well. And make it so that they sit at four rotations: top right, bottom right, bottom left, top left. This is for the level creator." The board's answers: parked cars are solid obstacles like boulders (crash into them, pairable for thread the needle); sidewalks are painted like roads with the curb added automatically where they meet a road, and the car drives up over the curb; PixelLab up to 50 generations for the whole set (T-397 and T-399 together), sample first. The tickets: T-396 (piece names), T-397 (art sample), T-398 (the pieces in the creator and the run, placeholders), T-399 (the full art set, swapped in). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The sidewalk paints like a road and the curb appears by itself on every edge where it meets a road, straights and corners (tests). (QA: pass / fail)
- [ ] In a run the car drives up over the curb onto the sidewalk and back down, with no crash or bump to a stop (test). (QA: pass / fail)
- [ ] Parked and broken cars place at the four facings and each look, crash the car, cut the combo, and can be paired for thread the needle (tests). (QA: pass / fail)
- [ ] The new pieces save and reopen, an earlier level opens unchanged, check_level.py accepts them, and the game's own map builds as before (tests). (QA: pass / fail)
- [ ] The side panel shows T-396's names, read from `creator_texts.json`. (QA: pass / fail)
- [ ] Level design, Content and game/docs/level/ describe the pieces and their controls. (QA: pass / fail)
- [ ] Screenshots of sidewalks with curbs and cars at each facing in the editor, and a GIF of driving over a curb in a run, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
