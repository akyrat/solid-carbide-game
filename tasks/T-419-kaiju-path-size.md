---
id: T-419
title: The kaiju only takes paths it fits through
status: open
from: project-lead
to: enemy-behavior
lead: Preemptive-bug-bash
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/kaiju_boss.gd, game/scripts/enemies/kaiju.gd, game/scripts/enemies/enemy_path_follower.gd, tasks/T-379-minions-twice-as-big.md]
files_expected_to_change: [game/scripts/enemies/enemy_navigation.gd, game/scripts/enemies/kaiju_boss.gd]
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

Enemies, Decisions: "The kaiju only takes paths it fits through". Bug: enemy_navigation.gd closes cells only 0.5 units around buildings (BUILDING_MARGIN, CELL 2.0), sized for minions, but the kaiju's radius is 2.0. Its path goes through gaps it can't fit and to waypoints under 1 unit from a wall, which it can never reach (REACH 1.0), so it slides on the wall and re-plans every second, mostly when the car is on a rooftop. Plan per body size. T-379 (open, another session) doubles the minions' size and will need the same; build it so the size comes from each enemy.

The board's review: stand on a rooftop on the board's level while the kaiju is out, and see it walk round buildings without getting stuck.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] On the board's level, every waypoint of the kaiju's planned path is at least its radius from every building (test over 50 start/target pairs). (QA: pass / fail)
- [ ] A gap narrower than the kaiju's diameter is never on its path; minions still use it. (QA: pass / fail)
- [ ] In a scripted run, the kaiju reaches a target behind two buildings within 30 s without stopping for more than 2 s. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
