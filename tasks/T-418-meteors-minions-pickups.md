---
id: T-418
title: Meteors hit minions and push pickups aside
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
files_to_read_first: [tasks/README.md, docs/enemies.md, game/scripts/enemies/kaiju_meteors.gd, game/scripts/enemies/enemy_data.gd, game/scripts/enemies/minion_spawner.gd]
files_expected_to_change: [game/scripts/enemies/kaiju_meteors.gd, game/scripts/enemies/enemy_data.gd, game/scripts/enemies/minion_spawner.gd]
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

Enemies, Decisions: "Meteors hit minions and push pickups aside". Today a boulder appears around any minion, coin or health pickup on its spot (kaiju_meteors.gd _blocked_by_body checks only the car and the kaiju), meteors never damage minions, and a meteor hits a car jumping over it (only the flat distance is checked). Also two data guards: enemy_data.gd meteor_attack_times() loops forever if seconds_between_attacks is 0 or less; minion_spawner.gd reads spawn_interval_seconds without a default. Refuse or clamp bad values with a clear error.

The board's review: during the kaiju fight, see meteors kill minions and push coins out from under the boulders.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A meteor landing on a minion damages it (minion health drops). (QA: pass / fail)
- [ ] A coin or health pickup on a boulder's spot ends up outside the boulder, still collectable. (QA: pass / fail)
- [ ] A car more than 1 unit above a landing meteor takes no damage; at the same level it does. (QA: pass / fail)
- [ ] seconds_between_attacks of 0 doesn't hang (the test finishes) and reports an error; a missing spawn_interval_seconds uses the default. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
