---
id: T-424
title: The in-run wreck-revive test is flaky: other weapons and minions change hearts, coins and the pickup
status: in-progress
from: project-lead
to: game-loop
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: []
files_to_read_first: [tasks/README.md, game/tests/unit/run/test_wreck.gd, tasks/T-406-wreck-health-revive.md, tasks/T-408-gun-one-shot-and-targets.md]
files_expected_to_change: [game/tests/unit/run/test_wreck.gd]
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

Bug in a test, not in the game. `game/tests/unit/run/test_wreck.gd`, `test_in_the_run_a_sliding_wreck_picks_up_a_health_pickup_and_drives_again` (from T-406) fails at random on master: 6 of 14 runs on a plain master checkout (found by the weapon-behavior agent on T-409, 2026-10-30), with a different assert each time (hearts 5 vs 1, coins 5 vs 0, the pickup not collected, a loss recorded). It plays a real Run scene, where the starting gun (stronger since T-408: one-shots, more bullets and targets) kills random minions near the wreck, and their drops change the hearts, the coins or the pickup the test watches. It has stopped three merges into master today (T-380, T-409, T-404).

Make the test deterministic: keep the run real (the wreck, the slide, the pickup and the revive go through the game's own code), but take out what the test isn't about, for example no minions spawned and no weapon firing during it, using whatever the run already offers for tests (seeded spawner, playtest switches, a test fixture) rather than new game code. If that can't be done without changing game code, stop and say what you'd change. Don't change what the test checks.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The root cause is in the result notes: what changed the hearts, coins or pickup during the test. (QA: pass / fail)
- [ ] `test_wreck.gd` passes 20 runs in a row of its own file (`bash game/tools/run_tests.sh` with the file, or the GUT command for one file), the count written in the result notes. (QA: pass / fail)
- [ ] The test still asserts what it did before: the sliding wreck picks up the health pickup, revives with 1 heart and drives again (the asserts are kept or made stricter, none removed). (QA: pass / fail)
- [ ] No game code changes, or, if any were needed, the agent stopped and asked first (result notes). (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started: the flaky wreck-revive test has stopped three merges today, so it goes first.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Root cause: the test plays a real Run scene, and the run's starting gun (stronger since T-408) and the minion spawner were live during the 40 + 90 physics frames. Gun kills dropped coins and hearts (changing coins, hearts, or which pickup the magnet pulled) and minion bodies hit the car (damage, a loss recorded).
Fix (test only, no game code): right after the run is added, `run.minions.enabled = false` and `run.weapons.enabled = false` (switches the run already has, used by the fixtures). Everything else stays real; no assert removed or changed.
Checks: test_wreck.gd alone, 20 runs in a row: 20 of 20 passed (23 tests each). All three sets pass: game/tools python unittest OK, tools python unittest OK (579 tests), GUT 2067/2067.
Changed: game/tests/unit/run/test_wreck.gd. Documents affected: none.
