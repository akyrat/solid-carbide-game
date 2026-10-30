---
id: T-373
title: Text: the HUD size slider's label
status: cancelled
from: project-lead
to: narrative-theme
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/data/, docs/hud-and-menus.md, art-archive/]
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

The board's decision (HUD and menus, Decisions, "The HUD scales with the window, and a HUD size slider", 2026-10-29; an MVP nice-to-have, started only after the last MVP round). The pause screen gets a slider that sets the HUD's size. Write its label, in the form of the pause screen's other slider labels (zoom, music), and, if the UI ticket shows a value, how the value reads (for example a percent). Style loop for each new line. Put it where the pause screen reads its texts (say where) and in HUD and menus, Content, "Pause screen".

The board's review: read the label in HUD and menus, Content.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The label is in the data file the pause screen reads its texts from, named in the result notes, and in HUD and menus, Content, "Pause screen". (QA: pass / fail)
- [ ] Each new line scored at least 8 in the style loop, with every round in the Style review. (QA: pass / fail)
- [ ] The label follows Text rules and matches the other slider labels' form. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

- 2026-10-30, open → cancelled: Replaced by goal G-008 (HUD and main menu), which writes its own tickets from the same decisions (2026-10-30).
