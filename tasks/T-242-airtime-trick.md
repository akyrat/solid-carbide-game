---
id: T-242
title: The airtime trick, paying out on landing by how long the car was in the air
status: done
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-241]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md, game/scripts/driving/trick_detector.gd, game/data/combo.json, game/scripts/hud/trick_popups.gd, tasks/T-219-aerial-tricks-180-and-360.md, tasks/T-241-text-airtime-trick-popup.md]
files_expected_to_change: [game/scripts/driving/trick_detector.gd, game/data/combo.json, game/scripts/hud/, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-242/screenshots/]
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

The board's new trick (Drifting, Decisions, "Airtime trick", 2026-10-21): every time the car is off the ground, its airtime is a trick of its own. On landing it pays a combo amount that scales with how long the car was in the air, in seconds and hundredths, through the existing combo (Game loop architecture, Decisions) and the existing trick popups, with T-241's text word for word. It counts alongside AIR 180! and AIR 360! (T-219). Propose reasonable defaults for the playtest, as tuning numbers in `game/data/combo.json`: the scaling (for example an amount per second, a minimum airtime below which nothing pays, and a cap), and how it sits next to the aerial tricks' amounts. Detect it from the car's airborne state in `trick_detector.gd`, the same way T-219 does. Don't change how the car drives. The live counter while airborne is T-243's.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the popup and a short GIF of a jump paying out (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show a landing after an airtime pays the airtime trick, with the amount the data's scaling gives for that airtime (two different airtimes give the expected different amounts), and that airtime below the minimum pays nothing (QA: pass; test_airtime_trick.gd covers two airtimes giving different amounts, below-minimum pays nothing, cap; GUT all passed)
- [ ] The popup shows T-241's text word for word; AIR 180! and AIR 360! still pay as before alongside it (tests, screenshot) (QA: pass; popup reads HANG TIME! +0.2 in screenshot and GIF, matches docs/hud-and-menus.md Content; air_tricks tests pass, GUT all passed)
- [ ] The scaling numbers live in `game/data/combo.json` and are listed with their reasons in the result notes and Drifting, Content (QA: pass; airtime min_seconds/per_second/max_add in combo.json, reasons in result notes and docs/drifting.md 'Airtime trick (task T-242)')
- [ ] A GIF of a jump off a rooftop paying out is in `art-archive/T-242/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass; airtime_run.gif (72 frames: rooftop edge, fall, landing popup) present; GUT passed, tools 439 OK, game/tools 393 OK skipped=1)

The board's review: jump off rooftops and ramps and watch the airtime pay out.
Board review files: the GIF in `art-archive/T-242/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started.

### 2026-10-22, In progress → In QA

Airtime trick built: every landing after 0.3 s or more in the air pays HANG TIME! with an amount scaled by the airtime. Sent to QA.

### 2026-10-22, In QA → Needs playtest

QA passed all 4. Ready to play: jump off a rooftop and watch HANG TIME! on landing. Files: art-archive/T-242/screenshots/.

### 2026-10-22, Needs playtest → Done

The board played it in the T-229 build: good. Merging into master.

## Result notes

Written by the agent when it finishes.

Built: every landing after an airtime pays the airtime trick, popup "HANG TIME! +amount" (T-241's text word for word). The detector sums the `dt` of the steps in the air (`observe_air` got an optional third argument, `car.gd` passes `model.dt`) and emits a new `airtime_trick(seconds)` signal on the landing step, after AIR 180!/AIR 360!. It is not in `TRICK_IDS` and not on the `trick` signal, because its amount depends on the seconds (so T-246's changes to the drift's payout in the same files stay apart). `RunState.add_airtime_trick` and `ComboData.airtime_add` pay it. No driving changed.

Scaling proposal (`game/data/combo.json`, `airtime`; reasons in Drifting, Content, "Airtime trick"):
- `min_seconds` 0.3: curbs and tiny hops pay nothing.
- `per_second` 0.2: a rooftop fall (0.98 s) pays 0.20, a 0.7 s ramp hop 0.14; below an AIR 180! (0.25) since it asks for no steering.
- `max_add` 0.6: reached at 3 s, a little above an AIR 360! (0.5); not reachable on today's map (highest drop 1.0 s).
- Amount is the airtime to hundredths times per_second, rounded to hundredths. The popup shows the amount with `String.num(.., 2)`, so 0.2 reads "+0.2" like every other trick.

Tests: new `game/tests/unit/test_airtime_trick.gd` (two airtimes give different amounts, below the minimum pays nothing, the cap, numbers from combo.json, with an air 180, the run's combo and popup text); `test_air_tricks.gd`'s real-fall test now also expects the airtime amount. Full GUT suite 1302/1302, `tools` Python 439 OK, `game/tools` Python 393 OK (1 skipped).

Screenshots in `art-archive/T-242/screenshots/`: `airtime_run.gif` (a run off a height-6 rooftop, 0.98 s in the air over its shadow, lands to HANG TIME! +0.2) and `airtime_popup.png`. Fixture: `game/tests/fixtures/airtime_gif_run.tscn`.

Not done / for the Project Lead: the long GDD was not regenerated (merge step). One hook refusal: an inline `python -` command for the docs edit was refused (it contained `**`); I made the same docs edits with the Edit tool instead (no task file or status touched). The drift prototype shows no HANG TIME! popup (it has no combo); its detector counts it.

Documents affected: docs/drifting.md, game/README.md.
- 2026-10-22, needs-playtest → done: board's playtest: good (played in the T-229 build)
