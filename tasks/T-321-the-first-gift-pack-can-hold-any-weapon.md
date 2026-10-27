---
id: T-321
title: The first gift pack offers two random choices from every weapon
status: open
from: project-lead
to: weapon-behavior
lead: Greenbull
epic: weapons
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/weapons.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/weapons.md, game/README.md, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/scripts/weapons/level_up_offers.gd, game/tests/unit/, game/README.md, docs/weapons.md]
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

The board's decision (Weapons, Decisions, "The first gift pack can hold any weapon", 2026-10-28): the first level-up no longer offers the fixed "upgrade the gun" or "get the flamethrower" (`level_up_offers.gd` `FIRST_OFFERS`, `is_first_offer()`). It draws its two choices at random from every choice available, like every later level-up (Weapons, Decisions, "Level-up offers with five weapons"): getting any weapon the car doesn't have, or upgrading the gun. Remove the fixed first offer, its tests and its mentions in the docs (Weapons, Content, "The level-up offers"; game/README.md), and keep the seeded draw so tests stay repeatable.

The board's review: start a few runs and check the first gift pack offers different weapons.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Over many seeded first level-ups, every available first choice appears (each of the four weapons the car doesn't have, and the gun upgrade), always two different ones (test). (QA: pass / fail)
- [ ] No code path offers the old fixed pair on purpose any more: FIRST_OFFERS and is_first_offer are gone or no longer used (QA reads the diff). (QA: pass / fail)
- [ ] Later level-ups draw exactly as before (the existing tests pass unchanged, or the result notes say why one changed). (QA: pass / fail)
- [ ] Weapons, Content, "The level-up offers" and game/README.md describe the new first offer. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-321/screenshots/`, as `tasks/README.md`, "Screenshots", asks. Two first level-ups with different offers. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
