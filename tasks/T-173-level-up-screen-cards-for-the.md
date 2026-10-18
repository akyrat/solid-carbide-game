---
id: T-173
title: Level-up screen: cards for the new weapons, and a weapon image on every card (placeholder images)
status: in-qa
from: project-lead
to: ui
lead: Goal-G-002
epic: hud-menus
milestone: mvp
goal: G-002
user_facing_text: yes
changes_visuals: yes
depends_on: [T-171, T-172]
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, docs/weapons.md, game/scripts/ui/level_up_screen.gd, game/scripts/ui/level_up_texts.gd, game/scripts/weapons/level_up_offers.gd, game/tests/unit/test_level_up_screen.gd, game/tests/fixtures/level_up_screen_demo.gd, game/README.md]
files_expected_to_change: [game/scripts/ui/level_up_screen.gd, game/scripts/ui/level_up_texts.gd, game/tests/unit/test_level_up_screen.gd, game/tests/fixtures/level_up_screen_demo.gd, game/tests/fixtures/level_up_screen_demo.tscn, docs/hud-and-menus.md, game/README.md]
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

The level-up screen's weapon cards each show an image of the weapon (docs/hud-and-menus.md, Decisions, 2026-10-18), and the screen must show the six new choice ids from D7. Add the 24 card texts from D6's result notes to `level_up_texts.gd` word for word (no wording of your own; if a text is missing, say so in the result notes). Give every card an image of its weapon (gun, flamethrower, underglow, molotovs, wiper) above or beside its title, description and 'Take it' button; for now a placeholder image per weapon drawn in code, never Redgull red, in a slot the art task (D9) fills with the final images. The starting gun's card shows a small gun (board, 2026-10-18). Keep the red and gold frame, the build-up animation (T-141) and the keyboard and mouse rules as they are, and keep the text readable.

The board's review: Open the level-up screen screenshot and level up in a run from the task folder: each card shows its weapon's placeholder image with the new text.

## Acceptance criteria

- [ ] `level_up_texts.gd` holds D6's 24 texts word for word, and a test walks every choice id and tier `level_up_offers.gd` can produce and finds a non-empty title and description for each. (QA: pass: 24 rows checked 0 problems; walk test in 953/953 suite)
- [ ] A test shows each card has an image node showing its weapon's image, a different one per weapon; placeholder images contain no Redgull red. (QA: pass)
- [ ] The existing level-up screen tests (animation, keyboard and mouse) pass unchanged. (QA: pass)
- [ ] A screenshot fixture shows two cards with their images, titles, descriptions and 'Take it' buttons inside the red and gold frame, with no text overlapping the image or running outside the card. (QA: pass: screenshot checked)
- [ ] `docs/hud-and-menus.md` Content 'Level-up screen' and `game/README.md` 'Level-up screen' describe the image slot; the game's test set passes. (QA: pass: 953/953)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-18, Blocked → In progress

Goal runner (G-002): started, in C:\solid-carbide-worktrees\T-173.

### 2026-10-18, In progress → In QA

Goal runner (G-002): the agent is done; QA is checking it.

## Result notes

UI Agent, 2026-10-18.

**Texts.** `level_up_texts.gd` holds T-171's 24 cards (D6) word for word: `get_underglow`, `get_molotov`, `get_wiper` and `upgrade_<weapon>.tier2` to `tier8` for each, 80 entries in all. Copied from T-171's table, then checked by a new script, `python game/tools/check_level_up_texts.py` (it reads the task's table and compares it with the `.gd` file: "24 rows checked, 0 problems"; tests in `game/tools/test_check_level_up_texts.py`, one of which checks the real files). No text was missing and no wording is mine. `card_text(id)` now gives the next tier's text for every `upgrade_<weapon>` (it used to cover only the gun and the flamethrower).

**Weapon image.** Every card has a `WeaponImage` slot (64 x 64 px, centred above the title, then the title, description and "Take it"). `LevelUpScreen.weapon_image(weapon)` loads `res://art/level_up/weapon_<gun|flamethrower|underglow|molotov|wiper>.png` when the file exists, otherwise a placeholder drawn in code: 16 x 16 pixel grids (a small pistol for the gun, a tailpipe with a flame, a car inside a cyan ring, a green bottle with a lit rag, a wiper blade on its pivot), opaque or transparent only, no Redgull red (the gun's grip was first brown, which the red check caught, so it is now dark grey-brown). **For the art task (T-174):** add the five PNGs under those names (any size, square fits best; the slot keeps the aspect ratio, nearest filtering) and the screen uses them with no code change.

**Layout.** To give the image room without taking it from the text, the card grew from 360 x 300 to 360 x 374 px (74 px: the image and its 10 px gap). The highlight frame became a 9-slice (`NinePatchRect`, margin 10) of the same `highlight_frame.png`, so it keeps its 6-art-pixel border and still reaches 12 px past the taller card. The red and gold frame, the build-up animation and the keyboard and mouse rules are unchanged. The banner sits a little higher on screen because the box is centred.

**Tests** (`game/tests/unit/test_level_up_screen.gd`, 40 tests, all pass). New: every choice id and tier the offers can produce (gun tiers 1-7, the other four 0-7, 39 in all, each checked as offered by `available_offers()`) has a non-empty title and description; T-171's texts spot-checked word for word and every key present; a new weapon's next-tier text; each card has an image node showing its weapon's image, a different image per weapon (pixel data compared), and an upgrade card shows the same image; placeholders are 16 x 16, opaque or transparent only, transparent background, and no pixel reads as Redgull red (the same rule as `build_drift_mark.py`'s `is_redgull_red`); all 39 cards laid out in a 1152 x 648 window with the image, title, description and button inside the card's frame border, in that order, the description ending above the button and the card not growing; the highlight frame on the taller card. Changed: one existing text test, `test_exact_text_for_known_cards`, counted 32 entries and now counts 80 (32 + 48). The animation, keyboard and mouse tests are unchanged and pass. The whole GUT set and the Python tool tests (282) pass.

**Screenshots** (1152 x 648, after the build-up), in `C:\solid-carbide-worktrees\T-173\art-archive\T-173\screenshots\`:
- `level_up_screen.png`: the first offer, gun upgrade and flamethrower, with their images (`bash game/tools/screenshot.sh res://tests/fixtures/level_up_screen_demo.tscn <out.png> 120`).
- `level_up_screen_new_weapons.png`: underglow and molotovs (`level_up_screen_new_weapons_demo.tscn`).
- `level_up_screen_wiper.png`: gun and wiper (`level_up_screen_wiper_demo.tscn`).
The fixture got an `offer_ids` export so the two new scenes reuse it. It needs about 120 frames: at 40, as T-052's notes say, the cards have not slid in yet.

**Quality note.** The placeholders are small and simple (16 px at 4x), clear enough to tell the weapons apart; they only stand in until T-174.

**Files changed:** `game/scripts/ui/level_up_screen.gd`, `game/scripts/ui/level_up_texts.gd`, `game/tests/unit/test_level_up_screen.gd`, `game/tests/fixtures/level_up_screen_demo.gd`, new `game/tests/fixtures/level_up_screen_new_weapons_demo.tscn` and `level_up_screen_wiper_demo.tscn`, new `game/tools/check_level_up_texts.py` and `game/tools/test_check_level_up_texts.py`, `art-archive/T-173/screenshots/` (3 PNGs). `level_up_screen_demo.tscn` did not need a change.

**Documents affected:** `docs/hud-and-menus.md` (Content, "Level-up screen": the image slot, the taller card, the placeholders) and `game/README.md` ("Level-up screen": the image slot, `weapon_image`/`placeholder_image`, the file names for T-174, the texts check, the tests and fixtures). Both updated.

PixelLab: none used (0 generations). Refusals: none.
