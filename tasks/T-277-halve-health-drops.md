---
id: T-277
title: Health drops at half the rate
status: open
from: project-lead
to: game-data
lead:
epic: enemies
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
depends_on: []
documents_affected: [docs/enemies.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/enemies.md, game/data/enemies.json, game/README.md, tasks/T-220-health-drops.md]
files_expected_to_change: [game/data/enemies.json, game/tests/, docs/enemies.md, game/README.md]
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

The board's decision (Enemies, Decisions, "Health drops", halved, 2026-10-22): a killed minion drops a health pickup at half today's rate: `health_drops.drop_chance` in `game/data/enemies.json` from 0.6 to **0.3**. The coins' drop rate is unchanged (it no longer has to match), and so is what a pickup restores (30%). Update the data's comment, any test that assumed the two rates are equal, Enemies, Content, and `game/README.md`.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes. Nothing to picture: the result notes say so in one line.

## Acceptance criteria

- [ ] `drop_chance` is 0.3 and a test over many kills shows health drops at about half the coins' rate; the coins' rate and the restore amount are unchanged (QA: pass / fail)
- [ ] Enemies, Content, and `game/README.md` give the new rate; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: play a run and notice fewer health pickups.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Result notes

Written by the agent when it finishes.
