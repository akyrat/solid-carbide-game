---
id: T-236
title: Level creator: rotate between the art's views, mirror, and rooftops and ramps at heights 3 and 6
status: open
from: project-lead
to: level-challenge
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-235]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/data/level/creator_assets.json, game/scripts/level_creator/editor.gd, game/scripts/level/elevation_layer.gd, game/tools/check_height_data.py, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/scripts/level_creator/editor.gd, game/scripts/level_creator/asset_panel.gd, game/scripts/level_creator/level_document.gd, game/tests/unit/level_creator/test_editor_rotate_heights.gd, game/README.md]
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

Rotating in the creator means switching between the views the art exists in and mirroring them, since the art has only the angles that were generated (Level design, Decisions, 'Level creator', board 2026-10-21). Before placing, the selected asset steps through the views and mirrors its catalogue entry lists (creator_assets.json), and only those; the preview under the cursor shows the current one. Rooftops can be placed at height 3 or 6; a 6 stands on a 3 and is written with the 'on' field, as in the elevation sample map's height data. Ramps are placed 0 to 3 or 3 to 6, with the side they climb. The level data written must pass check_height_data.py. The rotate, mirror and height labels come from creator_texts.json. Add the rotate, mirror and height controls to game/README.md, 'Level creator'. Screenshot of rooftops at 3 and 6 with their ramps in the editor in art-archive/<this task's id>/screenshots/.

The board's review: In the level creator, rotate and mirror pieces before placing them, and build a rooftop at 3 and a 6 on it with their ramps.

## Acceptance criteria

- [ ] A unit test per asset kind: stepping rotate and mirror on the selected asset offers exactly the views and mirrors its catalogue entry lists, and no others. (QA: pass / fail)
- [ ] A unit test places a rooftop at 3, a rooftop at 6 on it (its 'on' field naming the 3), a ramp 0 to 3 and a ramp 3 to 6 with the side they climb; the level data written to a temporary file passes python game/tools/check_height_data.py. (QA: pass / fail)
- [ ] The rotate, mirror and height labels come from creator_texts.json, and the test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', lists the rotate, mirror and height controls. (QA: pass / fail)
- [ ] A screenshot of rooftops at 3 and 6 with their ramps in the editor is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
