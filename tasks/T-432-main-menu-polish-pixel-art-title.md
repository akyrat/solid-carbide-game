---
id: T-432
title: Main menu polish: pixel-art title, styled work-in-progress line, splash cover slot (placeholder)
status: done
from: project-lead
to: ui
lead: Goal-G-008
epic: hud-menus
milestone: mvp
goal: G-008
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/docs/hud-and-menus/main-menu.md, game/scripts/menu/main_menu.gd, game/scenes/menu/main_menu.tscn, game/tests/unit/test_main_menu.gd, game/fonts/bangers/bangers.json]
files_expected_to_change: [game/scripts/menu/main_menu.gd, game/scenes/menu/main_menu.tscn, game/fonts/, game/tests/unit/test_main_menu.gd, docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md]
model: sonnet
qa_rounds: 1
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

Goal G-008, 'Main menu polish' (HUD and menus, Decisions) and Visual style, Decisions, 'The splash cover'. Give the title 'SOLID CARBIDE' a free pixel-art font, with its licence and a record next to it in game/fonts/ (like fonts/bangers/). Keep '(work in progress)' word for word and style it to match the title. Add the splash cover slot: when game/art/menu/splash.png exists, it fills the screen behind the title and buttons, cropped not stretched, with hard pixel edges (nearest filtering); when it doesn't, a plain dark placeholder shows. The splash art itself comes from a later Asset Generation ticket. Start, Garage and Exit keep their texts and signals and stay readable over the image. No new text.

The board's review: Open the main menu: the pixel-art title, the styled '(work in progress)' line and the dark placeholder behind them.

## Acceptance criteria

- [ ] The title 'SOLID CARBIDE' uses a pixel-art font whose licence file and record are in game/fonts/<font>/; '(work in progress)' is unchanged word for word and styled to match (screenshot). (QA: pass)
- [ ] Tests show the menu fills the screen with game/art/menu/splash.png (cropped, aspect kept, nearest filtering) when it exists, and with a plain dark placeholder when it doesn't, at 1152 x 648 and 3440 x 1440. (QA: pass)
- [ ] Tests show Start, Garage and Exit keep their texts, still send start_pressed, garage_pressed and exit_pressed, and focus starts on Start. (QA: pass)
- [ ] docs/hud-and-menus.md, Content, 'Main menu' and game/docs/hud-and-menus/main-menu.md describe the title font, the line's style and the splash slot. (QA: pass)
- [ ] Screenshots of the menu with the placeholder and with a test image are in art-archive/<id>/screenshots/. (QA: pass)
- [ ] All three test sets pass, with the counts in the result notes. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Goal runner (G-008): started, in C:\solid-carbide-worktrees\T-432.

### 2026-10-30, In progress → In QA

Goal runner (G-008): the agent is done; QA is checking it.

### 2026-10-30, In QA → Needs playtest

Goal runner (G-008): QA passed; merged into playtest/G-008.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (UI Agent). 0 PixelLab generations; no style loop (a free font, no new text, no generated art).

- Title and "(work in progress)" now use Press Start 2P (SIL OFL 1.1) in `game/fonts/press_start_2p/` (TTF, OFL.txt, `press_start_2p.json` record with hashes), fetched by `game/tools/fetch_pixel_font.py`. Title 56 px cyan, line 16 px pale; both with a near-black outline and nearest filtering. Texts unchanged.
- Splash slot in `main_menu.gd`: if `res://art/menu/splash.png` exists, a `TextureRect` (keep-aspect-covered, ignore-size expand, nearest filtering) fills the screen behind the menu under a 35% black scrim; else the plain dark navy `background` shows. `splash_path` can be set before entering the tree (tests). Menu layers now use `set_anchors_and_offsets_preset` so they really fill the screen.
- Tests (`test_main_menu.gd`): font and licence files, placeholder, splash cropped/nearest/fills at 1152x648 and 3440x1440, focus on Start, texts and signals. test_main_menu: 9/9 passed (35 asserts).
- Full suite: GUT 2145/2145 passed; `unittest discover -s game/tools` 736 tests OK (1 skipped); `unittest discover -s tools` 582 tests OK.
- Docs updated: docs/hud-and-menus.md (Main menu), game/docs/hud-and-menus/main-menu.md.
- Screenshots: art-archive/T-432/screenshots/menu_placeholder.png and menu_test_image.png (test image from `game/tools/menu_splash_shots.py`, removed again; no splash.png is committed).
- Refusals: none.

QA round 1: all six criteria pass. `python tools/qa_check.py` needed an approval QA doesn't have (skipped); checked by hand. test_main_menu 9/9; unittest game/tools OK; unittest tools 582 OK. GUT full run: 2144/2145 on first run, one timing-sensitive failure in test_run_likes.gd (unrelated to the menu; it failed on a different test in a second rerun and passed 18/18 on a third), so treated as flaky. Screenshots present and show the pixel title, styled line, test image cover. Docs mention the font and splash.
- 2026-10-30, in-qa → needs-playtest: QA passed every criterion (goal G-008).
- 2026-10-31, needs-playtest → done: The board's playtest of G-008: LGTM (2026-10-30)
