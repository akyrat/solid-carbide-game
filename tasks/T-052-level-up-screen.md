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
qa_rounds: 0
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

- [ ] A test fires a level-up and shows the screen opens with 2 cards whose titles and descriptions are T-051's text for T-043's offered choice ids (QA: pass / fail)
- [ ] A test presses a card's button and shows T-043's function is called with that choice id and the screen closes (QA: pass / fail)
- [ ] A screenshot shows the level-up screen over the paused run (QA: pass / fail)
- [ ] A test shows an upgrade card shows the T-051 text for the next tier of that weapon (for example the gun at tier 3 offers `upgrade_gun.tier4`'s text) (QA: pass / fail)
- [ ] A test shows A/D and the arrow keys move the highlight, Enter and Space take the highlighted card, and a key already held when the screen opens takes nothing (QA: pass / fail)
- [ ] A test shows Escape does not resume the run or close the screen while the choice is open (QA: pass / fail)
- [ ] `game/data/playtest.json` has `flamethrower_at_start` false, and a test shows a normal run's first level-up offers `get_flamethrower` and `upgrade_gun` (QA: pass / fail)
- [ ] `docs/hud-and-menus.md` describes the screen in Content, without changing Summary, Decisions or Open questions (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: playtest it before it is merged (board, 2026-10-13: nothing user-facing merges before the board has played it).

## Result notes

Written by the UI Agent (2026-10-15).

**How the board plays it:** open `C:\solid-carbide-worktrees\T-052\game\project.godot`, press Start, and drift. The first level-up comes at 100 likes, about 10 seconds of drifting at combo x1 (`drift_xp_per_second` 10; faster with a combo or a trick). The run pauses and the screen shows: left card the gun's tier 2 ("Bonus Bullets"), right card "Hot Take Exhaust" (the flamethrower). A/D or arrows move the yellow ring, Enter or Space takes the highlighted card, or click "Take it". After the flamethrower the next level-up offers both upgrades. Escape does nothing while the cards are open.

**Built:** `scripts/ui/level_up_screen.gd` (the screen, a child of the run, `run.level_up_screen`), `scripts/ui/level_up_texts.gd` (T-051's 32 rows, generated from its table), `run.gd` turns `state.pause_on_level_up` on and adds the screen, `pause_screen.gd` ignores Escape while `state.is_waiting_for_choice()`. `data/playtest.json` `flamethrower_at_start` is now false (comment updated). Docs: `docs/hud-and-menus.md` Content, "Level-up screen" (Summary, Decisions and Open questions untouched); `game/README.md`, "Level-up screen".

**Tests:** `tests/unit/test_level_up_screen.gd`, 19 tests, one per criterion and more (including a real mouse click). Full GUT suite 690 of 690 pass; `python -m pytest tools` 171 pass; `python -m pytest game/tools` 251 pass, 1 skipped. Screenshot: `art-archive/T-052/screenshots/level_up_screen.png` (made with `tests/fixtures/level_up_screen_demo.tscn`).

**Simple choices where the docs say nothing (please check):** layer 15 (over the HUD, under the pause screen); dim of 60% black; cards 360x300 with the banner "Redgull Sent a Gift Pack!" in a white rounded box above them; the "Take it" button is white with a yellow hover; the mouse hovering a card does not move the highlight; the highlight stops at the first and last card (no wrap); Tab/other keys do nothing. Any key held at open is ignored until released, and key-repeat is ignored. The cards' corners use a hard-edged (not smoothed) rounded box, not the popups' baked pixel art; if the board wants the exact stepped corners, that is a small follow-up.

