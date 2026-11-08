---
id: T-571
title: A Settings screen opened from the main menu
status: done
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-570]
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/docs/hud-and-menus/main-menu.md, game/docs/hud-and-menus/pause-screen.md, game/scripts/menu/main_menu.gd, game/scripts/ui/pause_screen.gd, game/scripts/ui/game_settings.gd, tasks/T-567-main-menu-music-toggle.md]
files_expected_to_change: [game/scripts/menu/, game/scripts/ui/, game/scenes/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
model: opus
qa_rounds: 1
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

Build HUD and menus, Decisions, "A Settings screen from the main menu". A Settings button on the main menu (text from T-570) opens a screen with the pause screen's settings that make sense outside a run: the music volume (and the SFX volume only when `GameSettings.sfx_enabled()`), the camera zoom, Camera smoothing, Dynamic camera, Rain, the drift guide and the jump arrow. Left out: HUD size, the HUD layout editor, the trick list, Restart and Exit, Set min/max zoom and god mode. The values are the same saved settings the pause screen uses (read at open, saved like the pause screen's, applied at the next run), and a music change is heard at once in the menu's music. Reuse the pause screen's rows, look and save rules instead of copying them where you can (propose the cleanest split, for example shared row builders). Back and Escape return to the main menu. T-567 (cancelled) built a music toggle on its branch task/T-567-main-menu-music-toggle; read it for how the menu music volume is applied, but don't merge it.

The board's review: play it from C:\solid-carbide-worktrees\T-571\game\project.godot: open Settings from the main menu, change the music and the checkboxes, start a run and open the pause screen, quit and reopen the game.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Never run a real itch.io push (butler push) and never print .env values. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The main menu shows the Settings button; it opens the screen with exactly the listed settings, and Back and Escape return to the main menu (tests). (QA: pass - tests cover button, exact controls (SFX only with switch), Back and Escape)
- [ ] A change on the Settings screen is saved, shows on the pause screen in the next run and is kept after a restart; the music volume changes the menu's music at once (tests). (QA: pass - tests: saved, shown on next pause screen and fresh game flow, music applied to bus at once)
- [ ] The pause screen works as before (the existing tests pass). (QA: pass - pause tests pass (full GUT rerun 3068/3069, 0 failing))
- [ ] docs/hud-and-menus.md Content and game/docs/hud-and-menus/ describe it. (QA: pass - docs/hud-and-menus.md and game/docs/hud-and-menus/ updated)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass - 269 scripts, 3069 tests, 0 failing in the rerun, counts in result notes; one test failed once in qa_check's parallel run, passed on rerun (flaky, not identified))
- [ ] Screenshots in art-archive/T-571/screenshots/ show the main menu with the button and the Settings screen. (QA: pass - 4 screenshots in art-archive/T-571/screenshots/)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: UI builds the Settings screen.

### 2026-11-07, In progress → In QA

Built: the Settings screen from the main menu. QA now.

### 2026-11-07, In QA → Needs playtest

QA passed (6/6). Play it in the combined build: C:\solid-carbide-worktrees\playtest-menu-fixes\game\project.godot

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

UI Agent, 2026-11-07. Built the main menu's Settings screen.

What changed:
- game/scripts/ui/settings_rows.gd (new, SettingsRows): the shared pieces, slider_row() (label, slider without focus, bare value), check() (the shared checkbox) and SaveOnRelease (T-427's rule: save on drag release and on close). The pause screen now builds its zoom, SFX, music and HUD size rows and its checkboxes with them; its fields, look and behaviour are unchanged (screenshot t571_pause_screen_unchanged.png, all pause tests pass).
- game/scripts/menu/settings_screen.gd + game/scenes/menu/settings_screen.tscn (new, SettingsScreen): title (settings_title), a panel in the pause strip's look with Camera zoom level, SFX volume (only when GameSettings.sfx_enabled()), Music volume, then Camera smoothing, Dynamic camera, Rain, Drift Guide, Facing arrow; Back (settings_back). Labels are the pause screen's. Values read from GameSettings at open; sliders save on release and on Back/Escape; checkboxes save at once; the music slider applies to the Music bus at once (the menu music follows); zoom and camera options are read by the next run. Back and Escape (pause action) save pending and return to the menu. Keyboard: focus on Back, Up/Down to the checkboxes, Left/Right along them.
- game/scripts/menu/main_menu.gd: Settings button (settings_button) between Cosmetics and Exit, in the KeyNav chain, signal settings_pressed.
- game/scripts/game/game_flow.gd: show_settings(), the settings field, cleared in _clear_screens().
- Tests: new game/tests/unit/test_settings_screen.gd (13 tests: button, exact controls with SFX switch off/on, Back, Escape, read at open, music heard at once and one write on release, saved on Back, checkboxes saved at once, values on the next run's pause screen and in a fresh game flow, pause change shown here, keyboard order). Updated test_menu_arrow_keys.gd (Settings in the chain, Space presses it) and hud/test_shared_button.gd (5 shared buttons).
- Fixtures: game/tests/fixtures/t571_settings_demo.gd, t571_menu.tscn, t571_settings.tscn, t571_settings_sfx.tscn (throwaway settings file).

Tests: full Godot set (bash game/tools/run_tests.sh): 269 scripts, 3069 tests, 3068 passing, 0 failing, 1 risky/pending (pre-existing). A first full run had 1 failure (test_menu_enter_and_space_press_the_selected_button expected Exit one Down after Cosmetics); fixed in the test, then the full run passed.

Screenshots (art-archive/T-571/screenshots/): t571_menu.png (main menu with Settings selected), t571_settings.png (Settings screen, SFX switch off as in the MVP), t571_settings_sfx.png (with the SFX switch on), t571_pause_screen_unchanged.png (pause screen after the refactor).

Documents affected: docs/hud-and-menus.md (Content: new 'The Settings screen (T-571)'; the Rain and Drift Guide lines no longer say the pause screen is the only settings screen), game/docs/hud-and-menus/main-menu.md (Settings button, new 'Settings screen' section), game/docs/hud-and-menus/pause-screen.md (shared rows).

Proposals for the playtest: the button's place (after Cosmetics), the slider order (zoom, SFX, music, as on the pause screen), the plain dark background without the splash, and the panel's size. Not done: the screen gallery tool (game/tools/screen_gallery.gd) does not yet include the Settings screen.
- 2026-11-08, needs-playtest → done: Board: menu fixes build played, merge (2026-11-08)
