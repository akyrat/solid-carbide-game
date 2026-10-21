---
id: T-237
title: Level creator: pieces snap to the tile grid and to close neighbours
status: open
from: project-lead
to: level-challenge
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-236]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/scripts/enemies/enemy_navigation.gd, game/tools/check_level.py, game/tools/check_height_data.py]
files_expected_to_change: [game/scripts/level_creator/snapping.gd, game/scripts/level_creator/editor.gd, game/tests/unit/level_creator/test_snapping.gd, game/README.md]
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

Pieces snap to the map's tile grid and to close neighbours so they align with little effort (Level design, Decisions, 'Level creator', board 2026-10-21). Every placed piece snaps to the map's tile grid so its edges lie on even units (enemy_navigation.gd's CELL = 2; the level validator checks the same). A piece placed within a snap distance of a neighbour lines its edge up with that neighbour's edge, for example a ramp's top end onto a rooftop's side, a rooftop at 6 onto its 3's edges, a building against a road. The docs give no snap distance: propose one, write it in game/README.md, 'Level creator', and in the result notes as a proposal for the board. Pieces that would overlap in a way the validator refuses are either not placed or placed and flagged (choose one, say which in the result notes); when refused or flagged, the editor shows the overlap message from creator_texts.json. Screenshot in art-archive/<this task's id>/screenshots/ of a ramp snapped onto a rooftop's side.

The board's review: In the level creator, place pieces next to each other and check they snap into line, a ramp onto a rooftop for example.

## Acceptance criteria

- [ ] A unit test places pieces from off-grid cursor positions: every placed piece's edges lie on even units. (QA: pass / fail)
- [ ] Unit tests: a piece placed within the documented snap distance of a neighbour lines its edge up with the neighbour's edge, including a ramp's top end onto a rooftop's side; a piece placed farther away does not move to the neighbour. (QA: pass / fail)
- [ ] A unit test: a piece that would overlap in a way check_level.py refuses is not placed or is flagged (as the result notes say), and the overlap message from creator_texts.json is shown. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', gives the snap distance; the result notes give it as a proposal for the board. (QA: pass / fail)
- [ ] The test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass / fail)
- [ ] A screenshot of a ramp snapped onto a rooftop's side is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
