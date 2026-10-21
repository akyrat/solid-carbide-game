---
id: T-245
title: A red, broken-looking popup when a crash breaks the combo
status: blocked
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-244]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md, game/scripts/hud/trick_popups.gd, game/scripts/hud/trick_popup_art.gd, tasks/T-244-text-combo-broken-popup.md]
files_expected_to_change: [game/scripts/hud/, game/tests/unit/, game/README.md, docs/hud-and-menus.md, art-archive/T-245/screenshots/]
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

The board's decision (HUD and menus, Decisions, "Combo broken popup", 2026-10-21): when a crash cuts the combo (hitting a wall, a building, a boulder or the map edge, or any damage to the car; Game loop architecture, Content, "The combo"), a popup pops from the car like the trick popups, with T-244's text word for word, but in red and in a broken, cracked style (for example a cracked or jagged card, a shake, pieces falling away: your proposal). Only on a crash that actually cuts a combo (not when there is no combo, and not when the combo drains away). The red is a warning red, never Redgull's red. It follows the car like the trick popups and stacks with them.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot and a short GIF of the popup after a crash in a run (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show the popup appears when a crash cuts a combo, and not when there is no combo or when the combo drains (QA: pass / fail)
- [ ] It shows T-244's text word for word, in red (not Redgull's red) and a broken style, following the car (screenshot, GIF) (QA: pass / fail)
- [ ] The GIF is in `art-archive/T-245/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: build a combo, crash into a wall, and watch the popup.
Board review files: the screenshot and GIF in `art-archive/T-245/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
