---
id: T-317
title: The 3-second animated time's up screen when the timer runs out
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-316]
documents_affected: [docs/game-loop-architecture.md, docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, game/docs/game-loop/the-run.md, game/docs/game-loop/screen-flow.md, game/scripts/run/run_state.gd, game/scripts/game/game_flow.gd, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/scripts/ui/, game/scenes/, game/scripts/game/game_flow.gd, game/tests/unit/, game/README.md, docs/hud-and-menus.md]
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

The board's decision (Game loop architecture, Decisions, "Time's up screen", 2026-10-28): when the 8-minute timer runs out and the kaiju has survived it (a loss), a **3-second animated failure screen** plays, then the run ends as today (straight to the main menu, or to the recap screen once T-320 is merged).

Build it in the game's comic look (the trick popups, the combo broken popup, the level-up screen: white rounded panel, black border, the Bangers font, hard pixel edges), with T-316's text, word for word. The animation is your proposal for the playtest: for example the headline slamming in and shaking, cracked like the COMBO BROKEN! popup, over the dimmed, frozen run. The run stops when the timer hits 0:00 (no damage, no likes, no pickups during the 3 seconds), and the screen can't be skipped (a proposal; say if a key to skip is cheap). Only the timer's loss shows it: losing all health ends the run as today (a proposal; the board asked only about the 8-minute mark). Placeholder look in code is fine; no PixelLab.

The board's review: let a run reach 8:00 without killing the kaiju and watch the time's up screen.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] When the timer reaches 0:00 with the kaiju alive, the screen shows T-316's text for 3 seconds (±0.1 s), animated, then the run ends with the same result as before (test with the run's time advanced to the end). (QA: pass / fail)
- [ ] During the 3 seconds the run is frozen: the timer, enemies, damage and pickups don't change (test). (QA: pass / fail)
- [ ] Killing the kaiju, and losing all health, end the run exactly as before, without this screen (tests). (QA: pass / fail)
- [ ] Every label comes from T-316's data file; no text is written in the code. (QA: pass / fail)
- [ ] HUD and menus, Content, "Time's up screen" and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-317/screenshots/`, as `tasks/README.md`, "Screenshots", asks. A GIF shows the whole 3 seconds. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
