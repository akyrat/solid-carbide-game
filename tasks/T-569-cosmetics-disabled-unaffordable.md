---
id: T-569
title: Cosmetics the player can't afford are disabled
status: open
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, tasks/T-553-cosmetics-menu-arrow-checkbox.md, game/scripts/menu/cosmetics_screen.gd]
files_expected_to_change: [game/scripts/menu/, game/tests/, game/docs/, docs/garage-design.md]
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

Build Garage design, Decisions, "Cosmetics the player can't afford are disabled": on the Cosmetics screen, a cosmetic's unlock button is disabled (greyed out, not clickable) while the player has fewer coins than its price, and clickable as soon as they have enough (for example right after another purchase changes the coins). Cosmetics already unlocked can always be picked. Use the same disabled look the menus already use for buttons, if there is one.

The board's review: play it from C:\solid-carbide-worktrees\T-569\game\project.godot: open Cosmetics with few coins and with enough (the agent says in the result notes how to give the save coins for the test).

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] A locked cosmetic's unlock button is disabled when coins are below its price and enabled when they reach it (tests). (QA: pass / fail)
- [ ] Unlocked cosmetics can always be picked (tests). (QA: pass / fail)
- [ ] docs/garage-design.md Content describes it. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-569/screenshots/ show the screen with an affordable and an unaffordable cosmetic. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
