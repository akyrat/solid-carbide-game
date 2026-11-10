---
id: T-615
title: Controller in the browser build
status: open
from: project-lead
to: qa-integration
lead: Controller-support
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: [T-607, T-608, T-610]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/working-with-the-board.md, tools/publish_itch.py]
files_expected_to_change: [docs/hud-and-menus.md]
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

The last step of controller support (HUD and menus, Decisions, "Controller support: local first, browser last, built for mobile later"). Once T-607, T-608 and T-610 are merged and the board is happy with the controller locally, check it in the browser build: export the Web preset (game/export_presets.cfg) to a folder outside game/, serve it locally, and check in Chrome that the game loads and that a controller is picked up after its first button press on the page. A real controller can't be pressed by an agent, so the agent checks what a script can (the export, its files, the page loading and Godot seeing a joypad through a mocked navigator.getGamepads if a headless browser allows it) and the board presses the buttons. Note: on 2026-11-09 the command guard refused an agent's headless --export-release Web; before this ticket starts, the Project Lead asks the board how the export runs (the board runs it, or allows it). Write what was found, and any browser-only difference from the desktop, in HUD and menus, Content.
The board's review: in Chrome (and Firefox if wanted), open the local browser build, press a controller button, then drive, use the menus and check the button prompts, as in the desktop build.
Board review files: art-archive/T-615/screenshots/

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The Web export folder (outside game/) holds index.html, a .wasm and a .pck, as the result notes say with the export command used. (QA: pass / fail)
- [ ] The result notes say whether the page loaded in Chrome, and what the script could check about the joypad (or why it could not). (QA: pass / fail)
- [ ] A screenshot in art-archive/T-615/screenshots/ shows the browser build running. (QA: pass / fail)
- [ ] HUD and menus, Content, records the browser findings and any difference from the desktop build. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
