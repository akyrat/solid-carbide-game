---
id: T-609
title: Text for the controller's button prompts
status: open
from: project-lead
to: narrative-theme
lead: Controller-support
epic: narrative
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/drifting.md, game/data/tutorial_text.json, game/data/trick_recipes.json, game/data/tutorial_practice.json]
files_expected_to_change: [game/data/controller_text.json, docs/hud-and-menus.md]
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

Text for step 3 of controller support (HUD and menus, Decisions, "Controller support in the menus and prompts"; the button layout: Drifting, Decisions, "Controller support"). When the player last used a controller, every place that names a keyboard key shows the controller's buttons instead (T-610 builds it and uses exactly this text). Write, through the style loop: (1) the short labels drawn on the button glyphs: left stick, D-pad, LT, RT, A, B, Y, LB, RB, Start (Xbox names; showing Xbox labels for every controller is a proposal for the playtest); (2) the controller version of every player-facing line in game/data/ that names a keyboard key (W, A, S, D, Space, R, Enter, Escape, Tab, arrows), for example the rail grind's "In the air, hold Space", the charged jump's hints, the tutorial's lines and the trick recipes' notes if they name keys. Search all of game/data/ (except the level creator's texts, which stay keyboard and mouse) and list every line found, with its file and key, in the result notes, including any that need no change. Put them in a new game/data/controller_text.json: a glyph block, and one entry per line keyed by its source file and key, with a _comment saying where it shows. Same length limits as the keyboard line it replaces. Record the texts in HUD and menus, Content, in a new subsection.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/data/controller_text.json exists, parses, and has a glyph label for each button in the description and a controller version for every line the result notes list as naming a keyboard key. (QA: pass / fail)
- [ ] The result notes list every line in game/data/ (outside the level creator's texts) that names a keyboard key, with its file and key, and say which got a controller version. (QA: pass / fail)
- [ ] No controller line is longer than the keyboard line it replaces (QA compares lengths with a short script). (QA: pass / fail)
- [ ] The Style review records the style loop, with every line scored 8 or more. (QA: pass / fail)
- [ ] HUD and menus, Content, has a subsection with the texts; the result notes say screenshots are not applicable (text only). (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
