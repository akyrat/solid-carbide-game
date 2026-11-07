---
id: T-554
title: Jump is offered on the first two mission gifts
status: in-progress
from: project-lead
to: game-loop
lead: Rails
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/drifting.md]
files_expected_to_change: [game/scripts/, game/data/, game/tests/, docs/game-loop-architecture.md]
model: sonnet
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

Build Game loop architecture, Decisions, "Jump is offered first": the first mission gift of a run always has the Jump power-up as one of its 2 choices; if the player doesn't take it, the second gift offers it again; after that, the usual offer rules. The other choice comes from the usual rules. Keep the slot caps and the God mode and test hooks working.

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Over many seeded runs, the first mission gift always offers Jump as one of 2 choices (test). (QA: pass / fail)
- [ ] If Jump isn't taken on the first gift, the second offers it; if it was, the second follows the usual rules (tests). (QA: pass / fail)
- [ ] docs/game-loop-architecture.md Content describes it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: Jump offered on the first two mission gifts.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. power_up_offers.gd: gifts_opened counter (reset on run start, skipped gifts not counted); while < 2 gifts opened and Jump not owned and in the pool, Jump is forced as one of the 2 choices, the other drawn as usual. Slot caps unaffected (Jump not in pool when slots full of other power-ups). Hooks unchanged. 4 new tests in test_power_up_offers.gd (200 seeds first gift, second gift when not taken, usual rules when taken, third gift unforced). Full suite: 254 scripts, 2921 tests, 2920 pass, 0 fail, 1 risky. Docs: game-loop-architecture.md Content bullet added (Decisions line already existed).
