---
id: T-279
title: "Text: the level creator's spawn point"
status: done
from: project-lead
to: narrative-theme
lead: Coursework
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json, tasks/T-271-text-thread-the-needle.md]
files_expected_to_change: [game/data/level/creator_texts.json, docs/level-design.md]
model: sonnet
qa_rounds: 1
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

The board's decision (Level design, Decisions, "The car's spawn point", 2026-10-22). Write the creator's labels for the spawn point, plain like T-261's and T-271's, into `game/data/level/creator_texts.json` (keep every existing key unchanged) and Level design, Content, "Level creator text", with this ticket's id: the marker's label on the map (for example "Start"), the hint while it is selected (drag to move, the turn key for its heading), the top bar message when it can't go where it was dropped (inside a building, an obstacle or off the map), the message when the board tries to delete it (it can't be deleted), and an updated controls hint line that adds the spawn point. Built on the level creator's build: the Project Lead makes your folder from the creator line (with T-261's and T-271's labels).

## Acceptance criteria

- [ ] `creator_texts.json` is valid JSON with the spawn labels (each with a "where it appears" note), every existing key unchanged, listed in Level design, Content, with this ticket's id (QA: pass; JSON valid, 5 new keys each with a where note, all T-271 keys unchanged, listed in Level design Content with T-279)
- [ ] The labels are short and plain like the creator's others (buttons about 16 characters) (QA: pass; "Start" is the only label; messages are short plain sentences, hint under 30 characters)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Open → In progress

Started at the board's request: the spawn point's labels.

### 2026-10-22, In progress → In QA

Text written: Start marker, its hint and messages, and the updated controls line. Sent to QA.

### 2026-10-22, In QA → Done

QA passed both. Done: the spawn point's labels; T-280 uses them.

## Result notes

Written by the agent when it finishes.

Added five keys to `game/data/level/creator_texts.json` (every existing key unchanged) and listed them in Level design, Content, "Level creator text", with this ticket's id: `spawn_label` "Start", `spawn_hint` "Start: drag to move. R: turn.", `spawn_blocked` "Can't start here: it's blocked.", `spawn_no_delete` "The start can't be deleted.", `controls_hint_spawn` (the pairs hint with "move the start" added; replaces `controls_hint_pairs`, which is kept). R is used as the turn key, the same as for pieces; the build must use the same key. Documents affected: docs/level-design.md.
- 2026-10-22, in-qa → done: QA passed both; text only, kept on the creator build line
