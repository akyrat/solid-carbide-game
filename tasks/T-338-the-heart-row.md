---
id: T-338
title: The hearts in a row at the top left, in place of the health bar
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: [T-334]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, game/docs/hud-and-menus/hud.md, game/scripts/hud/]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-338/]
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

The board's decisions (2026-10-28): HUD and menus, Decisions, "The HUD looks like a livestream"; Game loop architecture, Decisions, "Hearts instead of health points". The upright health bar and its heart at the top left are replaced by a **row of hearts**, like Zelda's, at the **top left**: one heart per heart the car can have (5, plus the garage's), full ones for the hearts left and empty ones for the hearts lost (no half hearts). A heart lost does a small break or flash (your proposal); a heart healed pops back in. Past one row's width (a proposal: 10), a second row starts under it.

- **Position and size:** from the board's HUD layout page (https://claude.ai/artifact/CSHYCDV9xZbSYwQGUt5SJ4); the Project Lead writes the saved numbers in this ticket's Updates when it starts. The weapon icons column moves to the page's position for it too.
- If T-339's heart art (full and empty) is in the branch you start from, use it; otherwise today's heart picture for full hearts and a dark outline of it for empty ones.

The board's review: play a run, get hit and heal: the hearts empty and fill.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The health bar is gone; the hearts show in a row at the layout page's position (at 1152 x 648), one per heart, full or empty to match the run (tests with 5, with a garage heart, after a hit and after a heal). (QA: pass / fail)
- [ ] The weapon icons are at the layout page's position and still clear of every other HUD piece (test). (QA: pass / fail)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) are in `art-archive/T-338/screenshots/`: full hearts, after a hit, and with a garage heart. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
