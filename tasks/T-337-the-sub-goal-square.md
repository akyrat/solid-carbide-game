---
id: T-337
title: The sub goal square in place of the likes bar, with the gift pack inside it
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-331]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/, game/art/gift_pack/package.png]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-337/]
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

The board's decisions (2026-10-28): HUD and menus, Decisions, "The HUD looks like a livestream"; Game loop architecture, Decisions, "Subs instead of likes". The likes bar and its "Likes ... Hype Lv" row are replaced by the **sub goal**, as the board designed it on its layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4):

- A **black square** that **fills green from the bottom** as subs come in (today's likes XP within the level), with today's spring when subs arrive (the fill shoots up with a small overshoot, T-273) and the drain emptying it slowly as now.
- **The gift pack inside it**, centred, filling 80% of the square (a 10% margin on each side; crop `art/gift_pack/package.png` to its box first, as the page does), **greyed out and dimmed** while the goal isn't reached. When the goal is reached it **lights up** in full colour and bounces, the square glows, and the level-up goes on as today (the helicopter brings the gift pack), then the square starts again from empty.
- **Under the square:** T-331's label, "{subs} / {goal}" with the subs icon or word.
- **"Hype Lv" is gone for good** (the board, 2026-10-28): remove the text, its code (`TEXT_LEVEL` and its placement in `hud.gd`) and the level-up pop that used it (`level_up_flash.gd`), and the same in the tests, comments and game/README.md. The level now shows only through the sub goal: the square fills, the gift lights up, the level-up goes on. Nothing replaces the text.
- Today's level-up animation on the bar (T-139) and the bar's heat (fire at the top combo step) are carried over to the square where they fit, or dropped with a reason in the result notes.
- **Position and size:** from the layout page; the Project Lead writes the saved numbers in this ticket's Updates when it starts; the board has put it on the right edge, about two thirds down (x988, y340, 128 x 180 at 1152 x 648), so anchor it to the right edge, not the bottom centre.
- If T-339's art (the square's frame, the subs icon) is in the branch you start from, use it; otherwise placeholders in code.

The board's review: play a run: the square fills as you drift, the gift lights up at the goal, and the gift pack comes.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The likes bar and its row are gone; the sub goal square shows at the layout page's position (at 1152 x 648), anchored to the right edge, and no "Hype Lv" text or code is left (test). (QA: pass / fail)
- [ ] The square's fill is the share of the current goal, with the spring on gains, and empties with the drain (tests). (QA: pass / fail)
- [ ] The gift is centred at 80% of the square, greyed until the goal and in full colour at it; the level-up and gift pack drop work as before (tests). (QA: pass / fail)
- [ ] The label under it shows "{subs} / {goal}" from T-331's text (test). (QA: pass / fail)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-337/screenshots/`: the square part-filled with the grey gift, and a GIF of it reaching the goal. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
