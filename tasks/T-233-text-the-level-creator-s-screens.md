---
id: T-233
title: Text: the level creator's screens
status: open
from: project-lead
to: narrative-theme
lead: Goal-G-005
epic: narrative
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/extended-narrative.md, docs/hud-and-menus.md]
files_expected_to_change: [game/data/level/creator_texts.json, docs/level-design.md]
model: sonnet
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

Write every piece of text the level creator shows (Level design, Decisions, 'Level creator', board 2026-10-21). The creator is the board's own tool, never shipped to players, so plain, clear labels are right; keep them short (buttons fit about 16 characters, panel category names about 12). Pieces, each with where it appears: the list screen's title; the new-level button (the only thing on the list when there are no levels); the play and edit actions on each listed level; the default name of a new level and the label of the level name field in the editor; the side panel's category names (ground tiles, roads, buildings, boulders, rooftops, ramps); the height labels for rooftops (3, 6) and ramps (0 to 3, 3 to 6); the rotate, mirror, delete and save labels; the save confirmation; the message shown when a piece can't be placed because it overlaps another piece; the editor's back-to-list button; and the controls hint line (mouse to place, the keys for rotate, mirror and delete). Write them into game/data/level/creator_texts.json (one key per piece, with a short note of where it appears), which the creator's scripts read, and list them in docs/level-design.md, Content, 'Level creator text', pointing to the JSON as the source.

The board's review: Read the creator's text in game/data/level/creator_texts.json.

## Acceptance criteria

- [ ] game/data/level/creator_texts.json exists, is valid JSON and has a text and a 'where it appears' note for each piece in the description: list title, new-level button, play and edit actions, default level name and name field label, the six panel category names, the rooftop and ramp height labels, rotate, mirror, delete and save labels, save confirmation, overlap message, back-to-list button and controls hint. (QA: pass / fail)
- [ ] No button text is longer than 16 characters and no category name longer than 12. (QA: pass / fail)
- [ ] docs/level-design.md, Content, has a 'Level creator text' section listing each piece and pointing to creator_texts.json. (QA: pass / fail)
- [ ] The result notes say in one line that there is nothing to screenshot (text only). (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
