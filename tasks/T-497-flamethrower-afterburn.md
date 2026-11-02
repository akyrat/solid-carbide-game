---
id: T-497
title: Hot Take Exhaust afterburn: burning enemies keep taking damage
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-496]
documents_affected: [docs/weapons.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/scripts/weapons/flamethrower/exhaust_flamethrower.gd, game/docs/weapons/flamethrower.md]
files_expected_to_change: [game/scripts/weapons/flamethrower/, game/tests/unit/, docs/weapons.md, game/docs/weapons/flamethrower.md]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-02 (docs/weapons.md, Decisions, "The board's own upgrade trees"): the flamethrower's burn time becomes real afterburn. Today an enemy hit by the flame flashes orange for burn_flash_seconds and takes damage only while inside the flame. Now an enemy that leaves the flame keeps taking the flame's damage (its current damage, after upgrades) every tick_interval for its burn time, while the orange tint and the burn flames on it show. Re-entering the flame refreshes the burn time; an enemy never takes more than one flame hit per tick (inside the flame or burning, not both). Tiers 5 and 7 (+1 s each, T-496's data) lengthen it. The weapons-during-the-wreck rule holds: burns already on enemies keep going. Explain the behaviour in game/docs/weapons/flamethrower.md and docs/weapons.md Content (the exhaust flamethrower). Never write, move or commit anything in game/data/levels/. SFX stay off.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A unit test: an enemy that leaves the flame at tier 1 takes the flame's damage every tick_interval for burn_flash_seconds, then stops. (QA: pass / fail)
- [ ] A unit test: with burn +2 s (tier 7) the same enemy keeps taking damage for burn_flash_seconds + 2 s. (QA: pass / fail)
- [ ] A unit test: an enemy inside the flame and burning takes one hit per tick, not two. (QA: pass / fail)
- [ ] A unit test: re-entering the flame refreshes the burn time. (QA: pass / fail)
- [ ] The orange tint and burn flames stay on for exactly the burn time (unit test). (QA: pass / fail)
- [ ] docs/weapons.md (the exhaust flamethrower) and game/docs/weapons/flamethrower.md describe the afterburn. (QA: pass / fail)
- [ ] The full Godot test set passes in QA; the agent runs only the test files it touched. (QA: pass / fail)
- [ ] Screenshots of burning minions outside the flame, under art-archive/T-NNN/screenshots/. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
