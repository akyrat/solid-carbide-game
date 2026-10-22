---
id: T-245
title: A red, broken-looking popup when a crash breaks the combo
status: in-qa
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

- [ ] Tests show the popup appears when a crash cuts a combo, and not when there is no combo or when the combo drains (QA: pass; test_combo_broken_popup.gd covers a cut, any damage, an obstacle hit, no combo, drain, signal only on a cut)
- [ ] It shows T-244's text word for word, in red (not Redgull's red) and a broken style, following the car (screenshot, GIF) (QA: pass; screenshot shows COMBO BROKEN! above the car on a cracked orange-red card (255,80,16, not Redgull 135,17,27, not the heart); text matches T-244; follows-car test passes)
- [ ] The GIF is in `art-archive/T-245/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass; GIF and PNG present; GUT all passed, tools 439 OK, game/tools 393 OK skipped=1)

The board's review: build a combo, crash into a wall, and watch the popup.
Board review files: the screenshot and GIF in `art-archive/T-245/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started.

### 2026-10-22, In progress → In QA

Built: a red-orange cracked COMBO BROKEN! card that shakes and breaks apart, only when a crash cuts a combo. Sent to QA.

## Result notes

Written by the agent when it finishes.

Built by the UI agent. `RunState.combo_broken` fires when a collision or damage takes a going combo down (the only change outside the HUD: one signal and four lines in `collision()`); `TrickPopups` shows it as a red cracked card (`combo_broken_art.gd`). Documents updated: docs/hud-and-menus.md, game/README.md. Screenshot and GIF: art-archive/T-245/screenshots/T-245_combo_broken.png and .gif.

Proposals for the playtest: the red is a warning red-orange (255, 80, 16) so it stays clear of Redgull's heart red; white letters with a black outline on the red; the crack runs through the lettering and the right half falls away after a short shake; no amount lost shown. The trick popups are not in the still screenshot (the screenshot tool's frames are slow, so they had already expired); stacking with trick popups is covered by a test.

Tests: full GUT suite 1299/1299 pass (`bash game/tools/run_tests.sh`), `python -m unittest discover -s tools` 439 OK, `-s game/tools` 393 OK (1 skipped, as before). The one refused command was an inline python edit of this task file (blocked by the status hook); I redid it with the Edit tool.
