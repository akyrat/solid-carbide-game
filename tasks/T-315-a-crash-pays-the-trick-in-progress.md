---
id: T-315
title: A crash that breaks the combo still pays the trick in progress
status: open
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

The board's decision (Game loop architecture, Decisions, "A crash pays the trick in progress", 2026-10-28): when a crash breaks the combo (hitting a wall, a building, a boulder, the map's edge or taking damage: `run_state.gd` `collision()`, the COMBO BROKEN! popup), the player still gets the trick they were doing up to that moment, instead of losing it.

Today a drift pays once, when it ends (Drifting, Decisions, "Drift pays once, at its end"); a crash in the middle of a drift loses it. With this change, a drift that a crash interrupts pays its `extended_drift` trick for the time it lasted until the crash, with its LONG DRIFT! popup and amount, and the XP from its seconds as today. Look for any other trick that builds up over time and can be cut by a crash (an aerial spin under way, for example) and treat it the same way, or say in the result notes why it doesn't apply.

**The order (a proposal for the board's playtest):** the trick pays first, then the crash cuts the combo by 80% as it does today, so its popup shows just before COMBO BROKEN!. Say in the result notes how this feels and offer the other order (cut first, then pay) as a tuning switch if it is cheap.

The board's review: drift into a wall and check the drift still pays its LONG DRIFT! before COMBO BROKEN!.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A drift interrupted by a crash pays one extended_drift trick scaled by the time it lasted until the crash, with its popup, before the combo is cut (tests: a wall hit, a boulder hit and an enemy hit during a drift). (QA: pass / fail)
- [ ] A drift that ends normally pays exactly as before, and a crash with no trick in progress behaves exactly as before (tests). (QA: pass / fail)
- [ ] The result notes list every trick checked for this, with what changed or why it doesn't apply. (QA: pass / fail)
- [ ] Drifting, Content and game/README.md describe the change and the order. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-315/screenshots/`, as `tasks/README.md`, "Screenshots", asks. A GIF shows a drift ending in a crash, with its LONG DRIFT! popup and COMBO BROKEN!. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
