---
id: T-103
title: Art: the full ground set for the MVP map, put into the map (PixelLab)
status: blocked
from: project-lead
to: asset-generation
epic: art
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-063]
documents_affected: [game/README.md, art-archive/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-063-map-ground-art.md, tasks/T-019-build-mvp-map.md, tasks/T-097-mvp-map-without-challenges.md, tasks/T-101-car-sprites-remaining-directions.md, art-archive/README.md, game/README.md]
files_expected_to_change: [art files under game/art/ and their records, the map's scenes and drawing code, tests, art-archive/, game/README.md]
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

**Waits for the board's review of T-063's first road tile (2026-10-12).** Split from T-063. Don't start until the board has approved that tile; the board may add notes from its review here.

The rest of the MVP map's ground, matching the approved tile, as Visual style, Decisions ("Ground") describes it: asphalt roads with white lane lines, **zebra crossings** at the junctions, light cracks, the road around the map's edge, and the dusty gravel centre, with a few cracked variants so the roads don't look repeated. Then swap them in for the map's flat placeholder colours (T-019, T-097), so a run started from the main menu shows the final ground.

No pavements in the MVP (board, 2026-10-12): the roads meet the building blocks directly. The approved road tile is in `game/art/ground/`; the other T-063 tiles are in `art-archive/T-063/` and may be used to break up the repeating cracks.

The board approves the generations this task needs. Plan the calls first and write the plan and its expected cost in the result notes before calling; check the balance before and after; use a long HTTP timeout. One round: don't regenerate tiles you don't like; report them. Every generation that isn't used as-is goes to `art-archive/T-103/` with its record and a row in `art-archive/README.md`; nothing generated is deleted, and `game/art/` holds only game-ready art.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] Every ground tile is under `game/art/` with its record, and a check script shows each follows Visual style's technical rules (QA: pass / fail)
- [ ] The record lists every PixelLab call with its prompt, settings and cost, and the balance before and after; only one round of generation was made (QA: pass / fail)
- [ ] In a run started from the main menu, the map shows the final ground (roads, white lines, zebra crossings, the edge road, gravel centre) with no gaps or seams, lined up with the map's layout and collisions (screenshots) (QA: pass / fail)
- [ ] T-019's and T-097's map tests still pass: the layout and boulders are unchanged (QA: pass / fail)
- [ ] Every unused or raw generation is in `art-archive/T-103/` with its record and listed in `art-archive/README.md` (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest a run and judge the ground's look; one round only, so problems are reported rather than regenerated.
Board review files: the ground art under `game/art/` and the screenshots.

## Result notes

Written by the agent when it finishes.
