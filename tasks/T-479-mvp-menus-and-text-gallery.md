---
id: T-479
title: The board's MVP pass: a gallery of every screen and a list of every player-facing text
status: open
from: project-lead
to: qa-integration
lead: Greenbull
epic: tooling
milestone: mvp
goal:
user_facing_text: no
changes_visuals: no
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/setup/tests.md]
files_expected_to_change: [game/tools/, game/tests/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
board_approved_art: yes only for a ticket that swaps in art the board has already approved, with no code or data change; it skips QA and the tests (tasks/README.md, "QA"). Default no.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board, 2026-11-01 (HUD and menus, Decisions, "The board passes through every menu and text before the MVP"): before the MVP release the board reviews every menu and every piece of player-facing text. Build the material for that review, by script, so it can be rebuilt after every change.

1. A script (headless, like the other screenshot tools in game/tools/) that opens every screen the player can meet and saves a screenshot of each: splash and main menu, tutorial slides, garage, the run's HUD (with the mission notebook page), the level-up gift pack, the driving power-up overlay, the pause screen and its settings (the HUD layout editor included), the end-of-run recap, and any other screen it finds. One PNG per screen, at 1280 x 720, into an output folder outside game/ (git-ignored), with a manifest JSON listing each screen's name, file and how it was reached.
2. A text inventory: every player-facing string the game can show (the text files, labels set in scenes or code, popups, mission phrasings, power-up and weapon names and descriptions), as one JSON or CSV with its key or source file, the text itself, and the screen it appears on. List strings found in code rather than in a text file separately.
3. Say in docs/hud-and-menus.md (Content) how to rebuild both.

No game behaviour changes. Never write, move or commit anything in game/data/levels/.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] Running the script makes one screenshot per screen listed in the description, plus a manifest naming each one; the result notes list the screens and any screen it could not reach, with why. (QA: pass / fail)
- [ ] The text inventory lists every string in the game's text files, with key, text and screen, and lists strings found in code separately; the result notes give the counts. (QA: pass / fail)
- [ ] A test runs the inventory on a small fixture and checks its output format. (QA: pass / fail)
- [ ] docs/hud-and-menus.md (Content) says how to rebuild the gallery and the inventory. (QA: pass / fail)
- [ ] No game script or scene behaviour changes (the diff touches only tools, tests and docs). (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `GUT_TIME_LIMIT=1500 GODOT_BIN="C:\Tools\Godot\Godot_v4.6.2-stable_win64.exe" bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)
- [ ] Nothing under game/data/levels/ is changed or committed. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.
