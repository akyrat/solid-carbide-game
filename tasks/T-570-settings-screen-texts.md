---
id: T-570
title: Texts: the main menu's Settings button and the Settings screen
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/data/pause_text.json, game/scripts/menu/main_menu.gd]
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

Write the texts for HUD and menus, Decisions, "A Settings screen from the main menu", through the style loop: (1) the main menu button that opens it (for example "Settings"), in the voice of the other main menu buttons; (2) the screen's title, if it needs one; (3) its Back button, if the existing Back text does not fit. The settings' own labels are reused from game/data/pause_text.json as they are. Keys and _comment in the file the main menu already reads, or in pause_text.json; list them in the result notes for T-571.

The board's review: in T-571's build, open Settings from the main menu.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Never run a real itch.io push (butler push) and never print .env values. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

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
