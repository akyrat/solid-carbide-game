---
id: T-327
title: Restart and Exit buttons on the pause screen
status: open
from: project-lead
to: ui
lead: Greenbull
epic: hud-menus
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, game/README.md, game/scripts/ui/pause_screen.gd, game/scripts/game/game_flow.gd, game/scripts/run/run_state.gd]
files_expected_to_change: [game/scripts/ui/pause_screen.gd, game/scripts/game/game_flow.gd, game/tests/unit/, game/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md]
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

The board's decision (HUD and menus, Decisions, "Restart and Exit on the pause screen", 2026-10-28): the pause screen (Escape during a run; `scripts/ui/pause_screen.gd`) gets two buttons, labelled with the board's own names, **"Restart"** and **"Exit"**, word for word (no text ticket: the board named them, as with "SFX volume" and "Camera smoothing").

- **Restart** ends the current run and starts a fresh one straight away, as if Start had been pressed on the main menu (a new run at level 1, the same map, the garage upgrades applied: `game_flow.gd` `start_run()` / `add_run()`).
- **Exit** ends the current run and goes back to the main menu. Exit on the main menu still closes the game; only the pause screen's Exit goes to the menu.

**Proposals for the playtest** (write them in the result notes and in HUD and menus, Content):
- Where the buttons sit on the pause screen (for example a row at the bottom, under the sliders), in its existing look.
- Whether either asks "are you sure?" first (a proposal: no, keep it quick; if a confirm is proposed, its text needs a Narrative Theme ticket, so say so instead of writing it).
- The run's coins: the coins collected so far are kept, as on any loss (Game loop architecture, Decisions: "kept whether the run is won or lost").
- A run left by Restart or Exit shows no time's up screen or recap (T-317, T-320 are not built yet; say how they should skip it).
- Keyboard: the buttons can be reached with the keyboard, like the rest of the pause screen.

A run started from the level creator (T-239) comes back to the creator when it ends: say what Exit and Restart do there (a proposal: Exit returns to the creator, Restart replays the same level).

The board's review: pause a run, press Restart, then pause again and press Exit.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The pause screen shows two buttons labelled exactly "Restart" and "Exit", reachable by mouse and keyboard (test). (QA: pass / fail)
- [ ] Restart removes the current run and starts a fresh one at level 1 with full health, the clock at 8:00 and the garage upgrades applied, unpaused (test). (QA: pass / fail)
- [ ] Exit removes the current run and shows the main menu, with the game unpaused (test); the main menu's own Exit still closes the game. (QA: pass / fail)
- [ ] The coins collected before Restart or Exit are kept, as on a loss (test). (QA: pass / fail)
- [ ] In a run started from the level creator, Restart and Exit do what the result notes propose (test). (QA: pass / fail)
- [ ] HUD and menus, Content, Game loop architecture's screen flow and game/README.md describe the buttons and the proposals. (QA: pass / fail)
- [ ] Screenshots of the pause screen with the two buttons are in `art-archive/T-327/screenshots/`, as `tasks/README.md`, "Screenshots", asks. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
