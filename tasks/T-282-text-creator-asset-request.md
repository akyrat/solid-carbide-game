---
id: T-282
title: "Text: the level creator's \"+\" asset request tab"
status: open
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
files_to_read_first: [tasks/README.md, docs/level-design.md, game/data/level/creator_texts.json, tasks/T-279-text-spawn-point.md, tasks/T-283-creator-asset-request-tab.md]
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

The board's decision (Level design, Decisions, "Asking for a new piece from the creator", 2026-10-24). Write the labels for T-283's asset request tab, plain like T-261's, T-271's and T-279's. Add them to `game/data/level/creator_texts.json`, keeping every existing key unchanged, and to Level design, Content, "Level creator text", with this ticket's id:

- **Button:** the "+" button's tooltip in the side panel.
- **Tab:** the tab's title.
- **Kinds:** the three kind choices (building, obstacle, decoration).
- **Description box:** its label, and the grey hint inside it while it is empty.
- **Footprint:** the optional footprint size's label.
- **Buttons:** Send and Cancel.
- **Request states:** the request's line in the panel while it waits for a session, while the art is being made, when the piece is ready, and when it failed.
- **Empty description:** the message when Send is pressed with no description.

Built on the level creator's build: the Project Lead makes your folder from `playtest/creator-set`.

## Acceptance criteria

- [ ] `creator_texts.json` is valid JSON with the request tab's labels (each with a "where it appears" note), every existing key unchanged, listed in Level design, Content, with this ticket's id (QA: pass / fail)
- [ ] The labels are short and plain like the creator's others (buttons about 16 characters) (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
