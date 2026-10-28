---
id: T-320
title: The recap screen after every run, with pictures
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-318, T-319]
documents_affected: [docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/game-loop-architecture.md, docs/hud-and-menus.md, docs/visual-style.md, game/docs/game-loop/screen-flow.md, game/docs/hud-and-menus/level-up-screen.md, game/scripts/game/game_flow.gd, game/scripts/ui/level_up_screen.gd]
files_expected_to_change: [game/scripts/ui/, game/scenes/, game/scripts/game/game_flow.gd, game/tests/unit/, game/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md]
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

The board's decision (Game loop architecture, Decisions, "Recap screen in the MVP", 2026-10-28; it replaces "In the MVP there is no recap"): after a run ends, win or loss, the recap screen shows the run's stats (T-319's summary) before the main menu: the enemies slain, the tricks completed, the highest combo multiplier reached and the weapons used, **all shown visually where possible**: each enemy type with its own sprite and its count, each weapon with its level-up card image and its tier, the highest combo in the combo counter's heated look for that multiplier (HUD and menus, "Combo counter"), the tricks with their counts (in the trick popups' look, a proposal). A trick or enemy with a count of 0 is left out.

The look is the game's comic look (white rounded panels, black borders, the Bangers font, hard pixel edges, like the level-up screen). The stats may count up or pop in one by one (your proposal). One button (T-318's text) goes to the main menu. After a time's up loss it comes after the time's up screen (T-317) if that is merged first. All text from T-318, word for word; the art is the game's existing sprites; no PixelLab.

The board's review: play a run to its end and read the recap.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] When a run ends (a win, a loss by health, a loss by time), the recap screen shows before the main menu, and its button returns to the main menu (tests for each ending). (QA: pass / fail)
- [ ] It shows each enemy type and each trick with a count above 0 with the right number, the highest combo, and each weapon used with its tier, from T-319's summary (test with a scripted run). (QA: pass / fail)
- [ ] Enemies and weapons are shown with their existing art (sprite, card image). (QA: pass / fail)
- [ ] Every label comes from T-318's data file; no text is written in the code. (QA: pass / fail)
- [ ] Game loop architecture's screen flow, HUD and menus, Content, "Recap screen" and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-320/screenshots/`, as `tasks/README.md`, "Screenshots", asks. Shots after a win and after a loss. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
