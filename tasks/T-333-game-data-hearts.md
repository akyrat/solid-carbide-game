---
id: T-333
title: "Game data: hearts, damage in hearts, invulnerability, health drops and the garage upgrade"
status: open
from: project-lead
to: game-data
lead: Greenbull
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md, game/data/run.json, game/data/, game/scripts/data/]
files_expected_to_change: [game/data/, game/scripts/data/, game/tests/unit/, game/README.md, docs/game-loop-architecture.md, docs/enemies.md, docs/garage-design.md]
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

The board's decisions (2026-10-28): Game loop architecture, Decisions, "Hearts instead of health points"; Enemies, Decisions, "Damage in hearts, fewer health drops, bolder outlines"; Garage design, Decisions, "The car health upgrade adds hearts". Put the numbers in the game's data, read through its data scripts (T-334 builds the behaviour):

- The car starts with **5 hearts** (today `run.json` `car.starting_health` 100).
- Damage in hearts: a **minion's hit 1**, a **meteor 1**, the **kaiju's 2** (today 5, 15 and 20 health; find each in the data).
- **Invulnerability after a hit: 1 second**, and the blink's rate (a proposal).
- **Health pickups:** drop chance **15%** (half today's 30%), each heals **1 heart**, never above the maximum.
- **The garage car health upgrade:** **+1 heart per level** (find its data; keep its level count and costs unless they no longer make sense, and say so).
- Remove or retire the numbers that no longer apply (the contact repeat every 0.5 s, the 30% heal), saying in the result notes where each went.

The board's review: none needed (data); judged in the HUD playtest.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The data has: 5 starting hearts; damage 1 (minion), 1 (meteor), 2 (kaiju); 1 s invulnerability; health pickups at 15% healing 1 heart; +1 heart per garage level, each read through the data scripts (tests that load them). (QA: pass / fail)
- [ ] The result notes list every old health number and what replaced it or why it is gone. (QA: pass / fail)
- [ ] Game loop architecture, Enemies and Garage design Content, and game/README.md list the new numbers. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
