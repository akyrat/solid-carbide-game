---
id: T-208
title: "Text: the music volume slider's label"
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/extended-narrative.md]
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

The pause screen gets a music volume slider under "SFX volume" (HUD and menus, Decisions, 2026-10-20). Write its label. It is one short line, shown at the left of the slider on the pause screen. It is the same kind of plain settings label as "SFX volume" (the board's name) and "Camera zoom level", so it reads as their sibling. Write it into HUD and menus, Content, as a "Music volume slider" entry next to the SFX volume slider's, with this ticket's id, for T-210 to use word for word.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] HUD and menus, Content, has a music volume slider entry with the label's exact text and this ticket's id (QA: pass)
- [ ] The label is one short line in the same style as "SFX volume" and "Camera zoom level" (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Open → In progress

Started: the agent is working in its own folder, C:\solid-carbide-worktrees$t, in parallel with the others.

### 2026-10-20, In progress → In QA

The label is written: "Music volume". Sent to QA.

## Result notes

Written by the agent when it finishes.

Label: "Music volume" (plain, lowercase second word, matching "SFX volume" and "Camera zoom level"; no story flavor, as settings labels are plain). Written into docs/hud-and-menus.md, Content, as the "Music volume slider" entry (T-208), directly after the SFX volume slider's entry. Documents affected: docs/hud-and-menus.md.
