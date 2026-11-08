---
id: T-582
title: Equip instead of Flex it on the Cosmetics screen
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
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/data/cosmetics_text.json]
files_expected_to_change: [game/data/cosmetics_text.json, game/tests/, docs/hud-and-menus.md, docs/garage-design.md]
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

Build HUD and menus, Decisions, "Equip instead of Flex it": set the `pick` text in game/data/cosmetics_text.json to "Equip" (the board's own word, so no style loop) and update its _comment, the tests that look for "Flex it" (test_cosmetics_screen.gd), and the docs that quote it (docs/hud-and-menus.md Content, "Item labels"; docs/garage-design.md if it quotes it). Check that "Equip" and the existing "Equipped" label read well side by side and fit the button. Your branch starts from the board's menu fixes build, which the board has approved.

The board's review: the board gave the word; a screenshot of the Cosmetics screen is enough.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] cosmetics_text.json's pick reads "Equip", and no "Flex it" is left in the game's data, scripts or tests (grep). (QA: pass / fail)
- [ ] The cosmetics tests pass (tests). (QA: pass / fail)
- [ ] The docs quote "Equip". (QA: pass / fail)
- [ ] A screenshot in art-archive/T-582/screenshots/ shows the Cosmetics screen with Equip. (QA: pass / fail)
- [ ] QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
