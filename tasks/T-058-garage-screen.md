---
id: T-058
title: The garage screen: plain list of upgrades with buy buttons
status: needs-playtest
from: project-lead
to: ui
lead: Playtest
epic: garage
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-057, T-059]
documents_affected: [docs/garage-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/garage-design.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, tasks/T-057-save-and-buy.md, tasks/T-059-text-garage.md, game/README.md]
files_expected_to_change: [the garage screen scene and script, tests, docs/garage-design.md, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-057 (saving and buying) and T-059 (the text) are done.**

Build the MVP garage screen as Garage design, Decisions describes it, kept plain: a list of the three upgrades, each with its current level, the price of the next level and a button to buy it, plus the player's coins and a way back to the main menu (the back button sends a signal; T-055 connects it). Buying calls T-057's function; the screen shows the result, including "maxed" and "can't afford". Use exactly T-059's text.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A screenshot shows the three upgrades with level, price and buy button, the coins, and the back button (QA: pass)
- [x] A test buys an upgrade and shows the level, price and coins on screen update (QA: pass)
- [x] A test shows a maxed upgrade and an unaffordable one show T-059's messages and can't be bought (QA: pass)
- [x] A test shows every label is exactly T-059's text (QA: pass)
- [x] `docs/garage-design.md` describes the screen in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Updates

### 2026-10-15, Needs playtest

The garage screen is built: 'Redgull Pit Stop', the coins, one row per upgrade (name, description, level, price, Buy) and Back, all in T-059's approved text. Buying spends coins and raises the level; unaffordable rows say 'Not enough coins', maxed ones 'Fully Funded'. It's the plain MVP list, not yet styled. QA round 1: all 6 pass. Waiting for the board's playtest in the unified build; the main menu's Garage button (T-089) can only start once this is done.

## Result notes

Written by the UI Agent.

- Built `game/scenes/menu/garage_screen.tscn` + `game/scripts/menu/garage_screen.gd` (`GarageScreen`): heading, coins, one row per upgrade (name, description, level, price, buy button or status message), back button (`back_pressed` signal only). All text is T-059's approved text. Buying calls `PlayerProgress.buy`; the screen redraws from `progress.info()` and on `changed`. `progress` is set by the caller (`GameFlow.progress`), or read from the save file when standalone. Not wired to the main menu (T-089).
- Unaffordable: buy disabled, row says "Not enough coins". Maxed: price gone, buy hidden (kept in layout), row says "Fully Funded".
- Screenshot: `C:\solid-carbide-worktrees\T-058\screenshots\T-058_garage.png` (fixture `tests/fixtures/garage_screen_demo.tscn`: 120 coins, damage bonus maxed).
- Tests: `tests/unit/test_garage_screen.gd` (7 tests, RunPaths file). Full GUT suite 687/687 pass; `game/tools` Python tests (257) and `tools` Python tests (180) pass.
- Documents updated: `docs/garage-design.md` (Content only), `game/README.md` ("Garage screen").

**QA (round 1, 2026-10-15): all pass.**
- Screenshot: heading, coins, 3 rows with level/price/Buy (maxed row shows "Fully Funded"), Back button. Pass.
- Buy test (test_buying_updates_level_price_and_coins): level, price, coins update. Pass.
- Maxed/unaffordable tests: messages shown, buy disabled, no charge. Pass.
- Labels: all constants and the test's expected strings match T-059's table character for character (14 keys). Pass.
- docs/garage-design.md: only a new Content subsection added. Pass.
- GUT 687/687; game/tools Python 257 OK; tools Python 180 OK. Pass.
- Tests use RunPaths.file (user://test_runs/<pid>/), screen gets progress injected; real progress.json not touched.
- 2026-10-15, in-qa → needs-playtest: QA passed
- Board's tweak (2026-10-16): "change "sponsored throttle" to "energy throttle", that's my only comment". Changed the acceleration upgrade's name from "Sponsored Throttle" to "Energy Throttle" in `game/scripts/menu/garage_screen.gd` and `game/tests/unit/test_garage_screen.gd`. No other game code or docs used the text. GUT 687/687, `tools` Python 180, `game/tools` Python 257 (1 skipped) pass.
