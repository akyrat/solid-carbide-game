---
id: T-399
title: Art: the full sidewalk and curb set and the parked and broken cars at four facings, swapped into the creator
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-397, T-398]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/working-with-the-board.md, docs/visual-style.md, docs/level-design.md, game/docs/level/level-creator-pieces.md]
files_expected_to_change: [game/art/, game/data/level/, game/docs/art/, docs/visual-style.md, art-archive/]
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

Built from the approved sample (T-397). The sidewalk tile and every curb piece T-398 uses (straights and corners); about three normal parked cars and two broken ones (a proposal; fewer if the cap runs short), each at the four facings top right, bottom right, bottom left, top left. Free script work first (mirroring a facing where the car's shape allows, curbs by script). The cap: PixelLab up to 50 generations for T-397 and T-399 together; write the planned calls and the remaining cap in the result notes before calling. Every asset goes through the style loop. Swap the art in for T-398's placeholders; game-ready art in `game/art/`, everything else in `art-archive/<id>/`.

Also the meteor craters (board, 2026-10-30, added after this ticket was written): 2 or 3 crater looks for T-398's crater piece, built from the crater approved in the sample, inside the same 50-generation cap.

The board's review: in the creator, paint sidewalks along roads and place every car at each facing and every crater next to buildings and boulders, then press Play.

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", 2026-10-30). The board: "add sidewalk assets that fit with the road ... and the buildings and other assets that we have, and make sure that it works well, consider the curb as well. And I also want a few different car assets that are just sitting parked, just normal, boring kind of cars. Generate some broken ones as well. And make it so that they sit at four rotations: top right, bottom right, bottom left, top left. This is for the level creator." The board's answers: parked cars are solid obstacles like boulders (crash into them, pairable for thread the needle); sidewalks are painted like roads with the curb added automatically where they meet a road, and the car drives up over the curb; PixelLab up to 50 generations for the whole set (T-397 and T-399 together), sample first. The tickets: T-396 (piece names), T-397 (art sample), T-398 (the pieces in the creator and the run, placeholders), T-399 (the full art set, swapped in). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The sidewalk and every curb piece T-398 uses, and each car look at all four facings, are in `game/art/` and used by the creator and the run in place of the placeholders. (QA: pass / fail)
- [ ] Each asset went through the style loop, with its score in the Style review; the generations used for T-397 and T-399 together are at most 50, listed in the result notes. (QA: pass / fail)
- [ ] Curbs join the road tiles with no gap or seam, and each car's facing matches its key (screenshots). (QA: pass / fail)
- [ ] Screenshots of the full set in the editor and in a run, next to roads, buildings and boulders, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] Visual style and game/docs/art/ record the set and the hand of any script fixes. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
