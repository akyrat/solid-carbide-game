---
id: T-543
title: The trick list shows REVERSE DRIFT!, AURA FARMING! and GRIND!
status: blocked
from: project-lead
to: ui
lead: Rails
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
board_approved_art: no
depends_on: [T-541]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, game/data/trick_recipes.json, game/scripts/menu/trick_list.gd]
files_expected_to_change: [game/data/trick_recipes.json, game/data/tutorial_text.json, game/art/tutorial/clips/, game/tools/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
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

Build HUD and menus, Decisions, "The trick list shows the new tricks". Add the three tricks of 2026-11-05 to the trick list (pause screen's Trick list and the tutorial's trick slide, wherever the same list is shown), in the same form as the seven there: each with its line and keycap recipe exactly as T-533 wrote them (docs/hud-and-menus.md Content, T-533; reverse drift: S + A/D held, aura: no keys, stand still, grind: Jump onto a rail), in game/data/trick_recipes.json and the texts in game/data/tutorial_text.json, and a recorded clip of each (game/art/tutorial/clips/<clip>_sheet.png), recorded from the real game the way the existing clips were (see how T-491's clips were made). The grind clip shows a car landing on a rail on master's map (T-541's rails). Propose the order of the list (for example the ground tricks, then the air tricks, then the grind) and keep the list fitting on screen at 1280x720.

The board's review: open the pause screen's Trick list and the tutorial's trick slide in the ticket's folder, C:\solid-carbide-worktrees\T-543\game\project.godot.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] trick_recipes.json has entries for reverse_drift, aura and rail_grind (or the ids the trick detector uses), each with a clip and steps, and the texts match T-533's exactly (test). (QA: pass / fail)
- [ ] The trick list shows ten tricks with their clips, and still fits inside the window at 1280x720 (test or screenshot). (QA: pass / fail)
- [ ] The three new clip sheets exist and were recorded from the game, with the recording method in the result notes. (QA: pass / fail)
- [ ] docs/hud-and-menus.md Content describes the new rows. (QA: pass / fail)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] Screenshots in art-archive/T-543/screenshots/ show the trick list with the three new rows, in the pause screen and in the tutorial. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
