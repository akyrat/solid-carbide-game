---
id: T-378
title: Art: the splash cover behind the main menu
status: cancelled
from: project-lead
to: asset-generation
lead: Greenbull
epic: art
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-377]
documents_affected: [docs/visual-style.md, game/docs/art/]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/working-with-the-board.md, game/docs/art/pixellab.md, game/art/car/, game/art/kaiju/, game/art/effects/]
files_expected_to_change: [game/art/menu/, art-archive/, docs/visual-style.md, game/docs/art/]
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

The board's decision (Visual style, Decisions, "The splash cover", 2026-10-29; an MVP nice-to-have). An AI-generated pixel art image behind the main menu, the game's cover for now. The board: "it's very, very important that it's consistent with the style of the game and the colors that we have and the actual car ... It doesn't need to be one-to-one what's in the game. It can be more cinematic. So you could add, let's say, the car drifting around the kaiju where the meteors are falling and the car is drift, avoiding them ... And the drift tricks show ... I'll leave the rest up to you. I trust you."

Use the game's real art as reference (the car's sheet, the kaiju, the meteors, the drift smoke and marks, the trick popups' look, the city), the game's palette and pixel rules (Visual style, Content, "Rules"; Greenbull's colours only on Greenbull's things). Leave room where the menu's title and buttons sit (see T-377's screenshots), or keep that part calm. Size: the menu's 1152 x 648 at the game's pixel scale or a clean multiple. Save as `game/art/menu/splash.png` with a record; the menu picks it up on its own (T-377).

**PixelLab: the board's go, up to 20 generations.** Write the planned calls and their cost in the result notes before the first call; 600 s timeout. Sample compositions first (cheap ones), then refine the best in the style loop (at most 3 refines). Never delete generated art (rejects to `art-archive/<id>/`).

The board's review: open the game and look at the main menu.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] `game/art/menu/splash.png` exists with a record, and the main menu shows it behind the title and buttons, which stay readable. (QA: pass / fail)
- [ ] It scored at least 8 in the style loop (or is noted below 8 after 3 refines), with every round in the Style review, judged on consistency with the game's style, palette and car. (QA: pass / fail)
- [ ] The PixelLab generations used are at most 20 and listed in the result notes, with the plan written before the first call. (QA: pass / fail)
- [ ] Visual style and the art docs under game/docs/art/ record it. (QA: pass / fail)
- [ ] The image enlarged, the sampled compositions, and a screenshot of the main menu with it are in `art-archive/<id>/screenshots/`. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

- 2026-10-30, open → cancelled: Replaced by goal G-008 (HUD and main menu), which writes its own tickets from the same decisions (2026-10-30).
