---
id: T-479
title: The board's MVP pass: a gallery of every screen and a list of every player-facing text
status: in-progress
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

### 2026-11-01, Open → In progress

Started: the screen gallery and text list for the board's MVP pass.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built by the QA/Integration agent (sonnet).

**Files:** `game/tools/screen_gallery.gd` (the in-game walk-through, run in a real window), `game/tools/screen_gallery.py` (runs it, checks the manifest against the PNGs, writes the text list too), `game/tools/text_inventory.py`, their tests `game/tools/test_text_inventory.py` and `game/tools/test_screen_gallery.py`, and docs/hud-and-menus.md (Content, "The MVP pass: the screen gallery and the text list (T-479)"). No game script or scene changed.

**Rebuild:** `python game/tools/screen_gallery.py` (about 30 s) and `python game/tools/text_inventory.py`. Output: `screenshots/mvp-gallery/` at the repo root (git-ignored): 19 PNGs at 1280 x 720, `manifest.json`, `text_inventory.json`, `text_inventory.csv`. The game's saves are pointed at throwaway `user://gallery_*` files.

**Screens captured (19):** main_menu, tutorial_slide_1, tutorial_slide_2, tutorial_slide_3, garage, hud_run_start, hud_mission_page, hud_trick_popup, hud_combo_broken, level_up_gift_pack, power_up_overlay, pause_screen, pause_trick_list, pause_hud_layout_editor, time_up_screen, wreck, recap_win, recap_time_up, recap_wreck.
**Not reached (1):** the runs list (Past streams): its texts exist in runs_list_text.json but no screen in the game reads them yet. It is in the manifest's `not_reached`.

**Text counts:** 232 in all: 182 from text files (data/*_text.json, screen_texts.json, and the level-up cards' table level_up_texts.gd, a text table kept in code: 100 keys) and 50 found in code (listed separately, with file:line). 17 developer-tool scripts are skipped and named under `not_scanned`. The code scan goes by pattern; the board's pass is the check for anything built another way. 13 of the text-file strings are the runs list's, for a screen not in the game yet.

**Tests:** python game/tools: 861 OK (1 skipped); python tools: 633 OK; GUT: 2502 of 2502 passing (209 scripts), TESTS PASSED. New Python tests: 12 (the inventory on a small fixture folder, its JSON and CSV format, that every real string has a screen; the manifest check).

Nothing under game/data/levels/ touched. Untracked .uid and .import files Godot made are not committed.
