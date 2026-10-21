---
id: T-223
title: "Text: the pickup magnet upgrade's name and description in the garage"
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
documents_affected: [docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/extended-narrative.md, game/data/garage.json]
files_expected_to_change: [docs/garage-design.md]
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

The garage gets a fourth upgrade (Garage design, Decisions, "Pickup magnet upgrade", 2026-10-21): the radius within which coins, gift packs and health drops are pulled to the car. Write its text for the garage's list, in the same form and voice as the three existing upgrades' texts (see Garage design, Content, and `game/data/garage.json`): its name, and whatever short description or effect line the other upgrades have. Write it into Garage design, Content, with this ticket's id, for T-224 to use word for word.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] Garage design, Content, has the magnet upgrade's exact name (and description line, if the other upgrades have one), with this ticket's id (QA: pass; "Brand Magnet" and desc line under Content, "Pickup magnet text (T-223)")
- [ ] It matches the existing upgrades' form and voice (QA: pass; name under 25, desc 70/80, same Redgull-joke ending as T-059 texts; no number, explained)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's request.

### 2026-10-21, In progress → In QA

Text written: Brand Magnet, "Pickups reach you from further per level. Redgull calls it engagement." Sent to QA.

### 2026-10-21, In QA → Done

QA passed both. Merged: Brand Magnet.

## Result notes

Written by the agent when it finishes.

Written into Garage design, Content, "Pickup magnet text (T-223)". Same form as T-059: a name (max 25) and one description line (max 80), no numbers since Game Data proposes the reach per level, Redgull-joke ending like the other three.

| Key | Text | Length |
|---|---|---|
| garage.pickup_magnet.name | Brand Magnet | 12/25 |
| garage.pickup_magnet.desc | Pickups reach you from further per level. Redgull calls it engagement. | 70/80 |

No XP or experience wording. Documents changed: docs/garage-design.md.
- 2026-10-21, in-qa → done: QA passed both; docs-only text, merged straight after QA
