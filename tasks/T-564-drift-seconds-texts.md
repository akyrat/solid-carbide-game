---
id: T-564
title: Texts: drift seconds goal and running totals in the notebook
status: open
from: project-lead
to: narrative-theme
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/data/tutorial_text.json, tasks/T-559-interactive-tutorial-texts.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md]
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

Build the texts of HUD and menus, Decisions, "The drift slide counts drift seconds", and Game loop architecture, Decisions, "Total-time mission goals show their running total", through the style loop: (1) the drift slide's notebook goal line for 3 seconds of drifting in total, with its running total (for example a format with {done} and {goal} seconds, one decimal), replacing T-559's "Drifts x/3" line for that slide; (2) the drift slide's instruction if it now says 3 drifts; (3) the format the in-game notebook uses to show a total-time goal's running total (for example airtime seconds), in the voice of the existing mission goal lines. Keys and _comment in the files the notebook and slides already read; list them in the result notes for T-565.

The board's review: in the combined build, play the drift slide and a run's airtime mission.

A tweak to the interactive tutorial build after the board played it (branch playtest/interactive-tutorial, which has T-559 to T-563). Your branch starts from that build. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line. Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each text exists with a key and a _comment, listed in the result notes. (QA: pass / fail)
- [ ] Each scores 8 or more in the style loop, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content lists them. (QA: pass / fail)
- [ ] The tests for the changed data pass and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
