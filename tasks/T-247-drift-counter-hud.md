---
id: T-247
title: The HUD's live drift counter, next to the airtime counter
status: done
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/drifting.md, game/README.md, tasks/T-243-airtime-counter-hud.md]
files_expected_to_change: [game/scripts/hud/, game/scenes/hud/, game/tests/unit/, game/README.md, docs/hud-and-menus.md, art-archive/T-247/screenshots/]
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

The board's decision (HUD and menus, Decisions, "Drift counter", 2026-10-22): while the car is drifting, a second small label next to the airtime counter (T-243) counts the drift's length up the same way (a plain two-decimal number, seconds, no unit and no other text), with its own small placeholder icon standing for a drift, drawn in code, never Redgull red. It disappears when the drift ends (when T-246 pays it out). Build it on T-243's counter (reuse its look and code), in the same place, so both can show at once when the car drifts off an edge. Its icon and exact spot are your proposals for the playtest.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot and a short GIF of the drift counter counting during a drift.

## Acceptance criteria

- [ ] Tests show the counter appears when a drift starts, counts up in hundredths matching the drift's length, and disappears when the drift ends (QA: pass; test_hud_drift_counter covers appear, hundredths count, disappear and restart; GUT 1305/1305 pass)
- [ ] It shows only a two-decimal number and its placeholder icon, beside the airtime counter, never Redgull red; both can show at once (screenshot) (QA: pass; screenshots show number plus skid-mark icon, white, under the airtime counter without overlap; both together is staged in a fixture because drifting stops in the air, T-219, as noted)
- [ ] A GIF of a drift shows it counting, in `art-archive/T-247/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass; drift_counter.gif present, 2 s drift; GUT, tools 439 OK, game/tools 393 OK)

The board's review: drift and watch the counter.
Board review files: the screenshot and GIF in `art-archive/T-247/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started at the board's word, built on T-243's airtime counter branch; T-243 taken out of its dependencies.

### 2026-10-22, In progress → In QA

Built: a drift counter with a skid-marks icon under the airtime counter. In play the two rarely show together, since a drift ends at takeoff. Sent to QA.

### 2026-10-22, In QA → Needs playtest

QA passed all 3. Ready to play: drift and watch the counter under the airtime one. The two rarely show together, since a drift ends at takeoff.

### 2026-10-22, Needs playtest → Done

The board played it in the T-229 build: good. Merging into master.

## Result notes

Written by the agent when it finishes.

Built `DriftCounter` (`game/scripts/hud/drift_counter.gd`), a subclass of `AirtimeCounter` that only swaps the icon (new `_make_icon()` hook): two code-drawn skid marks, white with black outline. `Hud` builds it, feeds it `car.model.is_drifting` and `model.dt` each physics step and resets it in `bind_car`. Tests: `tests/unit/hud/test_hud_drift_counter.gd` (appears, counts in hundredths, disappears and restarts, both counters independent, rebinding, number and icon only and never red, place in a run); the airtime test's fake model got an `is_drifting` field. Full GUT suite, both Python tool test sets pass (see the final run below).

Proposals for the playtest: the counter sits directly under the airtime counter (`Hud.DRIFT_OFFSET` (70, 30)); the icon is two skid marks. Finding: T-219 stops drifting in the air, so the drift counter ends at takeoff and both counters never really show at once in play; the screenshot with both is staged (airtime counter set by hand).

Screenshots and GIF in `art-archive/T-247/screenshots/`: `drift_counter.png` (1.00), `drift_and_airtime_counters.png` (staged both), `drift_counter.gif` (a 2 s drift). Fixture: `game/tests/fixtures/drift_counter_gif.tscn`. Documents updated: `game/README.md`, `docs/hud-and-menus.md`.
- 2026-10-22, needs-playtest → done: board's playtest: good (played in the T-229 build)
