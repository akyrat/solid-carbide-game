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

## Content

### Saving

The player's coins and the level of each upgrade are kept in one small file under `user://` (`progress.json`), so they last between game sessions. A missing file means a new player: 0 coins, every upgrade at level 0. When a run ends, win or loss, the coins it collected are added to the total and saved. Buying an upgrade spends its price, raises its level by one and saves; it is refused, with nothing changed, when the player has too few coins or the upgrade is at its last level. The functions the garage screen and the run call are in `game/README.md` ("Game data", "Saving and buying").

### The garage screen (MVP)

A plain list (task T-058, `game/scenes/menu/garage_screen.tscn`, script `game/scripts/menu/garage_screen.gd`, `GarageScreen`). From the top: the heading, the player's coins, one row per upgrade, and a back button. Each row shows the upgrade's name and description, its current level, the price of the next level and a buy button. All text is the approved text from task T-059. Buying calls the save-and-buy object (`PlayerProgress`), and the whole screen redraws from it: the coins, the level and the price. When the player cannot afford the next level, the buy button is disabled and the row says "Not enough coins". At the last level the price and buy button go and the row says "Fully Funded". The back button only sends a signal; connecting it to the main menu, and the main menu's Garage button to this screen, is the screen flow's job.

## Open questions

- (After MVP) More upgrades, for example top speed, cruise speed, steering, drift grip, or upgrades not about driving such as coin magnet range.
- (After MVP) The garage screen's visual style.
- (After MVP) Unlockable cars with different driving styles (from this document's scope).

## References

- The upgrade prices and effects: `game/data/garage.json` (task T-056).
