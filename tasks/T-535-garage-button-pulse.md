---
id: T-535
title: The Garage button pulses when an upgrade can be bought
status: done
from: project-lead
to: ui
lead: Rails
epic: garage
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: []
documents_affected: [docs/hud-and-menus.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/garage-design.md, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [game/scripts/menu/, game/scenes/menu/, game/tests/, game/docs/hud-and-menus/, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 2
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

Build HUD and menus, Decisions, "The Garage button pulses when something can be bought". On the main menu, while the saved coins cover at least one garage upgrade that isn't at its last tier, the Garage button pulses gently (a slow scale or brightness pulse) with a slightly highlighted colour that suits the shared button style; otherwise it looks as today. Read prices and tiers from the garage's own data, not a copy. Keyboard focus and the arrow-key navigation must look and work as before. No new text.

The board's review: play the combined build from C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot before merging.

Never write, move or commit anything in game/data/levels/ (the board's own levels). SFX stay off. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Every number you choose is a proposal for the board's playtest: list each with its reason in the result notes and keep it in data where the code already reads data.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] With coins enough for a non-maxed upgrade the Garage button pulses; with too few coins, or every upgrade maxed, it doesn't (tests covering the three cases). (QA: pass, round 2 after the board tweak: light blue letters)
- [ ] Coming back from the garage after buying updates the state (test). (QA: pass, round 2 after the board tweak: light blue letters)
- [ ] docs/hud-and-menus.md Content describes it. (QA: pass, round 2 after the board tweak: light blue letters)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass, round 2 after the board tweak: light blue letters)
- [ ] Screenshots or a GIF in art-archive/T-535/screenshots/ show the main menu with the button pulsing and not pulsing. (QA: pass, round 2 after the board tweak: light blue letters)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-05, Open → In progress

Started: the agent is working in C:\solid-carbide-worktrees$t.

### 2026-11-05, In progress → In QA

Built: the Garage button pulses while an upgrade can be bought. QA is checking it.

### 2026-11-05, In QA → Needs playtest

QA passed. In the combined playtest build: C:\solid-carbide-worktrees\playtest-batch-1105\game\project.godot

### 2026-11-06, Needs playtest → In progress

The board's tweak: light blue letters only, no yellow tint. Back with the agent; merges after QA.

### 2026-11-06, In progress → In QA

Tweak in: light blue letters, no yellow tint or scale pulse. QA is checking it; it merges once QA passes.

### 2026-11-06, In QA → Needs playtest

QA passed after the board's tweak; the board approved merging.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Built: the Garage button pulses while the saved coins cover the next level of at least one non-maxed garage upgrade.
- game/scripts/menu/main_menu.gd: `progress` var, `can_buy_something()` (PlayerProgress.can_buy over GarageData.UPGRADES, so prices and tiers come from the garage data), `is_garage_pulsing()`, `refresh_garage_pulse()` (looping sine tween on the button's modulate and scale). game/scripts/game/game_flow.gd: `show_menu` passes `progress`; the menu is rebuilt on every return from the garage, so buying updates it. Focus and KeyNav untouched. No new text.
- Proposals (consts in main_menu.gd, no data file for the menu exists): PULSE_SECONDS 1.6 (slow gentle breath), PULSE_SCALE 1.05 (noticeable but not jumpy), PULSE_TINT (1.0, 0.85, 0.35) (warm yellow; multiplies the steel plate so it reads as a gold-grey highlight).
- Tests: game/tests/unit/test_garage_button_pulse.gd (8: enough coins, too few, all maxed, no progress, pulse really changes the button, return from garage after buying via GameFlow, in-place refresh, focus/chain unchanged). Ran with -gselect: test_garage_button_pulse 8/8, test_main_menu 9/9, test_menu_arrow_keys 14/14, test_screen_flow 28/28.
- Docs: docs/hud-and-menus.md Content (main menu paragraph); game/docs/hud-and-menus/main-menu.md.
- Screenshots in art-archive/T-535/screenshots/: pulsing_f20/f40/f60/f80.png (frames of the pulse; f60 near the peak) and not_pulsing.png. Made with fixtures game/tests/fixtures/t535_pulse_rich.tscn / t535_pulse_poor.tscn (+ t535_pulse_demo.gd). Still frames only, no GIF.
- Untracked .uid files for other scripts in the folder were left out of the commit.

QA round 1: all 5 criteria pass. qa_check: tests PASS (2 sets; tools set skipped), documents PASS (1 changed), screenshots PASS (5 files). Agent's tests: test_garage_button_pulse 8/8, test_main_menu 9/9, test_menu_arrow_keys 14/14, test_screen_flow 28/28; QA full run green. Docs line present in docs/hud-and-menus.md.
- 2026-11-06, needs-playtest → in-progress: The board: the Garage button's letters turn light blue; no yellow highlighting on the button. No board QA needed: pass QA and merge.

Board's tweak (2026-11-06): "just make the letters light blue, no button yellow highlighting."
- Removed the yellow modulate tint and the scale pulse. While an upgrade can be bought the Garage letters are light blue (LETTER_BLUE (0.45, 0.8, 1.0), reads on the steel plate), with a soft colour breath to LETTER_BLUE_PALE (0.75, 0.92, 1.0) over PULSE_SECONDS 1.6 (kept as a proposal; the letters are the only signal). Applied to the font colour states in LETTER_STATES; original colours restored when nothing can be bought. Consts in main_menu.gd.
- Tests updated: test_garage_button_pulse.gd 9/9 (blue letters, no tint, no scale, letters restored); test_main_menu 9/9, test_menu_arrow_keys 14/14, test_screen_flow 28/28.
- Screenshots replaced: art-archive/T-535/screenshots/letters_blue_f5.png, letters_blue_f50.png, not_pulsing.png (the earlier pulsing_f*.png and the yellow-tint notes above are superseded).
- Docs: docs/hud-and-menus.md (Decisions line and Content) and game/docs/hud-and-menus/main-menu.md updated.

QA (after the board's light-blue-letters tweak): all 5 criteria pass. qa_check: tests PASS (2 sets, tools skipped), documents PASS (1), screenshots PASS (3: letters_blue_f5, letters_blue_f50, not_pulsing). Docs (Decisions and Content in docs/hud-and-menus.md) describe the light blue letters, no tint, no scale pulse. Agent's tests: garage_button_pulse 9/9, main_menu 9/9, arrow_keys 14/14, screen_flow 28/28; QA full run green.
- 2026-11-06, needs-playtest → done: The board, after the playtest: light blue letters, no yellow highlighting; approved to merge once QA passes.
