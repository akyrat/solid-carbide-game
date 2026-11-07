---
id: T-553
title: The Cosmetics submenu from the main menu, and the jump arrow checkbox
status: open
from: project-lead
to: ui
lead: Rails
epic: garage
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-550, T-552]
documents_affected: [docs/hud-and-menus.md, docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/garage-design.md, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [game/scripts/ui/, game/scenes/, game/tests/, docs/hud-and-menus.md, docs/garage-design.md]
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

Build HUD and menus, Decisions, "A Cosmetics button on the main menu" and the checkbox of "The jump arrow", and the screen of Garage design, Decisions, "Cosmetics". (1) A Cosmetics button on the main menu, in the shared button style, opening a Cosmetics submenu: a list of the jump effects with their name, description, price or picked state, a preview of each effect (its animation once T-556's art is in; until then the placeholder from T-551 or a still), buy and equip through T-552's API, the coin count, and a way back; keyboard and mouse like the other menus. (2) A checkbox for the jump arrow in the pause screen's settings next to Drift Guide, showing and saving `jump_arrow_enabled` and switching the arrow at once (T-551 reads it). All texts from T-550's keys (listed in its result notes), no placeholder text.

The board's review: in the combined build, open Cosmetics from the main menu, buy and pick an effect, and switch the arrow in the pause settings.

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The main menu's Cosmetics button opens the submenu and Back returns (test). (QA: pass / fail)
- [ ] The submenu lists the 5 jump effects with T-550's names and descriptions, shows prices and the coin count, buys and equips through the API, and refuses a purchase without enough coins with T-550's text (tests). (QA: pass / fail)
- [ ] The pause screen's jump arrow checkbox shows and saves jump_arrow_enabled and fits the settings row (test). (QA: pass / fail)
- [ ] Every text comes from T-550's keys (a search finds no hard-coded label). (QA: pass / fail)
- [ ] docs/hud-and-menus.md and docs/garage-design.md Content describe the screens. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-553/screenshots/ show the main menu with the button, the submenu (locked, bought, picked), and the pause settings with the checkbox. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
