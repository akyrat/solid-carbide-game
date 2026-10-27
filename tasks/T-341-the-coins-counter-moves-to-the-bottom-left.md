---
id: T-341
title: The coins counter moves to the bottom left, above the clock
status: blocked
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-335]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/README.md, game/scripts/hud/, tasks/T-335-the-timer-as-a-digital-clock.md]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-341/]
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

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28): on the HUD layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4) the **coins counter** ("Coins" and the number collected this run, in yellow) moves from the top right to the **bottom left, just above the clock**. Saved position at 1152 x 648: x16, y496, 108 x 36 (the clock is x16, y560, 200 x 72, so the two stack with a gap of 28 pixels). Anchor it to the bottom-left corner like the clock (T-335) so it keeps its margins at other window sizes. The text and the look stay as they are today (no new text); only the position and its anchor change. The Project Lead writes the final saved numbers in this ticket's Updates when it starts, in case the board has moved the piece again.

The board's review: play a run: the coins count sits above the clock at the bottom left and nothing overlaps it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The coins counter shows at the layout page's position (at 1152 x 648), anchored to the bottom-left corner, and is gone from the top right (test). (QA: pass / fail)
- [ ] It doesn't overlap the clock, the weapon icons or any other HUD piece, at 1152 x 648 and at a larger window size (test). (QA: pass / fail)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-341/screenshots/`: at 1152 x 648 and at a larger window. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new position has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
