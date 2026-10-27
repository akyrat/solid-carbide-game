---
id: T-315
title: A crash that breaks the combo still pays the trick in progress
status: done
from: project-lead
to: driving-drift
lead: Greenbull
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, game/README.md, game/scripts/run/run_state.gd, game/data/combo.json]
files_expected_to_change: [game/scripts/driving/, game/scripts/run/run_state.gd, game/tests/unit/, game/README.md, docs/drifting.md, docs/game-loop-architecture.md]
model: opus
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

The board's decision (Game loop architecture, Decisions, "A crash pays the trick in progress", 2026-10-28): when a crash breaks the combo (hitting a wall, a building, a boulder, the map's edge or taking damage: `run_state.gd` `collision()`, the COMBO BROKEN! popup), the player still gets the trick they were doing up to that moment, instead of losing it.

Today a drift pays once, when it ends (Drifting, Decisions, "Drift pays once, at its end"); a crash in the middle of a drift loses it. With this change, a drift that a crash interrupts pays its `extended_drift` trick for the time it lasted until the crash, with its LONG DRIFT! popup and amount, and the XP from its seconds as today. Look for any other trick that builds up over time and can be cut by a crash (an aerial spin under way, for example) and treat it the same way, or say in the result notes why it doesn't apply.

**The order (a proposal for the board's playtest):** the trick pays first, then the crash cuts the combo by 80% as it does today, so its popup shows just before COMBO BROKEN!. Say in the result notes how this feels and offer the other order (cut first, then pay) as a tuning switch if it is cheap.

The board's review: drift into a wall and check the drift still pays its LONG DRIFT! before COMBO BROKEN!.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A drift interrupted by a crash pays one extended_drift trick scaled by the time it lasted until the crash, with its popup, before the combo is cut (tests: a wall hit, a boulder hit and an enemy hit during a drift). (QA: PASS: test_crash_pays_trick.gd covers wall, boulder and enemy hit; LONG DRIFT! comes before COMBO BROKEN!)
- [ ] A drift that ends normally pays exactly as before, and a crash with no trick in progress behaves exactly as before (tests). (QA: PASS: normal drift end and no-trick crash tests present and green)
- [ ] The result notes list every trick checked for this, with what changed or why it doesn't apply. (QA: PASS: extended drift, air spins, airtime, 360, alt drift, thread the needle all listed)
- [ ] Drifting, Content and game/README.md describe the change and the order. (QA: PASS: all three docs updated, order and switch described)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-315/screenshots/`, as `tasks/README.md`, "Screenshots", asks. A GIF shows a drift ending in a crash, with its LONG DRIFT! popup and COMBO BROKEN!. (QA: PASS: GIF and PNG present; PNG shows LONG DRIFT! +0.09 under COMBO BROKEN!)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: PASS: 620 OK, 501 OK, GUT 143 scripts 1705/1705; one first GUT run exited 1 while run in parallel with the other sets, a clean rerun passed)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Started: the Driving & Drift Agent is making a crash pay the drift in progress before the combo is cut.

### 2026-10-27, In progress → In QA

Built: a crash now pays the drift (and air spins, hang time) in progress before COMBO BROKEN!. QA is checking it.

### 2026-10-27, In QA → Needs playtest

QA passed all 6 criteria. Ready for your playtest: C:\solid-carbide-worktrees\T-315\game\project.godot, or Play on T-315 in the Builds tab.

### 2026-10-27, Needs playtest → Done

Approved after the board's playtest of batch-1028; merging to master.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Driving & Drift Agent, 2026-10-27.**

What changed:
- `game/scripts/run/run_state.gd`: new signal `crashed`, sent from `collision()` (wall, building, boulder, map edge, raised-ground side, and any damage, since `damage_car()` calls it) while the run is going. By default it fires before the 80% cut, so the trick in progress pays first.
- `game/scripts/driving/trick_detector.gd`: `settle()` pays what is in progress as if it ended now: the drift so far (one `extended_drift` with `last_trick_seconds` = the time until the crash; the drift's time then restarts from zero, so the rest of a drift that goes on after the crash pays on its own) and, in the air, the spins and airtime so far (the rest of the airtime counts from the crash). A drift under `drift_pay.min_seconds`, or an airtime under `airtime.min_seconds` with no half turn, is left alone, so a crash with no trick in progress behaves exactly as before.
- `game/scripts/driving/car.gd`: `settle_tricks()` (calls `tricks.settle()` when detection is on). `game/scripts/run/run.gd`: connects `state.crashed` to it.
- `game/data/combo.json` + `ComboData`: `crash_pays_trick_first` (true, the board's order) and `airtime_min_seconds()`. The tuning switch for the other order is in: `false` cuts first, then adds the trick to the cut combo.

Every trick checked:
- **extended_drift (LONG DRIFT!):** changed, as above.
- **air_one_eighty / air_three_sixty (AIR 180! / AIR 360!):** changed: an aerial spin under way pays its completed half turns at a crash in the air.
- **airtime (HANG TIME!):** changed: the airtime so far pays at a crash in the air; the rest of the fall pays on landing.
- **three_sixty (FULL 360!):** doesn't apply: it pays the moment the full turn completes, so a crash never cuts a 360 that would have paid; a partial turn is not a trick and keeps counting as before.
- **alternate_drift (ALT DRIFT!):** doesn't apply: it pays the moment the switch completes (the new drift reaching its shortest time); nothing builds up.
- **thread_the_needle:** doesn't apply: not built over time (it pays clear_seconds after the crossing), and a touch of either obstacle voiding the pass is the board's own rule (Level design, Decisions); other crashes don't touch it.
- The XP from drifting seconds is unchanged (paid second by second while drifting).

How the order feels (my note for the playtest): paying first reads as cause and effect: LONG DRIFT! pops, then COMBO BROKEN! stacks over it, both at once at the car (see the GIF). The trade-off: the cut also takes 80% of the drift's amount, so the drift is worth little after a crash (a 1.72 s drift from x2.0 ends at x1.22; cut first it would be x1.29). Cheap to flip: `crash_pays_trick_first: false` in `combo.json`. One more effect: a drift with no combo before it now gives a combo, so a crash during a long drift from x1.0 now shows COMBO BROKEN! where before it showed nothing.

Open point for the playtest (not changed, HUD and menus' area): the HUD's drift counter (T-247) keeps counting the whole drift through a crash, while the paid part restarts from zero at the crash.

Tests: `game/tests/unit/run/test_crash_pays_trick.gd`, 17 tests: the detector's settle() (drift, too-short drift, partial 360, normal end, in the air with a spin, short airtime), and in the run scene a real wall hit, a real boulder hit and an enemy hit (`damage_car`) during a drift (LONG DRIFT! then COMBO BROKEN!, combo = cut of (combo + drift amount)), the rest of the drift paying on its own, a drift from no combo, the other order, a crash with no trick in progress, a normal drift end, and the drift XP.

Test sets (all pass): `python -m unittest discover -s game/tools -p "test_*.py"`: 620 tests OK (1 skipped). `python -m unittest discover -s tools -p "test_*.py"`: 501 tests OK. `bash game/tools/run_tests.sh`: 143 scripts, 1705/1705 passing.

Screenshots: `art-archive/T-315/screenshots/drift_into_boulder_pays_then_breaks.gif` (a run from the main menu at x2.0, a 1.72 s drift into a boulder: LONG DRIFT! +0.09 then COMBO BROKEN!, the counter goes x2.0 to x1.22) and `art-archive/T-315/screenshots/crash_pays_popups.png` (the two popups stacked, 8 frames after the hit). Fixture: `game/tests/fixtures/crash_pays_gif.tscn` (how to record: `game/README.md`, "A crash pays the trick in progress (T-315)").

Skipped: the fixture script's `.uid` file (`crash_pays_gif_demo.gd.uid`) was not generated: the `--import` run was refused by the ticket guard hook (it can't tell a `timeout`-wrapped command won't write a ticket). Godot makes it the next time the project is imported or opened; nothing depends on it.

Documents affected: `docs/drifting.md` (Content, "A crash pays the trick in progress (task T-315)"), `docs/game-loop-architecture.md` (Content, "The combo"), `game/README.md` ("Tricks", new subsection, and the combo broken popup note).
- 2026-10-27, needs-playtest → done: The board played batch-1028 and approved it.
