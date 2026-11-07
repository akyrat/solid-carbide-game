---
id: T-553
title: The Cosmetics submenu from the main menu, and the jump arrow checkbox
status: in-qa
from: project-lead
to: ui
lead: Rails
epic: garage
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
board_approved_art: no
depends_on: [T-552]
documents_affected: [docs/hud-and-menus.md, docs/garage-design.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/garage-design.md, docs/visual-style.md, docs/extended-narrative.md]
files_expected_to_change: [game/scripts/ui/, game/scenes/, game/tests/, docs/hud-and-menus.md, docs/garage-design.md]
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

Build HUD and menus, Decisions, "A Cosmetics button on the main menu" and the checkbox of "The jump arrow", and the screen of Garage design, Decisions, "Cosmetics". (1) A Cosmetics button on the main menu, in the shared button style, opening a Cosmetics submenu: a list of the jump effects with their name, description, price or picked state, a preview of each effect (its animation once T-556's art is in; until then the placeholder from T-551 or a still), buy and equip through T-552's API, the coin count, and a way back; keyboard and mouse like the other menus. (2) A checkbox for the jump arrow in the pause screen's settings next to Drift Guide, showing and saving `jump_arrow_enabled` and switching the arrow at once (T-551 reads it). All texts from T-550's keys (listed in its result notes), no placeholder text.

The board's review: in the combined build, open Cosmetics from the main menu, buy and pick an effect, and switch the arrow in the pause settings.

This ticket is part of the grind overhaul (board, 2026-11-07; Drifting, Decisions, "The grind overhaul"; tickets T-550 to T-556). The board plays all of it at the end, in one combined build (branch playtest/grind-overhaul, with T-547's map and T-548's grind changes), so build what the decisions say and propose every number. Write result notes with `python C:/solid-carbide-game/tools/task_notes.py T-NNN --text "..."` (your ticket's id) and hand back in one short line (tasks/README.md, "Handing back"). Never write, move or change anything in game/data/levels/. Run tests in the foreground only, and leave no background job running when you hand back. If a hook or the permission system refuses an action, stop and tell the Project Lead; never get around it.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The main menu's Cosmetics button opens the submenu and Back returns (test). (QA: pass; opens and Back returns, tested)
- [ ] The submenu lists the 5 jump effects with T-550's names and descriptions, shows prices and the coin count, buys and equips through the API, and refuses a purchase without enough coins with T-550's text (tests). (QA: pass; 5 effects, prices, coins, buy/equip, refusal text tested; screenshots match)
- [ ] The pause screen's jump arrow checkbox shows and saves jump_arrow_enabled and fits the settings row (test). (QA: pass; saves via GameSettings.save_jump_arrow_enabled, tested; fits row in screenshot)
- [ ] Every text comes from T-550's keys (a search finds no hard-coded label). (QA: pass; no-hard-coded-label test, texts from cosmetics_text.json)
- [ ] docs/hud-and-menus.md and docs/garage-design.md Content describe the screens. (QA: pass; both docs changed with Content sections)
- [ ] The tests for the changed code pass (the agent) and QA's full run passes, with the counts in the result notes. (QA: pass; both test sets green (2960 tests, 0 failing per notes))
- [ ] Screenshots in art-archive/T-553/screenshots/ show the main menu with the button, the submenu (locked, bought, picked), and the pause settings with the checkbox. (QA: pass; 5 screenshots: menu with button, locked, bought, picked, pause checkbox)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-11-07, Open → In progress

Started: Cosmetics button and submenu, the Facing arrow checkbox, and wiring the picked effect to the car.

### 2026-11-07, In progress → In QA

Built: Cosmetics button and submenu, Facing arrow checkbox, picked effect wired to the car. QA now.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Done (UI Agent). Built:
- game/scripts/menu/cosmetics_screen.gd + scenes/menu/cosmetics_screen.tscn: the Cosmetics submenu in the garage's look: title, coins ("Coins: {n}", garage text), 5 rows (looping preview using JumpEffect.draw_placeholder, name, description, "Unlock for {price} coins" + Unlock, or "Flex it", or "Equipped"), message line for not_enough_coins, Back. Buying and picking go through PlayerProgress (buy_cosmetic, equip). Keyboard chain ends on Back; focus moves to Back when the picked button hides. Texts all from data/cosmetics_text.json (Back and the coin line reuse the garage's constants).
- Main menu: Cosmetics button between Garage and Exit, signal cosmetics_pressed, in the key chain. GameFlow.show_cosmetics (Back returns to the menu).
- Link (a): GameFlow._ready sets JumpEffectChoice.provider = progress.equipped_jump_effect (a run outside the flow, e.g. level creator, plays the dash cloud).
- Link (b) and checkbox: pause_screen.gd jump_arrow_check "Facing arrow" after Drift Guide, saves through GameSettings.save_jump_arrow_enabled, switches the arrow through the notifier. The row got too wide (it overlapped the HUD weapon icons in test_hud_layout), so the checkbox gap went from 24 to 14 px.
- game/tools/text_inventory.py: cosmetics_text entry no longer says "not in the game yet".
Tests: new game/tests/unit/test_cosmetics_screen.gd (8: button opens/Back returns, 5 effects with texts and prices, buy then pick, refusal text, key order, no hard-coded label, provider wiring (a), checkbox label/default/saving/notifier (b)). Updated test_shared_button (menu 4, pause 13), test_menu_arrow_keys (Cosmetics in the chain). Full GUT run: 258 scripts, 2960 tests, 2959 passing, 0 failing, 1 risky/pending. text_inventory tests OK.
Screenshots in art-archive/T-553/screenshots/: main_menu.png, cosmetics_locked.png (300 coins), cosmetics_bought.png, cosmetics_picked.png, cosmetics_pause.png (checkbox in the pause settings). Fixture: game/tests/fixtures/cosmetics_shot.tscn (env COSMETICS_SHOT=locked|bought|picked|pause).
Docs: docs/hud-and-menus.md and docs/garage-design.md (new Content sections).
Proposals for the playtest: preview loop 1.0 s + 0.4 s hold, the previews are the code placeholder (small; T-556's art replaces them in draw_placeholder).
