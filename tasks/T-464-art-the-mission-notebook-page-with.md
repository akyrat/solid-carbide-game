---
id: T-464
title: Art: the mission notebook page (with checkbox, tick and cross-off marks) and the power-up overlay's frame (PixelLab)
status: open
from: project-lead
to: asset-generation
lead: Goal-G-009
epic: art
milestone: mvp
goal: G-009
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-458, T-459]
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, game/docs/hud-and-menus/livestream-hud-art.md, game/scripts/hud/mission_page.gd, game/scripts/ui/power_up_screen.gd, game/scripts/hud/hud_style.gd]
files_expected_to_change: [game/art/hud/mission_page.png, game/art/hud/mission_checkbox.png, game/art/hud/mission_tick.png, game/art/hud/mission_cross.png, game/art/ui/power_up_frame.png, game/scripts/hud/mission_page.gd, game/scripts/ui/power_up_screen.gd, docs/visual-style.md]
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

Final art for the notebook mission page (Game loop architecture, Decisions, 'Mission packs': a pixel-art notebook page on the left of the HUD) with its checkbox, tick and cross-off marks, and the frame of the driving power-up overlay, which must read clearly differently from the Greenbull weapons gift screen (not Greenbull's colours or emblem: Visual style, Content, 'Rules', rule 6). Made with PixelLab through the style loop (`tools/style_loop/run.py art`), free script fixes before regenerations, at most 4 generations per asset within the goal's art cap; write the planned calls and cost in the result notes first. Swap them in for D4's and D5's placeholders yourself, keeping their tests green. Record the art in Visual style, Decisions; archive every other generation under art-archive/<id>/.

The board's review: look at the notebook page and the power-up overlay's frame in a run, on dark and light ground: style, readability, and that the overlay reads as distinct from the weapons gift screen.

## Acceptance criteria

- [ ] The notebook page, checkbox, tick, cross-off mark and overlay frame are PNGs in game/art/, each with a Style review round on the ticket, and the generation count is in the result notes. (QA: pass / fail)
- [ ] The HUD's mission page and the power-up overlay use the new art in place of their placeholders, and their tests still pass. (QA: pass / fail)
- [ ] Screenshots of the page and the overlay in the game, on a dark and a light background, are in art-archive/<id>/screenshots/. (QA: pass / fail)
- [ ] Visual style records the new art. (QA: pass / fail)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
