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
- **Air turn upgrade** (board, 2026-10-22): a fifth garage upgrade raises how fast the car spins in the air (Drifting, Decisions, "Slower air turn, upgradable"), from the new base of 1.25 times the ground rate. Its levels, prices and how much each level adds are the Game Data Agent's proposals (the Project Lead's suggestion: back up to today's 2.5 at the top level). Its name and description: T-268. (T-270)

## Content

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

### Saving

The player's coins and the level of each upgrade are kept in one small file under `user://` (`progress.json`), so they last between game sessions. A missing file means a new player: 0 coins, every upgrade at level 0. When a run ends, win or loss, the coins it collected are added to the total and saved. Buying an upgrade spends its price, raises its level by one and saves; it is refused, with nothing changed, when the player has too few coins or the upgrade is at its last level. The functions the garage screen and the run call are in `game/README.md` ("Game data", "Saving and buying").

### The garage screen (MVP)

A plain list (task T-058, `game/scenes/menu/garage_screen.tscn`, script `game/scripts/menu/garage_screen.gd`, `GarageScreen`). From the top: the heading, the player's coins, one row per upgrade, and a back button. Each row shows the upgrade's name and description, its current level, the price of the next level and a buy button. All text is the approved text from task T-059. Buying calls the save-and-buy object (`PlayerProgress`), and the whole screen redraws from it: the coins, the level and the price. When the player cannot afford the next level, the buy button is disabled and the row says "Not enough coins". At the last level the price and buy button go and the row says "Fully Funded". The back button only sends a signal; connecting it to the main menu, and the main menu's Garage button to this screen, is the screen flow's job.

## Open questions

- (After MVP) More upgrades, for example top speed, cruise speed, steering, drift grip, or other upgrades not about driving (the pickup magnet is now decided: Decisions, 2026-10-21).
- (After MVP) The garage screen's visual style.
- (After MVP) Unlockable cars with different driving styles (from this document's scope).

## References

- The upgrade prices and effects: `game/data/garage.json` (task T-056).
