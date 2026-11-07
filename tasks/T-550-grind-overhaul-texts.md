---
id: T-550
title: Texts for the grind overhaul, the jump arrow and the Cosmetics menu
status: open
from: project-lead
to: narrative-theme
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/hud-and-menus.md, docs/garage-design.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [game/data/, docs/hud-and-menus.md, docs/garage-design.md]
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

Write every player-facing text the overhaul needs, through the style loop, into the data files the game already reads texts from (or a new one the UI ticket T-553 will read, named in your notes). (1) New texts: the main menu button that opens the Cosmetics submenu; the submenu's title, and its labels for a locked item with its price, buying, picking (equipped) and not enough coins; a name and a one-line description for each of the 5 jump effects (ids: dash_cloud, spring, jet_thrust, stunt_sparks, shockwave_ring; HUD and menus Decisions and Drifting, Decisions, "A jump effect around the car"); the label of the pause screen's checkbox for the jump arrow (HUD and menus, Decisions, "The jump arrow"), in the Drift Guide checkbox's voice. (2) Every existing text the overhaul makes wrong: search the game's data and docs for texts about grinding, Jump off a rail, the Jump power-up's cooldown (it has none now) and how a grind starts (now: hold Space in the air and touch a rail; release Space to launch where the car faces): the tutorial's slides, the trick list's GRIND! recipe, the Jump power-up's card and mission gift texts, and any other. Fix each, and list each text you changed with its file and key in the result notes. The texts the menu and checkbox use are listed with their keys, for T-553.

The board's review: read the new and changed texts in the combined build (playtest/grind-overhaul).

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each new text in the description exists in a data file with a key, listed in the result notes with what it is for and where it appears. (QA: pass / fail)
- [ ] Every existing text about grinding, Jump off a rail or the Jump cooldown that the overhaul makes wrong is changed, each listed with its file and key, and a search of game/data for "cooldown" near Jump shows none left. (QA: pass / fail)
- [ ] Each text has a style loop score of 8 or more in the Style review, or is noted for the playtest. (QA: pass / fail)
- [ ] docs/hud-and-menus.md and docs/garage-design.md Content list the new texts. (QA: pass / fail)
- [ ] The tests for the changed data pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
