---
id: T-303
title: Art: the level-up screen in Greenbull's colours, with its emblem
status: blocked
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-141, T-302, T-300, T-299]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/README.md, tasks/T-140-art-level-up-screen.md, tasks/T-141-level-up-screen-animation.md, game/tools/build_level_up_art.py, game/tools/test_build_level_up_art.py, game/scripts/ui/level_up_screen.gd, game/tests/unit/test_level_up_screen.gd, game/art/level_up/, game/art/logo/]
files_expected_to_change: [game/art/level_up/, game/tools/build_level_up_art.py, game/tools/test_build_level_up_art.py, art-archive/, docs/visual-style.md, game/README.md]
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

The level-up screen (T-140 art, T-141 animation, D5 texts) is in Redgull's red and gold with the gull. Remake its art in Greenbull's colours as the docs decide (Visual style, Decisions, 'The rebrand', 'Greenbull's look', 'Red after the rebrand'; Content, Rules, rule 6): Greenbull's dark green leading, with light green and a little yellow. The pieces in game/art/level_up/: header_ribbon.png, gift_pack_emblem.png, card_frame.png, highlight_frame.png, button_plate.png, button_plate_pressed.png and sunburst.png. The ribbon and the gift box carry Greenbull's emblem from game/art/logo/ (D3) instead of the gull.

Free script work first: rebuild them with build_level_up_art.py (or a successor) from the earlier sources, recoloured, with the emblem stamped in place of the gull. Use PixelLab only where a recolour can't do it, listing each call with its reason and count in the result notes before calling; the board's go is up to 12 generations per asset (a style loop run may be repeated on one asset with an improved brief, up to three runs), within the goal's art cap. Every piece goes through the style loop with --greenbull. Keep the old red and gold versions in art-archive/<this ticket>/ (never delete). Same file names and sizes, so level_up_screen.gd loads them unchanged. Update Visual style (the level-up screen's look) and game/README.md, 'Level-up screen art', to say how they are built now. Screenshots of the open screen with two cards, the highlight on each in turn, in art-archive/<this ticket>/screenshots/.

The board's review: play a run to a level-up: the screen's ribbon, emblem, cards, buttons and sunburst in Greenbull's dark green, light green and a little yellow, with no Redgull red or gull.

## Acceptance criteria

- [ ] header_ribbon.png, gift_pack_emblem.png, card_frame.png, highlight_frame.png, button_plate.png, button_plate_pressed.png and sunburst.png in game/art/level_up/ are remade with Greenbull's dark green as the main colour, with light green and a little yellow, and keep their file names and sizes. (QA: pass / fail)
- [ ] None of the seven pieces has a pixel the Redgull red check (style_rules.is_redgull_red, or its renamed successor) flags (output in the result notes). (QA: pass / fail)
- [ ] The ribbon and the gift box show Greenbull's emblem from game/art/logo/ and no gull (screenshots). (QA: pass / fail)
- [ ] build_level_up_art.py (or its successor) rebuilds the pieces by script, and its test passes; any PixelLab call is listed in the result notes with its reason and count, within 12 generations per asset. (QA: pass / fail)
- [ ] Each piece passes `python game/tools/style_rules.py art <file> --greenbull` and has a style loop record in the ticket's Style review. (QA: pass / fail)
- [ ] The old red and gold versions of all seven pieces are in art-archive/<this ticket>/. (QA: pass / fail)
- [ ] test_level_up_screen.gd passes: the screen still opens, animates and takes cards as before. (QA: pass / fail)
- [ ] Screenshots of the open level-up screen with two cards, the highlight on each, are in art-archive/<this ticket>/screenshots/, listed in the result notes. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
