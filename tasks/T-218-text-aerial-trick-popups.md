---
id: T-218
title: "Text: the two aerial tricks' popups"
status: in-qa
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, docs/extended-narrative.md]
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

The board adds two aerial tricks (Drifting, Decisions, "Aerial tricks", 2026-10-21): a **180** and a **360**, made by turning the car while it is in the air; left and right count the same. When one is done, a trick popup pops out of the car like the other tricks' popups (HUD and menus, Decisions and Content: white rounded cards, black lettering, Bangers). Write the text of the two popups: one short line each, in the same voice as the existing trick popups (see HUD and menus, Content), and clearly different from the ground drift's 360 popup so the player can tell an air 360 from a drift 360. Write them into HUD and menus, Content, next to the other trick popups, with this ticket's id, for T-219 to use word for word.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] HUD and menus, Content, has the exact text of both aerial trick popups, with this ticket's id (QA: pass; "AIR 180!" and "AIR 360!" in Trick popups with T-218)
- [ ] Each is one short line in the existing trick popups' voice, and the air 360's text differs from the drift 360's (QA: pass; short capitals lines with "!", AIR 360! differs from FULL 360!)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started: the popup texts for the air 180 and air 360.

### 2026-10-21, In progress → In QA

Texts written: "AIR 180!" and "AIR 360!". Sent to QA.

## Result notes

Written by the agent when it finishes.

Narrative Theme Agent: wrote the two popup texts into docs/hud-and-menus.md (Trick popups, in the Content section, next to LONG DRIFT!, FULL 360!, ALT DRIFT!):
- Air 180: "AIR 180!"
- Air 360: "AIR 360!"
Same voice as the existing popups (capitals, one short line, exclamation mark; Bangers has capitals only). The word AIR tells an air 360 from the drift's "FULL 360!". The combo amount ("+{amount}") is appended as for the other tricks. No other documents affected.
