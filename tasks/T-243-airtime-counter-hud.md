---
id: T-243
title: The HUD's live airtime counter while the car is airborne
status: in-progress
from: project-lead
to: ui
lead: Coursework
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, game/README.md, game/scripts/hud/hud.gd, game/scripts/hud/trick_popups.gd]
files_expected_to_change: [game/scripts/hud/, game/scenes/hud/, game/tests/unit/, game/README.md, docs/hud-and-menus.md, art-archive/T-243/screenshots/]
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

The board's decision (HUD and menus, Decisions, "Airtime counter", 2026-10-21): while the car is airborne, a small label near the bottom right of where the combo popups show counts its airtime up, as a plain number with two decimals (0.00, 0.01, ... seconds, no unit and no other text), next to a small icon standing for a jump, such as a wing. It appears when the car leaves the ground and disappears on landing (when the airtime trick, T-242, pays out). Read the car's airborne state as the aerial tricks do (`car_height.gd`, T-219). It has no words, so no text ticket is needed.

Use a **placeholder** icon drawn in code (a simple wing or similar, never Redgull red), in the HUD's comic look (HUD and menus, Decisions: white, black outline, the Bangers font for the number). Its exact place, size and look are your proposals for the playtest.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the counter mid-jump and a short GIF of it counting during a jump.

## Acceptance criteria

- [ ] Tests show the counter appears when the car leaves the ground, counts up in hundredths of a second matching the airtime, and disappears on landing (QA: pass / fail)
- [ ] It shows only a two-decimal number and the placeholder icon, near the bottom right of the combo popups' area, never Redgull red (screenshot) (QA: pass / fail)
- [ ] A GIF of a jump shows it counting, in `art-archive/T-243/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: jump off a rooftop and watch the counter.
Board review files: the screenshot and GIF in `art-archive/T-243/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started at the board's request.

## Result notes

Written by the agent when it finishes.

Built (UI Agent). `game/scripts/hud/airtime_counter.gd` (`AirtimeCounter`): a code-drawn white wing with a black outline (placeholder, no red) and a two-decimal Bangers number, no unit. `Hud.bind_car(car)` (called from `run.gd` for each new car) follows the car's `stepped` signal and reads `car.airborne` and `car.model.dt`: shown from the first airborne step, counts one physics step per step in the air, hidden and reset on landing or when a new car is bound.

Proposals for the playtest: number 30 px with an 8 px outline, icon 30 x 22; placed at `Hud.AIRTIME_OFFSET` (70, -10) from the screen's centre (right of the car, a little below where popups start); the airtime is counted in physics steps, as the trick will pay it out.

Tests: `game/tests/unit/hud/test_hud_airtime_counter.gd` (9 tests); full GUT suite passes (the earlier failed run was a parse error in my own test, fixed); `python -m unittest discover -s tools` 439 OK; `-s game/tools` 393 OK (1 skipped).

Screenshot and GIF: `art-archive/T-243/screenshots/airtime_counter.png` (mid-jump, 0.60) and `airtime_counter.gif` (4 MB, 72 frames, counts up during a jump off a rooftop). Fixture: `game/tests/fixtures/airtime_counter_gif.tscn`.

Documents affected, updated: `docs/hud-and-menus.md` (the airtime counter decision notes the build), `game/README.md` (new "Airtime counter (HUD)" section).
