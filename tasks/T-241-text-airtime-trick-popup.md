---
id: T-241
title: "Text: the airtime trick's popup"
status: in-progress
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

The board adds an airtime trick (Drifting, Decisions, "Airtime trick", 2026-10-21): every time the car lands after being in the air, a trick popup pays out its airtime. Write the popup's text: one short line in the voice of the existing trick popups (LONG DRIFT!, FULL 360!, ALT DRIFT!, AIR 180!, AIR 360!; HUD and menus, Content), followed by "+{amount}" as the others are. Say whether it shows the airtime itself (for example the seconds) or not, as a proposal. Write it into HUD and menus, Content, next to the other trick popups, with this ticket's id, for T-242 to use word for word. The live airtime counter (T-243) is a plain number with an icon and needs no text.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] HUD and menus, Content, has the airtime popup's exact text, with this ticket's id (QA: pass / fail)
- [ ] It is one short line in the existing trick popups' voice, clearly different from AIR 180! and AIR 360! (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's request.

## Result notes

Popup text: **HANG TIME!** followed by "+{amount}", written in docs/hud-and-menus.md (Content, Trick popups, T-241). Proposal: it does not show the airtime (the live counter T-243 does); same size as the AIR popups. Chosen for the voice of LONG DRIFT! and FULL 360!, and clearly apart from AIR 180!/AIR 360!. Only docs/hud-and-menus.md changed.
