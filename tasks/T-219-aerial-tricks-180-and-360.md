---
id: T-219
title: "Aerial tricks: a 180 and a 360 turned in the air"
status: blocked
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-218]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md, game/scripts/driving/trick_detector.gd, game/scripts/data/combo_data.gd, game/scripts/hud/trick_popups.gd, tasks/T-218-text-aerial-trick-popups.md]
files_expected_to_change: [game/scripts/driving/trick_detector.gd, game/data/, game/scripts/hud/, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-219/screenshots/]
model: opus
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

The board's first aerial tricks (Drifting, Decisions, "Aerial tricks", 2026-10-21): while the car is airborne (off a ramp or a rooftop's edge, on the elevation map that the run now plays on), turning its heading **180 degrees** during one airtime is the 180 trick, and turning it a **full 360** is the 360 trick. Direction doesn't matter: a left and a right turn are the same trick.

Detect them in `trick_detector.gd` from the car's heading and its airborne state (`car_height.gd`), alongside the existing ground tricks, and feed them into the existing combo (how tricks raise it: Game loop architecture, Decisions; the numbers live in the combo data) and the existing trick popups, with T-218's texts word for word (HUD and menus, Content). Proposals for the playtest, written in the result notes and in Drifting, Content: what each is worth, whether a 360 also counts its 180 or only the 360, what a 540 or 720 gives, whether the turn must be finished before landing, and how an air turn interacts with a drift 360 that spans the jump. Don't change how the car drives or turns in the air.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots and a short GIF of each trick in a run (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] Tests show a 180 turn during one airtime gives the 180 trick, and a full turn the 360 trick, the same for left and right turns; a smaller turn, or the same turn on the ground, gives neither (QA: pass / fail)
- [ ] Each aerial trick raises the combo through the existing combo data and shows its popup with T-218's text word for word (tests, and a screenshot of each popup in a run) (QA: pass / fail)
- [ ] A GIF of each trick in a run on the elevation map is in `art-archive/T-219/screenshots/` (QA: pass / fail)
- [ ] The car's driving and air steering are unchanged (existing driving tests pass unchanged); the proposals are in the result notes and Drifting, Content (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run and do both aerial tricks off the rooftops and ramps.
Board review files: the GIFs in `art-archive/T-219/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
