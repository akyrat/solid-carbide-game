---
id: T-414
title: Weapons during the wreck, and molotovs land where enemies can be
status: open
from: project-lead
to: weapon-behavior
lead: Preemptive-bug-bash
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-413]
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/weapons.gd, game/scripts/weapons/molotovs.gd, game/scripts/weapons/bricks.gd, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd]
files_expected_to_change: [game/scripts/weapons/weapons.gd, game/scripts/weapons/molotovs.gd]
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

Weapons, Decisions: "Weapons during the wreck" and "Molotovs land where enemies can be". Today no weapon is stepped while the run isn't going, so fires, burns and flame tints freeze and bullets hang in the air during the wreck. During the wreck: molotov fires and burning enemies keep going, the underglow keeps ticking, the bricks go off if the wrecked car lands; the gun, molotov throws, the wiper and the exhaust flamethrower fire nothing new. Also: weapons.gd checks the run only once per step, so after the kaiju's death ends the run, later weapons in the same step still kill minions; stop at the end of the run. A molotov landing inside a building or off the map (molotovs.gd random_landing) picks another spot.

The board's review: get wrecked with molotov fires burning and the underglow on, and see them keep damaging; jump, get wrecked in the air, and see the bricks go off on landing.

Part of the audit epic: the preemptive bug bash of 2026-10-30. A read-only audit of the game and its docs looked for situations the game can reach whose behaviour no doc decides, and for code holes, so they are fixed before they become bugs. Every ticket from it carries epic: audit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] During the wreck, a molotov fire and a burning enemy keep dealing damage, and the underglow keeps ticking (enemy health drops). (QA: pass / fail)
- [ ] During the wreck, a wrecked car landing from the air sets the bricks off. (QA: pass / fail)
- [ ] During the wreck, the gun, molotov throws, the wiper and the exhaust flamethrower fire nothing (no new bullets, bottles, wipes or flames). (QA: pass / fail)
- [ ] After the run ends (win or time up), no weapon damages anything later in the same step. (QA: pass / fail)
- [ ] Over 1000 throws on the board's level, no molotov lands inside a non-platform building or off the map. (QA: pass / fail)
- [ ] New headless tests cover each criterion below that describes behaviour, and all three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
