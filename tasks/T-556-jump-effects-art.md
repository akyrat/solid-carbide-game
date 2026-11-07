---
id: T-556
title: Art: the five jump effects (dash cloud, spring, jet thrust, stunt sparks, shockwave ring)
status: open
from: project-lead
to: asset-generation
lead: Rails
epic: driving
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/drifting.md, docs/garage-design.md]
files_expected_to_change: [game/art/effects/, art-archive/T-556/, game/scripts/driving/, docs/visual-style.md]
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

Make the art for Drifting, Decisions, "A jump effect around the car": five short animations played around the car when it jumps: a little dash cloud (the default), a spring pushing the car up, a jet thrust, stunt sparks (a burst of sparks under the car) and a shockwave ring (a ring rippling out on the ground). Small, quick, readable at game size, in the game's pixel style. Prefer the free pixel and effect tools (pixelart_workbench, vfx_workbench) where they serve; PixelLab generations are approved (the board's go, 2026-11-07) up to 50 for this ticket, within the overhaul's 250, through the style loop; write planned calls and totals in the result notes, 600 s timeout. Decide whether an effect needs per-direction art (a jet from the car's rear does) and say so. Swap them in for T-551's placeholders, so each id plays its art; the Cosmetics submenu (T-553) shows them as previews. Never delete generated art.

The board's review: in the combined build, pick each effect in Cosmetics and jump.

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Each of the 5 effect ids plays its own animation around the car when it jumps, instead of the placeholder (test). (QA: pass / fail)
- [ ] Each effect's style loop score is 8 or more, or it is noted for the playtest. (QA: pass / fail)
- [ ] PixelLab calls and totals are in the result notes, within 50. (QA: pass / fail)
- [ ] docs/visual-style.md Content describes the effects and how they were made. (QA: pass / fail)
- [ ] QA's full test run passes, with the counts in the result notes. (QA: pass / fail)
- [ ] GIFs in art-archive/T-556/screenshots/ show each effect in the game. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
