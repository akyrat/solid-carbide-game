---
id: T-591
title: Texts: needle routes in the level creator
status: open
from: project-lead
to: narrative-theme
lead: Rails
epic: level-creator
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/level-design.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json]
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

Write the level creator texts for Level design, Decisions, "Needle routes", in the voice and length of the creator's other texts (the pair tool's texts in level-design.md Content, "Pair tool", and the creator's texts file): the route tool's button and its key in the controls hint (pick a free key and say which; check the creator's existing keys in level-design.md Content), the hint while it is on (click pair lines in order), the top bar message when a pair joins a route and when the route is finished, the order switch's two choices (in order, random), a short label naming a route and its pair count, and the button to remove a pair from its route. These are a dev tool's texts for the board, so plain and short; through the style loop only if the creator's other texts were. List each with its key and where it shows in the result notes for T-591, and in level-design.md Content.

The board's review: in T-591's build.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Every text listed in the description exists in the creator's texts file with a key, listed in the result notes with where it shows. (QA: pass / fail)
- [ ] level-design.md Content lists them. (QA: pass / fail)
- [ ] The chosen key is not used by the creator already (checked against the listed controls). (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
