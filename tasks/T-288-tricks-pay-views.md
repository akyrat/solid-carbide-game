---
id: T-288
title: "Each trick pays views, multiplied by the combo"
status: planning
from: project-lead
to: game-loop
lead: Coursework
epic: game-loop
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-287]
documents_affected: [docs/game-loop-architecture.md, docs/drifting.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md, game/scripts/run/run_state.gd, game/data/combo.json, game/data/run.json, tasks/T-287-text-views-instead-of-likes.md]
files_expected_to_change: [game/scripts/run/, game/data/, game/tests/, docs/game-loop-architecture.md, docs/drifting.md]
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

**On hold: needs refining before work starts (board, 2026-10-25).**

The board's playtest note on the game build (2026-10-24). How it works today (`run_state.gd`):
- Only drifting earns likes: each full second of a drift pays `drift_xp_per_second`, multiplied by the combo.
- A trick earns nothing by itself. It only raises the combo multiplier by its amount in `combo.json`. The "+0.5" in a trick's popup is that rise.

The board expected each trick to pay points, with an unbroken combo raising the multiplier on them, the classic stunt-game score. This ticket would make each trick pay views (T-287's word):
- **What a trick pays:** its own base amount, multiplied by the combo at that moment.
- **The popup:** it shows the views earned.
- **The score:** the run's total views is its score, shown at the end of the run.

## Open questions (for refining with the board)

1. Does drifting keep paying per second as now, or do only tricks pay?
2. What is a trick's base amount? Should bigger tricks (AIR 360!, THREAD THE NEEDLE!) pay more? (The agent would propose the numbers, for the playtest.)
3. Does the trick still raise the multiplier by its own amount too, as today?
4. Where does the end-of-run score appear (the end screen), and is a best score kept between runs?

## Acceptance criteria

To be written once the open questions are answered.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-25, Open → Planning

On hold at the board's request: needs refining before work starts. Open questions are in the ticket.

## Result notes

Written by the agent when it finishes.
