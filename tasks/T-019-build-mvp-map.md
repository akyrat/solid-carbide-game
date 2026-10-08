---
id: T-019
title: Build the MVP map: city grid, obstacle patterns and preset challenges
status: open
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
depends_on: []
documents_affected: [docs/level-design.md, game/README.md]
files_expected_to_change: [the map scene and its scripts, the map's layout data file, their tests, screenshots, docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/level-design.md, docs/level-design/, docs/game-loop-architecture.md, docs/visual-style.md, docs/drifting.md, game/README.md, .claude/agents/level-challenge.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The rule for completing a challenge is in Level design, Decisions (2026-10-08): the drawn car touches the corridor continuously from the arrow's start to its end, in the arrow's direction; leaving it midway means starting again.

Build the MVP map in Godot as Level design describes it, with flat placeholder colours (no PixelLab): the board will look at the layout and the challenges before any art.

- **The city grid** (Level design, Decisions): 80 by 80 units, 1 unit = the car's width; an 8-unit perimeter road with a hard stop at the edges; 10 by 10 building blocks in a 4 by 4 grid with 8-unit roads; the 28 by 28 gravel centre with no blocks. Buildings and the map edge block the car. The map must be easy to drop the T-012 car into later (same units and physics rate); it does not need the car to be finished.
- **Obstacle patterns and fitting the sketches:** the board's drawings in `docs/level-design/` are rough sketches of the general shape (Level design, Decisions). Make fitted versions that work on the map: as drawn they measure about 11 by 12, 11 by 13 and 11 by 20 units with their 3-unit corridors, and the roads are 8 units wide. Adjust size, spacing and how tight the loops are as needed, but keep the shape: the number of boulders (3 units across), which way the arrow goes around each boulder, and the overall path. Save each fitted version next to its sketch (for example `arrow-1.fitted.json` and `.svg`) and leave the sketches unchanged. Place copies of the 2 patterns. How many copies and where is this agent's call (Level design, Decisions); list them with their positions in the result notes so the board can adjust. Boulders block the car.
- **Preset challenges:** choose 30% of the pattern copies to be challenges, the same on every run (round to the nearest whole number, at least 1, and say how in the result notes). For a Single Boulder challenge, pick one of its 2 arrows. Each challenge shows its arrow on the ground as a 3-unit-wide corridor (a flat placeholder band with an arrowhead is fine; the painted animation comes later).
- **Completing a challenge** (rule in Level design, Decisions): the arrow disappears, the boulders stay as plain obstacles for the rest of the run, and the map sends a clear "challenge completed" signal that XP and the HUD will hook into later. Awarding XP itself is not part of this task.
- **Layout data:** save the placed buildings, pattern copies, boulders and challenges (with their arrow points in map units) to one data file, so tests, the drivability check (T-021) and the board can read the map without opening Godot.
- **Docs:** `game/README.md` explains how to open the map scene. In `docs/level-design.md`, add a `### MVP map` subsection under Content (what was built, where the patterns and challenges are, with a screenshot) and link the layout data in References; do not change Summary, Decisions or Open questions. Follow `docs/README.md`.

Before handing challenges over, this agent normally checks they are drivable with the Driving & Drift Agent's script. That script is T-021 and needs the Godot car (T-012), so here, list which challenges still need that check; the check happens when T-021 is done.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] A test reading the layout data shows the map is 80 by 80 units, with the perimeter road, the 16 blocks minus the centre ones, the 8-unit roads and the 28 by 28 gravel centre at the positions Level design gives (QA: pass / fail)
- [ ] A test shows every boulder is 3 units across, and every pattern copy matches its fitted version; a test shows each fitted version keeps its sketch's number of boulders and the arrow's direction around each boulder (QA: pass / fail)
- [ ] A test shows the number of challenges is 30% of the pattern copies, rounded as the result notes say, and the same on every run (QA: pass / fail)
- [ ] A test shows no challenge corridor and no boulder overlaps a building or lies outside the map (QA: pass / fail)
- [ ] A test drives a stand-in body along one challenge per the completion rule and shows the "challenge completed" signal fires once, the arrow disappears, and the boulders remain (QA: pass / fail)
- [ ] A screenshot of the whole map (with the T-001 screenshot tool) shows the grid, the boulders and the challenge arrows (QA: pass / fail)
- [ ] No PixelLab call was made: `game/art/pixellab-generation-log.jsonl` is unchanged (QA: pass / fail)
- [ ] `game/README.md` explains how to open the map; `docs/level-design.md` has the `### MVP map` subsection and links the layout data, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: look at the map screenshot and the list of pattern copies and challenges, and adjust if needed.

## Result notes

Written by the agent when it finishes.
