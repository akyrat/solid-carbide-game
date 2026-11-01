---
id: T-488
title: The first mission is a 2-second drift instead of 4
status: in-progress
from: project-lead
to: game-data
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, game/data/missions.json]
files_expected_to_change: [game/data/missions.json, game/tests/unit/]
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

The board, 2026-11-01 (Game loop architecture, missions, already updated): mission 1 is one unbroken drift of 2 seconds, not 4. Change game/data/missions.json mission 1's amount to 2 (and its note). The notebook line is built from the amount by screen_texts.json's extended_drift pattern, so no text changes. Update any test that expects 4. Never write, move or commit anything in game/data/levels/.

The board's review: start a run and see the notebook's first mission ask for 2 seconds; a 2-second drift ticks it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/missions.json mission 1 asks for one unbroken drift of 2 seconds; a test shows a 2-second drift completes mission 1 and a shorter one does not. (QA: pass / fail)
- [ ] The notebook's first line reads with 2 seconds (a test or a screenshot listed in the result notes). (QA: pass / fail)
- [ ] The tests for the changed files pass (the agent, with -gselect), and QA's full run passes (tasks/README.md, "Which tests run when"), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-01, Open → In progress

Filed from the board's note: mission 1 becomes a 2-second drift. Game Data agent started.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Mission 1 amount and note now 2 seconds in game/data/missions.json. Tests updated: run/test_missions.gd (2.1 s completes; two 1 s drifts do not; 1.5 s + 1.5 s across a wall hit does not; 2 s completes), test_mission_data.gd, game/test_missions_power_ups_run.gd, hud/test_hud_mission_page.gd (notebook line reads 'Hold one drift for 2 seconds', built from the amount). Ran with -gselect: test_missions, test_mission_data, test_missions_power_ups_run, test_hud_mission_page, test_mission_texts, all passed. Nothing in game/data/levels touched.
