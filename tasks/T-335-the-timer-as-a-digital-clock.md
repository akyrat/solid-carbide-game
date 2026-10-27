---
id: T-335
title: The timer at the bottom left as a digital clock that turns from green to red
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, game/README.md, game/scripts/hud/]
files_expected_to_change: [game/scripts/hud/, game/scenes/, game/tests/unit/hud/, game/README.md, docs/hud-and-menus.md, art-archive/T-335/]
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

The board's decision (HUD and menus, Decisions, "The HUD looks like a livestream", 2026-10-28). The run timer moves from the top centre to the **bottom left** and becomes a **digital pixel-art clock**: blocky segment-style digits ("7:56") in a dark panel. Its digits start **green** and turn **yellow, orange and red** as the time nears 0:00. Proposed switch points (the board's layout page uses these): green above 3:00, yellow to 1:30, orange to 0:30, red below; keep them in the HUD's data.

- **Position and size:** from the board's HUD layout page (https://claude.ai/artifact/U33QPUELxgZCZBjYDpBszQ). The Project Lead writes the saved numbers (game pixels at 1152 x 648) in this ticket's Updates when it starts; anchor it to the bottom-left corner so it keeps its margins at other window sizes.
- **Look:** placeholder drawn in code for now (dark panel, glowing digits). If T-339's clock art is in the branch you start from, use it instead.
- **Also, for the board's layout page:** save one **screenshot of a run with the HUD hidden** (the world only, 1152 x 648) as `art-archive/T-335/screenshots/run_no_hud.png`, so the board can place pieces over the clean game.

The board's review: play a run and watch the clock turn yellow, orange and red.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The timer shows at the bottom left at the layout page's position and size (at 1152 x 648), anchored to that corner, and no longer at the top centre (test). (QA: pass / fail)
- [ ] Its colour is green, yellow, orange and red at the data's switch points (tests at each boundary). (QA: pass / fail)
- [ ] It counts down exactly as before and stops while paused (the existing timer tests pass). (QA: pass / fail)
- [ ] `art-archive/T-335/screenshots/run_no_hud.png` is a 1152 x 648 run with no HUD. (QA: pass / fail)
- [ ] HUD and menus, Content and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots of the clock in green, yellow, orange and red are in `art-archive/T-335/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
