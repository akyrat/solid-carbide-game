---
title: Garage design
gdd_order: 6
scope: The garage's visual UI style, persistent car upgrades, the current car stats display, and future scope for unlockable cars with different driving styles.
agents_work_on: [ui]
agents_read: [driving-drift, game-data]
---

# Garage design

## Summary

The garage is where coins earned in runs buy permanent upgrades for the car. It is opened from the main menu. In the MVP it sells three upgrades, each with about 10 levels: acceleration, car HP, and a damage bonus for the car's weapons, shown as a plain list.

## Decisions

- The garage is opened from the main menu (how the menus connect: Game loop architecture, Decisions). (2026-10-08)
- The MVP garage sells three permanent upgrades: **acceleration** (reaching top speed faster), **car HP**, and a **damage bonus** in percent for the car's weapons. (2026-10-08)
- Each upgrade has about 10 levels. The Game Data Agent works out each level's price and how much it improves. (2026-10-08)
- In the MVP the garage screen is a plain list: each upgrade with its current level, the price of the next level and a button to buy it, plus the player's coins and a way back to the main menu. Its visual style comes after the MVP. (2026-10-08)
- The player's coins and the upgrade levels bought are saved to disk, so they are kept between game sessions. (2026-10-09)
- **Pickup magnet upgrade** (board, 2026-10-21): the radius within which coins, gift packs and health drops are pulled to the car (Game loop architecture, Decisions, "Pickup magnet") is a garage upgrade, starting at 1 car length; its levels, prices and how far each level reaches are the Game Data Agent's proposals. Built in T-224 (proposal): 10 levels, radius 3.0 units (1 car length) at level 0, +0.6 units (a fifth of a car length) per level, 9.0 (3 car lengths) at level 10; prices 40, 50, 60, 80, 100, 120, 155, 190, 240, 300, the same curve as the acceleration upgrade. The numbers live in `game/data/garage.json`. Its name and description in the garage: T-223. (T-224)
- **Air turn upgrade** (board, 2026-10-22): a fifth garage upgrade raises how fast the car spins in the air (Drifting, Decisions, "Slower air turn, upgradable"), from the new base of 1.25 times the ground rate. Its levels, prices and how much each level adds are the Game Data Agent's proposals (the Project Lead's suggestion: back up to today's 2.5 at the top level). Built in T-270 (proposal): 10 levels, the value is the air turn's total multiplier of the ground rate, 1.25 at level 0 and +0.125 per level, 2.5 (today's old value) at level 10 (1.375, 1.5, 1.625, 1.75, 1.875, 2.0, 2.125, 2.25, 2.375, 2.5); prices 40, 50, 60, 80, 100, 120, 155, 190, 240, 300, the same curve as the acceleration and magnet upgrades. Reasons: an eighth of the ground rate per level is the old 2.5 split into ten even steps, so the top level gives back what T-269 took away; an air 360 off the tallest rooftop needs a total of about 1.9 (Drifting, T-269's notes), so it becomes reachable at level 6 (2.0, with a margin; level 5 gives 1.875, just short), and the air 180 is there from level 0; one shared price curve keeps the five upgrades comparable until the playtest. The run takes the bought level's value minus the base and passes it to the car's `apply_air_turn_bonus()` at every run's start (`CarTuning.apply_air_turn_upgrade`, called in `GameFlow.start_run()`); the drift prototype never gets it. The numbers live in `game/data/garage.json`. Its name and description: T-268. (T-270)
- **The car health upgrade adds hearts** (board, 2026-10-28): with hearts (Game loop architecture, Decisions, "Hearts instead of health points"), each level of the car health upgrade adds 1 heart to the 5 the car starts with. Its description names no number, so it stays as it is. (T-333) Data: `car_health` in `game/data/garage.json`, unit `hearts`, base 5, +1 per level to 15 at level 10; the 10 levels and their prices (40 to 300) are unchanged, they still make sense.
- **Pixel art icons for the upgrades** (board, 2026-10-29): each garage upgrade gets a small pixel art icon, shown beside its row in the garage. One art ticket per upgrade (acceleration, car health, damage bonus, pickup magnet, air turn), each icon its own PNG in `game/art/garage/<upgrade key>.png`, which the garage picks up on its own; placeholders drawn in code until then. Script-drawn first (no PixelLab go yet), in the bold comic look of the HUD's reaction icons. (T-365, T-366 to T-370)
- **A broken save never wipes progress** (board, 2026-10-30, audit): a save file that fails to load is never overwritten; the game keeps a backup of the last good save and loads it. Each save records its version, so a renamed upgrade keeps its level. The same goes for the runs list. (T-417) Built as: a save is written to a temp file and renamed; the previous good file becomes `<file>.bak`; a file that fails to load is renamed to `<file>.broken-<time>` and kept; `version` starts at 1 (a file with none is 1), and a renamed upgrade id is mapped in `PlayerProgress.ID_RENAMES`.
- **Cosmetics** (board, 2026-11-07): a **Cosmetics** submenu, opened from the main menu, where the player picks how the car looks in small ways. The first cosmetics are the jump effects (Drifting, Decisions, "A jump effect around the car"): the dash cloud is the default and free; the others are **unlocked with coins**, then picked there. The prices are proposals for the playtest. What is unlocked and which one is picked are saved with the player's progress. (T-552, T-553, T-556)

## Content

### Cosmetics data (T-552)

`game/data/cosmetics.json` lists the 5 jump effects in menu order, each with its price in coins and no text (names come from T-550's data). Prices, proposals for the playtest: **dash_cloud 0** (free, unlocked and picked from the start), **spring 150**, **jet_thrust 300**, **stunt_sparks 450**, **shockwave_ring 600**. Reasons: a run earns about 250 coins and the cheapest garage upgrade level costs 40 (the top levels 240 to 300), so the first effect is within reach after one run (about 0.6 runs), and each next one costs about another 0.6 runs, so all four cost about 6 runs together and sit beside the upgrades instead of competing with them.

The save (`progress.json`, same version and backup rules) gains `"cosmetics": {"unlocked": [ids], "jump_effect": id}`. A save without it (an old one) loads with dash_cloud unlocked and picked, and loses nothing; unknown ids are dropped and a pick that is not unlocked falls back to dash_cloud.

The API is on `PlayerProgress` (`game/scripts/data/player_progress.gd`; prices from `CosmeticsData`): `cosmetics_list() -> Array` of `{id, price, unlocked, equipped}` in menu order; `is_unlocked(id) -> bool`; `can_afford(id) -> bool` (known, still locked, enough coins); `buy_cosmetic(id) -> {ok, reason}` (spends the price, unlocks, saves, does not equip; refused with `NOT_ENOUGH_COINS`, `ALREADY_UNLOCKED` or `UNKNOWN_COSMETIC`, nothing changed); `equip(id) -> bool` (unlocked only, saves); `equipped_jump_effect() -> String`. `changed` is emitted after a buy or an equip. Tests: `game/tests/unit/test_cosmetics.gd`.

### Pickup magnet text (T-223)

The fourth upgrade's text, in the form of the other three (name up to 25 characters, description up to 80; T-224 uses it word for word, with the key `pickup_magnet`). It names no number, because the Game Data Agent proposes how far each level reaches.

| Key | Text | Length |
|---|---|---|
| garage.pickup_magnet.name | Brand Magnet | 12/25 |
| garage.pickup_magnet.desc | Coins and drops fly to you from further per level. | 50/80 |

### Air turn text (T-268)

The fifth upgrade's text, in the form of the other four (name up to 25 characters, description up to 80; T-270 uses it word for word, with the key `air_turn`). It names no number, because the Game Data Agent proposes how much each level adds.

| Key | Text | Length |
|---|---|---|
| garage.air_turn.name | Spin Doctor | 11/25 |
| garage.air_turn.desc | Spin faster in the air per level. More flips, more views. | 57/80 |

### Upgrade icons (T-365)

Each upgrade row begins with a small icon. The art is `game/art/garage/<upgrade key>.png` (a proposal: 16 x 16, drawn at 3x with hard pixel edges), one file per upgrade (`acceleration`, `car_health`, `damage_bonus`, `pickup_magnet`, `air_turn`); the art tickets T-366 to T-370 each add only their file and the garage picks it up with no code change. A missing file shows a grey pixel-square placeholder drawn in code, without text or Greenbull's colours. The rest of the row is unchanged. (Built in T-365: `game/docs/garage/garage-screen.md`.)

### Saving

The player's coins and the level of each upgrade are kept in one small file under `user://` (`progress.json`), so they last between game sessions. A missing file means a new player: 0 coins, every upgrade at level 0. When a run ends, win or loss, the coins it collected are added to the total and saved. Buying an upgrade spends its price, raises its level by one and saves; it is refused, with nothing changed, when the player has too few coins or the upgrade is at its last level. The functions the garage screen and the run call are in `game/docs/data/game-data.md` ("Game data", "Saving and buying").

- **Keyboard** (board, 2026-11-02, T-492): the garage works with the arrow keys alone. It opens with the first upgrade's Buy selected; Up and Down (or W and S) walk the Buy buttons in the list's order, then Back, and wrap round (Left and Right, or A and D, keep the selection where it is; W, A, S and D work exactly like the arrows, board, 2026-11-02); Enter or Space presses the selected button; the selection shows with the shared button's focus plate. A Buy that is too expensive ("Not enough coins") can still be selected (it just does nothing); a fully funded upgrade's hidden Buy is skipped, and if it was selected the selection moves to the next one. Only fresh presses count, so a key held when the screen opens does nothing. The mouse works as before. How it is built: `GarageScreen.focus_order` and `KeyNav` (`game/scripts/ui/key_nav.gd`).

### The garage screen (MVP)

A plain list (task T-058, `game/scenes/menu/garage_screen.tscn`, script `game/scripts/menu/garage_screen.gd`, `GarageScreen`). From the top: the heading, the player's coins, one row per upgrade, and a back button. Each row shows the upgrade's name and description, its current level, the price of the next level and a buy button. All text is the approved text from task T-059. Buying calls the save-and-buy object (`PlayerProgress`), and the whole screen redraws from it: the coins, the level and the price. When the player cannot afford the next level, the buy button is disabled and the row says "Not enough coins". At the last level the price and buy button go and the row says "Fully Funded". The back button only sends a signal; connecting it to the main menu, and the main menu's Garage button to this screen, is the screen flow's job.

### How the garage fits the window (T-470)

The whole list (heading, coins, the five rows and Back) is one column, measured at its natural size (descriptions wrap in a 300 px width so a long one never widens a row) and scaled to the largest size that fits the window, then centred. Every Buy button and Back are therefore fully on screen at any window size: the base 1152 x 648, 1920 x 1080, ultrawide 2560 x 1080 and small windows (960 x 540). It refits whenever the window is resized. Like the HUD (T-431) the column uses nearest filtering and the scale follows the window, but it has no size slider.

## Open questions

- (After MVP) More upgrades, for example top speed, cruise speed, steering, drift grip, or other upgrades not about driving (the pickup magnet is now decided: Decisions, 2026-10-21).
- (After MVP) The garage screen's visual style.
- (After MVP) Unlockable cars with different driving styles (from this document's scope).

## References

- The upgrade prices and effects: `game/data/garage.json` (task T-056).
