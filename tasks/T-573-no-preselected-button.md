---
id: T-573
title: No button looks selected when a menu opens
status: needs-playtest
from: project-lead
to: ui
lead: Rails
epic: ui
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, game/scripts/ui/key_nav.gd, game/scripts/menu/garage_screen.gd, game/scripts/menu/cosmetics_screen.gd, game/scripts/menu/main_menu.gd, game/scripts/menu/settings_screen.gd, game/scripts/menu/tutorial_slides.gd, game/scripts/ui/pause_screen.gd]
files_expected_to_change: [game/scripts/menu/, game/scripts/ui/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
model: sonnet
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

Build HUD and menus, Decisions, "No button looks selected when a menu opens". The board's bug: entering the garage and the Cosmetics screen shows the first available button as selected (they call grab_focus() on open: garage_screen.gd, cosmetics_screen.gd). Fix those, then check every other menu and screen that does the same (main menu, Settings screen, tutorial slides, pause screen, trick list, HUD layout editor, god mode page, level-up and other screens; grep for grab_focus) and fix them the same way. Keyboard play must keep working: no button looks selected until the player presses a key that moves between buttons (arrows, Tab), and that first press shows the selection where it starts. Mouse hover is unchanged. Prefer one shared way (for example in key_nav.gd) over a fix per screen. Propose what Enter or Space does on a screen where nothing looks selected yet (keep today's action where a screen relies on it, for example the level-up cards or the tutorial's Go live), and list each screen's behaviour in the result notes. Your branch starts from the board's menu fixes build (playtest/menu-fixes: T-568, T-569, T-571, T-572), so the Settings screen is there.

The board's review: play it in the menu fixes build (the Project Lead merges your branch into C:\solid-carbide-worktrees\playtest-menu-fixes once QA passes): open the garage, Cosmetics, Settings and the other menus with the mouse, then use the arrows.

Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. No PixelLab calls. Run tests in the foreground only, one command at a time, and leave no background job running. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The garage and the Cosmetics screen open with no button shown as selected (tests). (QA: pass)
- [ ] Every other menu or screen that selected a button on opening does the same, listed in the result notes (tests for each). (QA: pass)
- [ ] Arrows or Tab still move the selection, and the first press shows it (tests); mouse hover works as before. (QA: pass)
- [ ] docs/hud-and-menus.md Content and game/docs/hud-and-menus/ describe it. (QA: pass)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass)
- [ ] Screenshots in art-archive/T-573/screenshots/ show the garage and Cosmetics screens just opened, and after one arrow press. (QA: pass)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-08, Open → In progress

Started: UI fixes the preselected buttons in every menu.

### 2026-11-08, In progress → In QA

Built: no menu preselects a button (shared KeyNav helper). QA now.

### 2026-11-08, In QA → Needs playtest

QA passed (6/6). In the menu fixes build for your playtest.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done. No button is selected when a screen opens; one shared way in KeyNav (game/scripts/ui/key_nav.gd): clear_selection (replaces grab_focus on open and on coming back), reveal_selection / handle_keys (first fresh arrow, Tab, W, A, S or D selects the screen's start button and nothing else; later presses move as before; echo ignored; hidden start ignored). Mouse hover and clicks untouched.
Per screen (start button / Enter or Space with nothing selected, a proposal): Main menu: Start / starts the run (as before). Garage: first Buy shown (Back if none) / selects it, buys nothing. Cosmetics: first action shown (Back) / selects it. Settings: Back / selects it. Tutorial slides: right arrow, Go live on the last slide, none on trick slides / presses it (as before); once a key selected a button the selection follows the slides, a trick slide clears it. Pause screen: Resume / selects it, never resumes. Trick list: Back / selects it. God mode page: Back / selects it. HUD layout editor: Done / selects it. Returning to the pause strip from the trick list, god mode or HUD editor selects nothing (arrows then select Resume). Level-up, power-up, recap and the trick list rows never grabbed focus: unchanged (a test greps for it).
Kept: garage and Cosmetics hand the selection on when the selected button hides (maxed Buy, picked effect); only happens if the player had selected it.
Tests: new game/tests/unit/test_no_preselected_button.gd (21 tests: every screen opens with none; first key selects start; Enter rules; held key; hidden menu). Updated 11 old tests that expected the preselection (menu arrow keys, main menu, garage pulse, settings, tutorial, pause, trick list, god mode). Full run: 3103 tests, 3102 passing, 0 failing, 1 risky (was 3082 before).
Docs: docs/hud-and-menus.md (Content, "Nothing is selected when a screen opens"; Settings keyboard line), new game/docs/hud-and-menus/keyboard-selection.md.
Screenshots (art-archive/T-573/screenshots/): t573_garage.png, t573_garage_key.png, t573_cosmetics.png, t573_cosmetics_key.png (just opened, then after one Down press). Fixtures game/tests/fixtures/t573_*.
Documents affected: docs/hud-and-menus.md, game/docs/hud-and-menus/keyboard-selection.md. Long GDD not regenerated (Project Lead's merge step).
