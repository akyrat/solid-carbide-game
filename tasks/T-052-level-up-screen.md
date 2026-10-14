---
id: T-052
title: The level-up (gift pack) screen: 2 cards, take one
status: planning
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

Written by the agent when it finishes.
