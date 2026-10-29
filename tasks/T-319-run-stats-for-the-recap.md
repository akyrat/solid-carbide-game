---
id: T-319
title: "The run keeps its stats for the recap: enemies slain, tricks, highest combo, weapons used"
status: in-qa
from: project-lead
to: game-loop
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/docs/game-loop/the-run.md, game/scripts/run/run_state.gd, game/scripts/run/run.gd, game/scripts/weapons/weapons.gd]
files_expected_to_change: [game/scripts/run/, game/tests/unit/run/, game/README.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "Recap screen in the MVP", 2026-10-28). T-320 builds the screen; this ticket gives it the numbers. Over a run, keep:

- **Enemies slain:** how many of each enemy type the car's weapons killed (minions, each kind there is, and the kaiju).
- **Tricks completed:** how many of each trick (every id the combo counts: drifts, 360s, alternate drifts, aerial tricks, airtime, thread the needle).
- **Highest combo multiplier** reached in the run.
- **Weapons used:** every weapon the car had during the run, with the tier it ended on; and the damage or kills each weapon did if it is cheap to count (a proposal: it makes the recap more interesting).

Expose them as one read-only summary the recap screen reads when the run ends (for example `run_state.recap()` returning a dictionary; your design), cleared when a new run starts. Nothing the player sees changes in this ticket.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] After a scripted run (tests), the summary has the right count per enemy type, per trick id, the highest multiplier and the weapons with their tiers. (QA: pass / fail)
- [ ] A new run starts with an empty summary (test). (QA: pass / fail)
- [ ] The summary is still readable after the run_ended signal, so a screen shown after the run can read it (test). (QA: pass / fail)
- [ ] Game loop architecture, Content and game/README.md describe the summary and its fields. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started overnight (build B, End of a run): the Game Loop Agent is making the run keep its stats for the recap.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (Game Loop Agent).** `RunState.recap()` returns a plain, JSON-ready Dictionary (a copy each call): live while the run goes, the final snapshot after `run_ended` (still readable until the next `start_run()` clears it). Fields: `result` (win/loss/""), `loss_reason` (time/health/""), `time_survived`, `coins`, `likes` (total XP gained), `level`, `enemies_slain` {type: kills}, `tricks` {id: count}, `highest_combo`, `weapons` {id: {tier, kills}}. T-360, T-320 and T-363 can use it as is.

My choices (the board is asleep): enemy types are "minion" and "kaiju" (`ENEMY_TYPE` const on each script); kills are credited to the weapon that struck the last blow (`take_damage(amount, source)`, the enemy keeps `last_hit_by`; bullet and molotov fire carry `weapon_id`); damage per weapon is not counted (kills only); weapons are the owned ones at the end, read through `state.weapons_source` (set by the rack, `Weapons.owned_tiers()`); the highest combo is tracked at every trick, so a crash cut does not lower it; tricks are counted by the id the combo uses, including airtime and thread_the_needle.

Changed: run_state.gd, minion.gd, kaiju.gd, minion_spawner.gd, kaiju_boss.gd, weapons.gd and the weapons' hit calls, bullet.gd, molotov_fire.gd. Test doubles of `take_damage` and the kaiju test's fake state were updated for the new signature. New tests: `game/tests/unit/run/test_run_recap.gd` (11). Docs: Game loop architecture (Content, "The run's stats for the recap"), `game/docs/game-loop/the-run.md`, `game/README.md`.

Tests (foreground): game/tools unittest 657 OK (1 skipped); tools unittest 573 OK; `bash game/tools/run_tests.sh` 1827/1827 passing. No screenshots: nothing the player sees changes.
