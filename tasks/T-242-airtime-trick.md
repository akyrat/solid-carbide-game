---
id: T-242
title: The airtime trick, paying out on landing by how long the car was in the air
status: blocked
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

The board's new trick (Drifting, Decisions, "Airtime trick", 2026-10-21): every time the car is off the ground, its airtime is a trick of its own. On landing it pays a combo amount that scales with how long the car was in the air, in seconds and hundredths, through the existing combo (Game loop architecture, Decisions) and the existing trick popups, with T-241's text word for word. It counts alongside AIR 180! and AIR 360! (T-219). Propose reasonable defaults for the playtest, as tuning numbers in `game/data/combo.json`: the scaling (for example an amount per second, a minimum airtime below which nothing pays, and a cap), and how it sits next to the aerial tricks' amounts. Detect it from the car's airborne state in `trick_detector.gd`, the same way T-219 does. Don't change how the car drives. The live counter while airborne is T-243's.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot of the popup and a short GIF of a jump paying out (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show a landing after an airtime pays the airtime trick, with the amount the data's scaling gives for that airtime (two different airtimes give the expected different amounts), and that airtime below the minimum pays nothing (QA: pass / fail)
- [ ] The popup shows T-241's text word for word; AIR 180! and AIR 360! still pay as before alongside it (tests, screenshot) (QA: pass / fail)
- [ ] The scaling numbers live in `game/data/combo.json` and are listed with their reasons in the result notes and Drifting, Content (QA: pass / fail)
- [ ] A GIF of a jump off a rooftop paying out is in `art-archive/T-242/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: jump off rooftops and ramps and watch the airtime pay out.
Board review files: the GIF in `art-archive/T-242/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
