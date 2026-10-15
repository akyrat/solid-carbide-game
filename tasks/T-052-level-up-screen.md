---
id: T-052
title: The level-up (gift pack) screen: 2 cards, take one
status: in-qa
from: project-lead
to: ui
lead: Weapons
epic: hud-menus
milestone: mvp
user_facing_text: yes
changes_visuals: yes
depends_on: [T-043, T-051]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/game-loop-architecture.md, docs/visual-style.md, docs/extended-narrative.md, docs/weapons.md, tasks/T-043-level-up-weapon-choices.md, tasks/T-051-text-level-up-screen.md, game/README.md]
files_expected_to_change: [the level-up screen scene and script, tests, game/data/playtest.json, docs/hud-and-menus.md, game/README.md]
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

**Blocked until T-043 (the choices) and T-051 (their text) are done.**

When the player levels up, turn on T-037's level-up pause so the run pauses and this screen shows the 2 choices T-043 offers, as plain cards: each with a title, a description and a button to take it (HUD and menus, Decisions). Taking one calls T-043's function, which applies it and resumes the run. Use exactly T-051's text. While the choice is open, Escape must not resume the run: the level-up pause shares the game pause with the Escape pause screen (T-037's note), so stop the pause screen from resuming while `state.is_waiting_for_choice()` is true.

**The board's choices (2026-10-15, HUD and menus, Decisions):**
- **Look:** the game's comic look, like the trick popups and the combo counter: white rounded cards with black borders, black text in the Bangers font with hard pixel edges, over the run dimmed behind it. No Redgull red. The highlighted card stands out clearly (for example a thicker border or the combo's yellow ring).
- **Input:** A/D or the left/right arrow keys move the highlight between the cards, Enter or Space takes the highlighted card; clicking a card's "Take it" button also takes it. The first card starts highlighted. Keys held down from driving when the screen opens must not take a card by accident (only a fresh press counts).
- **Which text:** T-043 offers ids (`upgrade_gun`, `get_flamethrower`, `upgrade_flamethrower`); T-051 has a title and description for `get_flamethrower` and one per tier for each upgrade id (`upgrade_gun.tier2` to `tier8`, `upgrade_flamethrower.tier2` to `tier8`). An upgrade card shows the text of the tier it would give (the weapon's current tier + 1). The two `weapon.*.name` rows are not used on this screen. Put the text in the game the way earlier UI tasks did (approved text, keyed).
- **Playtest switch:** set `flamethrower_at_start` in `game/data/playtest.json` to `false` in this task's branch (and its comment), so the board's first level-up offers "get the flamethrower" as the game's rule says. Tests that rely on it keep setting their own override.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test fires a level-up and shows the screen opens with 2 cards whose titles and descriptions are T-051's text for T-043's offered choice ids (QA: pass)
- [x] A test presses a card's button and shows T-043's function is called with that choice id and the screen closes (QA: pass)
- [x] A screenshot shows the level-up screen over the paused run (QA: pass)
- [x] A test shows an upgrade card shows the T-051 text for the next tier of that weapon (for example the gun at tier 3 offers `upgrade_gun.tier4`'s text) (QA: pass)
- [x] A test shows A/D and the arrow keys move the highlight, Enter and Space take the highlighted card, and a key already held when the screen opens takes nothing (QA: pass)
- [x] A test shows Escape does not resume the run or close the screen while the choice is open (QA: pass)
- [x] `game/data/playtest.json` has `flamethrower_at_start` false, and a test shows a normal run's first level-up offers `get_flamethrower` and `upgrade_gun` (QA: pass)
- [x] `docs/hud-and-menus.md` describes the screen in Content, without changing Summary, Decisions or Open questions (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the UI Agent (2026-10-15).

**How the board plays it:** open `C:\solid-carbide-worktrees\T-052\game\project.godot`, press Start, and drift. The first level-up comes at 100 likes, about 10 seconds of drifting at combo x1 (`drift_xp_per_second` 10; faster with a combo or a trick). The run pauses and the screen shows: left card the gun's tier 2 ("Bonus Bullets"), right card "Hot Take Exhaust" (the flamethrower). A/D or arrows move the yellow ring, Enter or Space takes the highlighted card, or click "Take it". After the flamethrower the next level-up offers both upgrades. Escape does nothing while the cards are open.

**Built:** `scripts/ui/level_up_screen.gd` (the screen, a child of the run, `run.level_up_screen`), `scripts/ui/level_up_texts.gd` (T-051's 32 rows, generated from its table), `run.gd` turns `state.pause_on_level_up` on and adds the screen, `pause_screen.gd` ignores Escape while `state.is_waiting_for_choice()`. `data/playtest.json` `flamethrower_at_start` is now false (comment updated). Docs: `docs/hud-and-menus.md` Content, "Level-up screen" (Summary, Decisions and Open questions untouched); `game/README.md`, "Level-up screen".

**Tests:** `tests/unit/test_level_up_screen.gd`, 19 tests, one per criterion and more (including a real mouse click). Full GUT suite 690 of 690 pass; `python -m pytest tools` 171 pass; `python -m pytest game/tools` 251 pass, 1 skipped. Screenshot: `art-archive/T-052/screenshots/level_up_screen.png` (made with `tests/fixtures/level_up_screen_demo.tscn`).

**Simple choices where the docs say nothing (please check):** layer 15 (over the HUD, under the pause screen); dim of 60% black; cards 360x300 with the banner "Redgull Sent a Gift Pack!" in a white rounded box above them; the "Take it" button is white with a yellow hover; the mouse hovering a card does not move the highlight; the highlight stops at the first and last card (no wrap); Tab/other keys do nothing. Any key held at open is ignored until released, and key-repeat is ignored. The cards' corners use a hard-edged (not smoothed) rounded box, not the popups' baked pixel art; if the board wants the exact stepped corners, that is a small follow-up.

### QA round 1 (QA/Integration Agent, 2026-10-15): all nine criteria pass

- **Opens with 2 cards, T-051 text: pass.** `test_level_up_opens_two_cards_with_the_approved_text` fires a level-up, checks 2 cards whose ids equal `offers.current_offers` and whose title/description are T-051's keys. Separately, a script compared all 32 card rows in `game/scripts/ui/level_up_texts.gd` with T-051's result notes table character for character: no mismatch, no extra keys; the two `weapon.*.name` rows are rightly left out.
- **Button takes it, screen closes: pass.** `test_pressing_a_cards_button_takes_it_and_closes` (T-043's `offer_taken` fires with the id, the flamethrower is applied, screen hidden, run resumed); `test_real_mouse_click_on_the_button_takes_the_card` does it with a real pushed mouse click.
- **Screenshot: pass.** Looked at `art-archive/T-052/screenshots/level_up_screen.png`: the dimmed run (car, HUD, timer) behind a white rounded banner "Redgull Sent a Gift Pack!" and two white black-bordered cards in Bangers (Bonus Bullets / Hot Take Exhaust), each with "Take it"; the first card has the yellow ring. No Redgull red on the screen (the only red is the board-approved HUD heart).
- **Next-tier text: pass.** Gun at tier 3 shows `upgrade_gun.tier4`; flamethrower at tier 4 shows `upgrade_flamethrower.tier5`. The code builds the key from the weapon's tier + 1.
- **Keys: pass.** A/D and both arrows move the highlight (first card starts highlighted, stops at the ends), Enter and Space take the highlighted card, key-repeat echoes do nothing, and a key held at open does nothing until released (the test injects the held-key check; the real one is `Input.is_physical_key_pressed`).
- **Escape: pass.** The pause action and `pause.toggle()` leave the run paused, the screen open, no pause screen on top; a normal run still pauses and resumes.
- **Playtest switch: pass.** `game/data/playtest.json` has `flamethrower_at_start` false with an updated comment; `test_normal_run_first_level_up_offers_flamethrower_and_gun_upgrade` reads the real file and gets `upgrade_gun` and `get_flamethrower`. Tests that need the flamethrower set their own `playtest_override`.
- **Docs: pass.** The diff of `docs/hud-and-menus.md` touches only Content (replaces "(The level-up screen: to be written.)" with a "Level-up screen" section); Summary, Decisions and Open questions unchanged. `game/README.md` has a "Level-up screen" section.
- **All tests: pass.** Full GUT suite 690/690 (61 scripts), `python -m pytest tools` 171 passed, `python -m pytest game/tools` 251 passed, 1 skipped.
- Board's choices checked as well: comic look (white StyleBoxFlat without anti-aliasing, black Bangers text with antialiasing off, 60% black dim, yellow `RING` highlight with a thicker border), keyboard and mouse input, next-tier text, playtest switch off. No Godot process left running from QA (the test runner stops its own).
- 2026-10-15, in-qa → needs-playtest: QA round 1: all nine criteria pass (qa-integration)
- 2026-10-15, needs-playtest → in-progress: when I level up the second and third time, I had to resize my windfow for it to refresh so i can see the level up options.

### Board's playtest, round 1 (2026-10-15): fix by the UI Agent

The board's note, word for word: "when I level up the second and third time, I had to resize my windfow for it to refresh so i can see the level up options."

**Cause:** the card title and description labels wrap their text but had no width of their own. When the cards were rebuilt for a later level-up, the wrapping labels were measured with no width (one word per line), so the box became far too tall and was centred with the cards pushed below the bottom of the window (a test showed them at y 1336 in a 648 pixel window) until a resize made the containers measure again. The first level-up worked because the first layout happened with the screen already set up. **Fix:** `level_up_screen.gd` gives each wrapping label a fixed width (`TEXT_WIDTH`, the card's width less margins and border), so the size is right from the first layout. **Check:** new test `test_later_level_ups_show_laid_out_cards_without_a_resize` (a 1152x648 window, three level-ups in a row, each time the cards are visible, at least 360x300, side by side and inside the window; it fails without the fix: 19 of 20 pass, and passes with it). Real windowed run: `tests/fixtures/level_up_screen_third_demo.tscn` plays Start, takes two cards and levels up a third time in the real renderer; screenshot `art-archive/T-052/screenshots/level_up_screen_third.png` shows the third level-up laid out and centred without any resize.
