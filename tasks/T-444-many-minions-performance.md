---
id: T-444
title: The game stays fast with a crowd of minions
status: open
from: project-lead
to: enemy-behavior
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: [T-443]
documents_affected: [game/docs/enemies/minions.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/docs/enemies/minions.md, game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/enemy_path_follower.gd]
files_expected_to_change: [game/scripts/enemies/, game/tools/, game/tests/unit/, game/docs/enemies/minions.md]
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

The board, 2026-10-31 (docs/enemies.md, Decisions, "Minions spawn on a timer, and 30% slower"): with minions on a constant timer (T-443), many more will be alive at once, and the game must not slow down much.

1. Write a repeatable measurement script (in game/tools/, run headless) that starts a run on the game's map (Kaiju City), holds a given number of minions alive around the car (for example 50, 100, 200, 300) and reports the average and worst physics and frame times. Run it before changing anything and put the numbers in the result notes.
2. Find where the time goes (path finding, path following, separation between minions, depth sorting, collisions, per-frame allocations, signals) and optimise the biggest costs: for example sharing or caching paths, re-planning less often, spreading work over frames, cheaper neighbour checks. Behaviour stays the same as the player sees it: minions still find their way round buildings and boulders, up ramps and off ledges, and hit the car as today.
3. Run the script again after the changes and put the before and after numbers side by side in the result notes, with what each change bought.

No gameplay or numbers change in this ticket. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A measurement script in game/tools/ reports the average and worst frame times with a given number of minions alive on Kaiju City, and is documented in game/docs/enemies/minions.md with how to run it. (QA: pass / fail)
- [ ] The result notes have before and after numbers for at least 50, 100 and 200 minions, and the after numbers are lower for 100 and 200. (QA: pass / fail)
- [ ] The existing enemy navigation, falling, ramp and contact tests still pass unchanged (minions behave as before). (QA: pass / fail)
- [ ] A test (or the script's own check) covers each optimisation that changes when work happens (for example cached paths stay correct when the car moves). (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
