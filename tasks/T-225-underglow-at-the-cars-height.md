---
id: T-225
title: The neon underglow rises with the car on raised surfaces and in the air
status: in-qa
from: project-lead
to: weapon-behavior
lead: Coursework
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/drifting.md, game/README.md, tasks/T-206-run-on-the-elevation-sample-map.md]
files_expected_to_change: [game/scripts/weapons/, game/tests/unit/, game/README.md, docs/weapons.md, art-archive/T-225/screenshots/]
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

A bug the board found in a playtest (2026-10-21): on a raised surface (a rooftop or ramp on the elevation map, the run's map since T-206), the neon underglow ring stays drawn on the street instead of rising with the car, which "looks a bit funny". Draw the ring under the car at the car's height, the way T-206 lifted the exhaust flames (Weapons, Decisions, "The flamethrower at height"), on rooftops, ramps and in the air, and in the right depth order next to the raised areas. How it should look in the air (under the car, or on the ground below with the round shadow) is your proposal for the playtest, in the result notes.

Its damage area stays as it is today unless that is plainly broken at height; if enemies at another level are hurt or missed in a way that looks wrong, say so in the result notes as a proposal rather than changing it. Check the molotov fire and the wiper too: if either has the same bug, fix it the same way and say so.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with screenshots of the underglow on a rooftop and a ramp in a run (`tasks/README.md`, "Screenshots").

## Acceptance criteria

- [ ] On a rooftop, a ramp and (as proposed) in the air, the underglow is drawn under the car at its height, in the right depth order (tests, and screenshots in a run) (QA: pass; rooftop, ramp and air screenshots show the ring under the car at its height, car drawn over roof, tests added)
- [ ] On the street the underglow looks and works as before (tests) (QA: pass; street screenshot shows ring round the car on the ground, street test added)
- [ ] The result notes say whether the molotov fire and the wiper had the same bug, and what was done (QA: pass; wiper fixed, molotov is ground fire so no bug)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass; GUT TESTS PASSED, tools 439 OK, game/tools 387 OK, 1 skipped)

The board's review: drive onto a rooftop with the underglow.
Board review files: the screenshots in `art-archive/T-225/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Open → In progress

Started: the underglow rises with the car.

### 2026-10-21, In progress → In QA

Fixed: the underglow (and the wiper, which had the same bug) rise with the car. Sent to QA.

## Result notes

Written by the agent when it finishes.

- **Fix:** `neon_underglow.gd` now lifts its ring by the car's height (`car_height()`, position minus `height * 16` px), the same way T-206 lifted the exhaust flames. The ring sits in the car's `View` under the car sprite, so it shares the car's depth order with the raised areas (the View's z is set from the car's height).
- **Molotov fire and wiper:** the wiper had the same bug (its arm stayed on the street) and is fixed the same way (`windshield_wiper.gd`). The molotov fire is a ground fire where the bottle lands, not attached to the car, so it has no such bug; left as is.
- **Damage area:** unchanged (a flat circle round the car's ground position); a test checks it at height. Proposal: enemies on another level (e.g. street enemies while the car is on a roof) are hit by the same flat circle; that is not plainly broken, so not changed.
- **Proposals for the playtest:** in the air the ring stays under the car (rises with it) rather than staying on the ground with the round shadow; the wiper's arm rises with the car too.
- **Tests:** 7 new GUT tests in `game/tests/unit/run/test_run_elevation_map.gd` (street, both rooftops, air, damage area, wiper). GUT 1238 passed; `tools` unittest 439 OK; `game/tools` unittest 387 OK (1 skipped).
- **Screenshots** (`art-archive/T-225/screenshots/`): `underglow_street.png`, `underglow_rooftop.png`, `underglow_ramp.png`, `underglow_air.png`. Fixtures `run_elevation_underglow_*.tscn`.
- **Documents:** `docs/weapons.md`, `game/README.md`. No refused commands.
