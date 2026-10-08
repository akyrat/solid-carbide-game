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

## Content

(To be written.)

## Open questions

- (After MVP) More upgrades, for example top speed, cruise speed, steering, drift grip, or upgrades not about driving such as coin magnet range.
- (After MVP) The garage screen's visual style.
- (After MVP) Unlockable cars with different driving styles (from this document's scope).

## References

(None yet.)
