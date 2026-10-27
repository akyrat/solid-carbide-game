---
id: T-311
title: Art: the level-up ribbon (and frames if needed) with dark green leading, checked on a screenshot from the main menu
status: in-progress
from: project-lead
to: asset-generation
lead: Goal-G-006
epic: art
milestone: mvp
goal: G-006
user_facing_text: no
changes_visuals: yes
depends_on: [T-309, T-310]
documents_affected: [docs/visual-style.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/hud-and-menus.md, docs/working-with-the-board.md, game/README.md, tasks/T-303-art-the-level-up-screen-in.md, game/tools/build_level_up_art.py, game/tools/test_build_level_up_art.py, game/tools/check_level_up_shot.py, game/tools/style_rules.py, game/scripts/ui/level_up_screen.gd, game/art/level_up/, art-archive/T-307/screenshots/level_up_screen.png]
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

T-303 remade the level-up screen in Greenbull's colours, but light green leads. The header ribbon's large centre field is light green RGB 104, 220, 96. The goal check needs Greenbull's dark green RGB 12, 76, 44 to be the most common colour in the ribbon, frame and emblem art on screen, as the docs say: dark green leading, light green and a little yellow (Visual style, Decisions, 'Greenbull's look'; Content, Rules, rule 6).

Rebuild header_ribbon.png with build_level_up_art.py, keeping its size (380x44), the title area (art x 76 to 304) and the emblem medallions. The centre field becomes Greenbull's dark green, with light green kept to trim and the thin yellow line. The title is now lettered in cream with a dark outline (D2), so it reads on dark green. If dark green still doesn't lead on screen, also shift card_frame.png and highlight_frame.png toward dark green (keep the cream fill, the sizes and the 10-pixel 9-slice margins). The gift box can stay as it is. Keep T-303's versions in art-archive/<this ticket>/ (never delete). This is free script work: no PixelLab call is expected. If one is needed, list it with its reason and count in the result notes before calling; the board's go is up to 12 generations per asset, within the goal's art cap. Every changed piece goes through the style loop with --greenbull.

Then take the screenshot with D1's fixture (game/tests/fixtures/level_up_from_menu_demo.tscn, a run started from the main menu, screen fully open with both cards) and run `python game/tools/check_level_up_shot.py <png>` on it. It must report no Redgull red pixel and dark green RGB 12, 76, 44 as the most common art colour. Write its output in the result notes. Update Visual style (the level-up screen's look) and game/README.md ('Level-up screen art').

The board's review: play a run from the main menu to a level-up: the ribbon is dark green with light green trim and a little yellow, the cream title reads clearly on it, the emblems show, and there is no Redgull red.

## Acceptance criteria

- [ ] header_ribbon.png keeps its size (380x44) and has a dark green RGB 12, 76, 44 centre field with light green trim and a thin yellow line; any other changed piece keeps its file name and size; `python game/tools/build_level_up_art.py check` passes for all seven pieces. (QA: pass / fail)
- [ ] Each changed piece passes `python game/tools/style_rules.py art <file> --greenbull` and has a style loop record in this ticket's Style review. (QA: pass / fail)
- [ ] T-303's versions of every changed piece are in art-archive/<this ticket>/. (QA: pass / fail)
- [ ] A screenshot from game/tests/fixtures/level_up_from_menu_demo.tscn (a run started from the main menu, the level-up screen open with both cards and the Greenbull title) is in art-archive/<this ticket>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] `python game/tools/check_level_up_shot.py` on that screenshot exits 0: no Redgull red pixel, and dark green RGB 12, 76, 44 is the most common art colour; its output is in the result notes. (QA: pass / fail)
- [ ] test_build_level_up_art.py and test_level_up_screen.gd pass; any PixelLab call is listed in the result notes with its reason and count. (QA: pass / fail)
- [ ] docs/visual-style.md and game/README.md describe the dark green ribbon. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-27, Open → In progress

Goal runner (G-006): started, in C:\solid-carbide-worktrees\T-311.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
