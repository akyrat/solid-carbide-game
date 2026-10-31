---
id: T-445
title: Art: the board's own splash art behind the main menu
status: open
from: project-lead
to: asset-generation
lead: Greenbull
epic: audit
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/visual-style.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, game/art/menu/splash.json]
files_expected_to_change: [game/art/menu/splash.png, game/art/menu/splash.json, art-archive/, docs/visual-style.md]
model: sonnet
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

The board, 2026-10-31: the main menu's splash cover becomes the board's own picture, `C:\Users\andre\Downloads\pixellab-Make-this-more-cinematic-and-a-1793446317815.png` (320 x 180, RGBA, the same size and format as today's `game/art/menu/splash.png`; the board made it with PixelLab outside the studio). The board has already seen and approved it, so this ticket skips QA and the tests (tasks/README.md, "QA", "Art the board has already approved skips QA and the tests").

1. Move today's splash (T-433's, v2 of its style loop) to `art-archive/<this ticket>/` with its record, never deleting it.
2. Copy the board's picture to `game/art/menu/splash.png` byte for byte (no style loop, no PixelLab call, no edits).
3. Update `game/art/menu/splash.json` (source: the board's own PixelLab picture, date, ticket) and the Visual style document's line on the splash cover (Decisions, "The splash cover", or Content), saying the cover is now the board's picture.
4. One screenshot of the main menu with it, if the capture script works (`bash game/tools/screenshot.sh <menu scene> screenshots/x.png <frames>`); no test sets.

Never write, move or commit anything in game/data/levels/.

The board's review: open the game and look at the main menu.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] game/art/menu/splash.png is byte for byte the board's picture (the agent shows matching SHA-256 hashes in the result notes). (QA: pass / fail)
- [ ] Today's splash is in art-archive/ with its record, not deleted. (QA: pass / fail)
- [ ] splash.json and docs/visual-style.md say the cover is the board's own picture. (QA: pass / fail)
- [ ] A screenshot of the main menu is saved in art-archive/<this ticket>/screenshots/, or the result notes say why not. (QA: pass / fail)
- [ ] 0 PixelLab calls; nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
