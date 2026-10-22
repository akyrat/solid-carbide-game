---
id: T-266
title: The windshield wiper pushes minions about twice the car's length
status: open
from: project-lead
to: game-data
lead:
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/data/weapons.json, game/README.md, tasks/T-170-the-windshield-wiper-sweeps-in-front.md]
files_expected_to_change: [game/data/weapons.json, game/tests/, docs/weapons.md, game/README.md, art-archive/T-266/screenshots/]
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

The board's decision (Weapons, Decisions, "A stronger wiper push", 2026-10-22): when the windshield wiper is first picked up (tier 1), a minion it hits is pushed back about twice the car's size, taken as twice the car's length: **6 units** (the car is 1 unit wide and 3 long; today `knockback_distance` is 1.5). Change the number in `game/data/weapons.json`; the tiers keep their multipliers (tier 5 still x1.5), so the final tier pushes 9. The kaiju is still never pushed. If a 6-unit push needs the code to move the minion over several steps rather than at once (so it doesn't jump through a wall, boulder or off a ledge oddly), say so and do it; minions still stop at obstacles and fall off ledges as today. Update Weapons, Content (the wiper's numbers) and `game/README.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a short GIF of the wiper pushing minions at tier 1.

## Acceptance criteria

- [ ] `weapons.json` has the wiper's tier-1 push at 6 units, the tier multipliers unchanged (final 9); a test shows a minion hit at tier 1 ends about 6 units from where it was, and the kaiju is not pushed (QA: pass / fail)
- [ ] A pushed minion still stops at buildings and boulders and drops off ledges as before (tests) (QA: pass / fail)
- [ ] Weapons, Content, and `game/README.md` give the new numbers; the GIF is in `art-archive/T-266/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: pick up the wiper and watch minions fly.
Board review files: the GIF in `art-archive/T-266/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
