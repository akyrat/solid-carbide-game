---
id: T-267
title: A smaller exhaust flame, drawn behind the car and enemies, that burns whatever touches it
status: open
from: project-lead
to: weapon-behavior
lead: Coursework
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/data/weapons.json, game/README.md, tasks/T-042-exhaust-flamethrower.md, tasks/T-071-weapon-effects-art.md]
files_expected_to_change: [game/data/weapons.json, game/scripts/weapons/, game/scenes/weapons/, game/tests/, docs/weapons.md, game/README.md, art-archive/T-267/screenshots/]
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

The board's decision (Weapons, Decisions, "A smaller exhaust flame that burns what it touches", 2026-10-22). In playtests the exhaust flame looks too big, shows on top of enemies, and doesn't reliably hurt what it seems to touch; the board feels the hit area is much smaller than the drawn flame.

1. **Smaller at the start:** at tier 1 the flame is drawn 4 to 5 times smaller than today in length and width (propose the exact factor, about a quarter, in `game/data/weapons.json`); the size tiers grow it from there as before, and the ramp-up over the first second of a drift stays.
2. **Behind:** the flame is drawn behind the car and behind every enemy, never over them, on the street, on rooftops and in the air (Decisions, "The flamethrower at height").
3. **Hit area = drawn flame:** the damage area is the flame as it is drawn at every moment (size, ramp-up, direction, tier), so a minion takes damage as soon as any part of it touches the visible flame (replacing "its centre"); the kaiju as before (any overlap). Find and explain in the result notes why the hit area and the art differ today.

Damage numbers and timing are unchanged. Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. End with a screenshot showing the flame behind a minion with its hit area outlined (debug draw in a fixture only), and a short GIF of a drift through minions at tier 1.

## Acceptance criteria

- [ ] At tier 1 the drawn flame and its hit area are the proposed fraction of today's size (about a quarter), and grow with the size tiers as before (tests) (QA: pass / fail)
- [ ] Tests show the hit area matches the drawn flame through the ramp-up and in every direction, and a minion whose edge (not centre) touches the flame takes damage (QA: pass / fail)
- [ ] The flame draws behind the car and behind enemies (a depth test and the screenshot) (QA: pass / fail)
- [ ] Weapons, Content and `game/README.md` give the new numbers and rule; the screenshot and GIF are in `art-archive/T-267/screenshots/`; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: drift through minions with the flamethrower at its first level.
Board review files: the screenshot and GIF in `art-archive/T-267/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
