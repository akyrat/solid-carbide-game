---
id: T-320
title: The recap screen after every run, with pictures
status: in-qa
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

The look is the game's comic look (white rounded panels, black borders, the Bangers font, hard pixel edges, like the level-up screen). The stats may count up or pop in one by one (your proposal). The player leaves it with a Continue button (T-318's text) or an **X at the top right**, both to the main menu (board, 2026-10-29: Game loop architecture, Decisions, "The recap always closes a run"). Every run ends on it: after a time's up loss it comes after the time's up screen (T-317), and after a health loss after the 3-second wreck (T-360), whichever of those is merged first. The runs list (T-364) will reopen a saved run's recap in this screen, so keep it able to show a summary it is given. All text from T-318, word for word; the art is the game's existing sprites; no PixelLab.

The board's review: play a run to its end and read the recap.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] When a run ends (a win, a loss by health, a loss by time), the recap screen shows before the main menu, and its Continue button and the X at the top right both return to the main menu (tests for each ending). (QA: pass / fail)
- [ ] It shows each enemy type and each trick with a count above 0 with the right number, the highest combo, and each weapon used with its tier, from T-319's summary (test with a scripted run). (QA: pass / fail)
- [ ] Enemies and weapons are shown with their existing art (sprite, card image). (QA: pass / fail)
- [ ] Every label comes from T-318's data file; no text is written in the code. (QA: pass / fail)
- [ ] Game loop architecture's screen flow, HUD and menus, Content, "Recap screen" and game/README.md describe it. (QA: pass / fail)
- [ ] Screenshots (or a GIF for anything that moves) of the change in a run are in `art-archive/T-320/screenshots/`, as `tasks/README.md`, "Screenshots", asks. Shots after a win and after a loss. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes, and the new behaviour has its own tests. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-29, Open → In progress

Started (build B): the UI Agent is building the recap screen that closes every run, with Continue and the X, from your approved text.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**UI Agent, 2026-10-29: built.**

- **Screen:** `game/scripts/ui/recap_screen.gd` (`RecapScreen`) and `game/scenes/menu/recap_screen.tscn`. Full screen over the main menu's dark background, comic look (white rounded panels, 3 px black borders, black Bangers with hard pixel edges). From the top: the title for the ending (`title.win` / `title.time_up` / `title.wreck`) with the X at the top right; Takedowns (enemy sprite = first frame of `art/minion/minion_s.png` / `art/kaiju/kaiju_s.png`, cropped; name; "x{count}") beside Peak engagement (highest combo as "x5.59" in the combo counter's heated look, via its own `ComboHeat`: colour, glow, pulse); Tricks landed (each trick's plain trick popup, `TrickPopupArt`, then "x{count}", wrapping); Weapons used (level-up card image, name, "Tier {tier}"); Continue at the bottom. 0 counts are left out. `show_summary(summary)` takes any `RunState.recap()` dictionary, also one read back from JSON, for T-364.
- **Text:** every word from `game/data/recap_text.json`, word for word. The only non-file string shown is the count form "x{n}", reused from the HUD (`WeaponIcons.TEXT_COUNT`, the combo counter's approved form) for counts and the combo. The X is a pixel X drawn in code (no text); its tooltip/accessible name is `button.close`.
- **Flow (`game/scripts/game/game_flow.gd`, small and self-contained):** new `show_recap(summary)`, `recap` var, `recap_shown` signal; `_on_run_ended` now defers `show_recap(run.state.recap())` instead of `show_menu()`; the recap's `closed` (Continue, X or Enter) calls `show_menu()`; `_clear_screens()` also frees the recap. A health loss reaches it only after T-360's wreck (run_ended comes after the wreck). **For whoever merges T-317:** the time's up screen should call `show_recap(summary)` when it is done instead of going to the menu; `show_recap` takes any summary.
- **Proposals for the playtest:** a section with nothing to show (no kills, no tricks) is left out; the highest combo always shows (x1.00 base look with no tricks); enemies/tricks in the text file's order, weapons in the order taken; panels pop in one by one (title first) in stepped alpha frames, about 0.7 s, while Continue and the X work at once; Enter also continues; the buttons take no keyboard focus, so a drift key held from the run presses nothing; trick popups at their normal size.
- **No PixelLab**, existing art only.
- **Tests:** new `game/tests/unit/test_recap_screen.gd` (15 tests: titles per ending, counts above 0 only, trick popup images, weapon card images and tiers, enemy sprites, combo heat step, empty sections, JSON summary, every label from the text file, no words typed in the script, Continue/X/Enter close once, no focus, X at top right and nothing overlapping at 1152x648, pop-in, a scripted run). `game/tests/unit/game/test_screen_flow.gd` updated (28 tests): win, health loss and time loss each show the recap, then Continue and the X return to the main menu; the recap waits for the wreck; it shows what the run counted; a second run after Continue.
- **Test counts (all foreground, all pass):** `python -m unittest discover -s game/tools -p "test_*.py"`: 657 tests OK (1 skipped); `python -m unittest discover -s tools -p "test_*.py"`: 573 tests OK; `bash game/tools/run_tests.sh`: 1874/1874 passing, TESTS PASSED.
- **Screenshots** (`art-archive/T-320/screenshots/`): `recap_win.png` (after a win: all seven tricks, both enemies, six weapons), `recap_wreck.png` (after a health loss), `recap_time_up.png` (after a time loss). Fixtures: `game/tests/fixtures/recap_screen_{win,wreck,time_up}_demo.tscn` (script `recap_screen_demo.gd`, saves isolated with `TestSave.isolate()`).
- **Docs updated:** `docs/hud-and-menus.md` (Content, "Recap screen": the built screen), `docs/game-loop-architecture.md` (flowchart recap node; Content, "Screen flow"), `game/docs/game-loop/screen-flow.md`, new `game/docs/hud-and-menus/recap-screen.md`, `game/README.md` (index line). Left for the Project Lead: Game loop architecture's old decision "In the MVP there is no recap" (already superseded) and its open question "(After MVP) Which stats does the recap screen show...", which the board's 2026-10-28 decision now answers.

Board review files: art-archive/T-320/screenshots/recap_win.png, art-archive/T-320/screenshots/recap_wreck.png, art-archive/T-320/screenshots/recap_time_up.png
