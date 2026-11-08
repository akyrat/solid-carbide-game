---
id: T-575
title: Texts: the level creator's labels for the hint pieces
status: open
from: project-lead
to: narrative-theme
lead: Rails
epic: level
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json, game/docs/level/level-creator.md]
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
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Write the level creator's labels for Level design, Decisions, "Hint pieces in the level creator", through the style loop, in the voice of the creator's other labels: the side panel's category name for the hints, a label for each piece (gas, brake, straight arrow, curved arrow, circular arrow), the choice between painted on the ground and standing sign, and any hint line the creator's bottom bar shows while one is picked. These are the board's tool labels; the pieces themselves show no words in the game. Keys and _comment in game/data/level/creator_texts.json; list them in the result notes for T-576.

The board's review: in T-576's build, open the level creator.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/ (the board's own levels). Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each label exists in creator_texts.json with a key and a _comment, listed in the result notes. (QA: pass / fail)
- [ ] Each scores 8 or more in the style loop, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/level-design.md Content lists them. (QA: pass / fail)
- [ ] The creator's text test (test_creator_texts_only.gd) and the data tests pass, and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
