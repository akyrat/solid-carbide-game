---
id: T-375
title: Art: one visual language for the whole HUD
status: cancelled
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/hud-and-menus.md, game/docs/hud-and-menus/hud.md, game/art/hud/, game/tools/build_hud_livestream_art.py]
files_expected_to_change: [game/art/hud/, game/tools/, art-archive/, docs/visual-style.md, game/docs/art/]
model: opus
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board's decision (HUD and menus, Decisions, "A consistent HUD", 2026-10-29; an MVP nice-to-have, **start only after the last MVP round**): "they seem like they came from different games at the moment". Today's HUD pieces (the clock, the coins box, the hearts, the viewers counter and its fire, the sub goal square, the weapon icons, the combo counter, the trick popups, the reactions, the pause and level-up panels) were made in separate tickets.

1. Take a screenshot of the HUD in a run and list what differs between the pieces (outline thickness and colour, palette, font, corner shape, shadow, pixel scale).
2. Write **one HUD style sheet** in Visual style (outline, palette, panel shape and corners, the font for numbers and for words, the pixel scale): your proposal, built from what the board already approved (the comic look of the level-up screen and the reaction icons the board loved), with none of Greenbull's colours outside Greenbull's things.
3. Redraw by script every HUD art piece that breaks it (keep the old files in `art-archive/<id>/`), and list in the result notes what the UI ticket must change in code (fonts, colours, outline widths), for the linked UI ticket. No PixelLab (script work; if one piece needs PixelLab, stop and say so).
4. A before and after screenshot of the same moment in a run.

The board's review: compare the before and after, then play a run.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Visual style holds one HUD style sheet (outline, palette, panel shapes, fonts, pixel scale), and the result notes list each HUD piece and what changed or why it already fits. (QA: pass / fail)
- [ ] Every redrawn piece is in game/art/hud/ with its record, the old versions are in art-archive/<id>/, and no PixelLab generations were used. (QA: pass / fail)
- [ ] The result notes list the code changes the UI ticket needs (fonts, colours, outlines), piece by piece. (QA: pass / fail)
- [ ] Before and after screenshots of the same moment in a run are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] `python -m unittest discover -s game/tools -p "test_*.py"` passes, with the count in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

- 2026-10-30, open → cancelled: Replaced by goal G-008 (HUD and main menu), which writes its own tickets from the same decisions (2026-10-30).
