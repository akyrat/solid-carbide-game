---
id: T-565
title: The drift slide counts 3 s of drifting in total; total-time mission goals show their running total
status: open
from: project-lead
to: game-loop
lead: Rails
epic: game-loop
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/game-loop-architecture.md, docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, tasks/T-561-practice-session.md, tasks/T-563-notebook-trick-splash.md, game/scripts/hud/mission_page.gd]
files_expected_to_change: [game/scripts/run/, game/scripts/hud/, game/tests/, game/docs/game-loop/, docs/game-loop-architecture.md, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "The drift slide counts drift seconds" and Game loop architecture, Decisions, "Total-time mission goals show their running total". (1) Practice session (T-561): the drift slide's goal becomes 3 seconds of drifting in total, added up over all drifts (not one unbroken drift); the notebook shows the running total live as the player drifts, and the success signal fires when it reaches 3 s. The other trick slides keep counting 3 tricks. (2) In the run, a mission goal that adds time up (the airtime goal; any other total-time goal) shows its running total against its goal in the notebook, updating live as it grows (mission_page.gd and the run's progress signal). The unbroken drift goal is unchanged. Decide how T-563's falling name box behaves for time goals (propose: no box for each fraction of a second; for example a box when a drift or a landing adds its seconds) and say what you chose. Texts come from T-564's keys (merged into your branch when it passes QA); until then, a seam.

The board's review: in the combined build, play the drift slide (3 s in total) and a run's airtime mission.

A tweak to the interactive tutorial build after the board played it (branch playtest/interactive-tutorial, which has T-559 to T-563). Your branch starts from that build. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line. Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] On the drift slide, drifting adds up across drifts, the notebook shows the running total, and the success fires at 3 s in total (tests). (QA: pass / fail)
- [ ] The other three trick slides still count 3 tricks (the existing tests pass). (QA: pass / fail)
- [ ] In a run, the airtime goal shows its running total in the notebook, updating as airtime adds up (test); the unbroken drift goal is unchanged (test). (QA: pass / fail)
- [ ] docs/game-loop-architecture.md and docs/hud-and-menus.md Content describe it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] A GIF in art-archive/T-565/screenshots/ shows the drift slide's total growing to 3 s and the run's airtime total growing. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
