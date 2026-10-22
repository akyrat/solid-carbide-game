---
id: T-263
title: "Level creator: paint roads with a brush that joins them itself"
status: blocked
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-261]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level_creator/, game/tools/build_ground_tiles.py, game/art/ground/ground_atlas.json, tasks/T-252-road-junction-tiles.md, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level_creator/, game/tools/, game/art/ground/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-263/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22): roads are painted with a brush. Pick Road, Centre line, Zebra crossing or Cracked road (T-262's Roads group), then press and drag across the map: the road is laid along the drag at the full road width (today's two-tile-wide road, with a centre line in its middle for Centre line, never two half tiles the board has to pair up), and wherever painted roads meet, the editor picks the right piece itself: straights in both directions, corners, T-junctions, crossroads and dead ends at the open ends (T-252's pieces and today's straight tiles; draw by script any piece still missing, for example a centre-line corner or junction, no PixelLab). Painting over a road changes its kind; the delete key (or a right-drag, your proposal) erases road along the drag and the neighbours re-join. Zebra crossing is placed across a road where you click. A road never paints over a building, platform or ramp. Saved levels write the same ground data as today, so they play unchanged, and earlier levels still open. The panel's old separate road tiles are no longer needed (keep them in the data so old levels draw).

Built on T-262's branch (the Project Lead makes your folder). Labels from `creator_texts.json` (T-261). End with screenshots of a street grid painted in a few drags with every junction kind, and a short GIF of painting one.

## Acceptance criteria

- [ ] Tests show a drag paints a full-width road along it, and that meeting roads become the right straight, corner, T-junction, crossroads or dead end, for each road kind; erasing re-joins the neighbours (QA: pass / fail)
- [ ] The centre line runs in the middle of the road and joins across every piece without gaps (tests on the tile data and the screenshot) (QA: pass / fail)
- [ ] A painted level saves, passes `check_level.py` and plays; earlier levels open unchanged (tests) (QA: pass / fail)
- [ ] Screenshots and the GIF are in `art-archive/T-263/screenshots/`; `game/README.md` describes the brush; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: paint a street grid with the brush.
Board review files: the screenshots and GIF in `art-archive/T-263/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
