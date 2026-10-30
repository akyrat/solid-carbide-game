---
id: T-397
title: Art sample: one sidewalk tile with its curb and one parked car facing, for the board's review
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, docs/visual-style.md, docs/level-design.md, game/art/roads/, game/art/buildings/, game/art/boulders/, game/docs/level/level-creator-pieces.md]
files_expected_to_change: [art-archive/, game/docs/art/, docs/visual-style.md]
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

Sample first (docs/working-with-the-board.md, "Art and money"): one sidewalk tile with a curb edge against the road, and one normal parked car at one facing (top right), for the board's review before the full set (T-399). They must fit the existing roads, buildings and obstacles: the same isometric angle, tile size and pixel scale as the road tiles, the city's palette (Visual style, Decisions, "City colours"), and nothing of Greenbull. The parked car is a plain, boring city car, clearly not the player's car. Free script work first where it fits (for example the curb drawn by script from the road's kerb line). The board's go: PixelLab up to 50 generations for T-397 and T-399 together; write the planned calls and cost in the result notes before calling, and keep this sample to a few generations. Every asset goes through the style loop. Show the sample composed with a road tile, a building and a boulder, so the board judges the fit. Put the sample in `art-archive/<id>/`, not yet in the game.

The board's review: look at the sample next to the road, a building and a boulder, and approve or adjust it.

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", 2026-10-30). The board: "add sidewalk assets that fit with the road ... and the buildings and other assets that we have, and make sure that it works well, consider the curb as well. And I also want a few different car assets that are just sitting parked, just normal, boring kind of cars. Generate some broken ones as well. And make it so that they sit at four rotations: top right, bottom right, bottom left, top left. This is for the level creator." The board's answers: parked cars are solid obstacles like boulders (crash into them, pairable for thread the needle); sidewalks are painted like roads with the curb added automatically where they meet a road, and the car drives up over the curb; PixelLab up to 50 generations for the whole set (T-397 and T-399 together), sample first. The tickets: T-396 (piece names), T-397 (art sample), T-398 (the pieces in the creator and the run, placeholders), T-399 (the full art set, swapped in). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] One sidewalk tile with a curb edge and one parked car at the top-right facing are in `art-archive/<id>/`, at the road tiles' isometric angle and pixel scale (checked against a road tile). (QA: pass / fail)
- [ ] A composed preview shows them next to a road tile, a building and a boulder, on a dark and a light background, enlarged. (QA: pass / fail)
- [ ] Each went through the style loop, with its score in the Style review; the generations used are in the result notes, within the cap. (QA: pass / fail)
- [ ] Visual style describes the sidewalk's and the parked cars' look. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
