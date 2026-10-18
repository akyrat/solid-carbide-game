---
id: T-176
title: QA: the five weapons, the random offers and the card images together in a run
status: blocked
from: project-lead
to: qa-integration
lead: Goal-G-002
epic: weapons
milestone: mvp
goal: G-002
user_facing_text: no
changes_visuals: no
depends_on: [T-172, T-173, T-174, T-175]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/weapons.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md, game/data/playtest.json, game/scripts/weapons/level_up_offers.gd]
files_expected_to_change: [game/tests/unit/weapons/test_all_weapons_run.gd]
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

Check the goal's work together before the board's single playtest of `playtest/G-002`. Run the game from the main menu with all five weapons owned (the `all_weapons_at_start` playtest switch from D7, set only in the test, never committed as true) headless for 60 seconds. Drive a run through repeated level-ups until several weapons reach tier 8, checking no repeated or maxed choice is offered. Run all three test sets and the staleness check. Write a test for the repeated level-up run so it can be rerun. Report results per criterion; fix nothing in game code yourself.

## Acceptance criteria

- [ ] A run started from the main menu with all five weapons owned runs headless for 60 seconds with no script errors in the log. (QA: pass / fail)
- [ ] A test levels a run up repeatedly until at least three weapons reach tier 8, with no offer ever holding the same id twice or a choice for a weapon at tier 8, and no error. (QA: pass / fail)
- [ ] The game's tests, the tools tests and the docs checks all pass, and the staleness check reports nothing stale after the long GDD and the short GDD fingerprint are regenerated. (QA: pass / fail)
- [ ] `data/playtest.json` as committed has every switch false. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
