---
id: T-244
title: "Text: the combo broken popup"
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
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/extended-narrative.md]
files_expected_to_change: [docs/hud-and-menus.md]
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

The board wants feedback when the player breaks their combo (HUD and menus, Decisions, "Combo broken popup", 2026-10-21): when a crash cuts the combo, a red, broken-looking popup pops from the car like the trick popups. Write its text: one short line in the trick popups' voice (LONG DRIFT!, FULL 360!, AIR 360!; HUD and menus, Content), but reading as a loss (for example something like COMBO BROKEN!). Say whether it shows how much was lost, as a proposal. Write it into HUD and menus, Content, with this ticket's id, for T-245 to use word for word.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] HUD and menus, Content, has the combo broken popup's exact text, with this ticket's id (QA: pass / fail)
- [ ] It is one short line in the trick popups' voice that reads as a loss (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
