---
title: Weapons
gdd_order: 5
scope: Which weapons exist and their progression trees.
agents_work_on: [weapon-behavior]
agents_read: [game-data]
---

# Weapons

## Summary

The car's weapons fire on their own, so the player only drives. The MVP has two: a simple gun the player starts every run with, which automatically shoots at enemies in range, and a flamethrower out of the exhaust that fires only while drifting.

## Decisions

- The MVP has 2 weapons: the starting gun and the exhaust flamethrower (below). Each level-up offers a choice between them (the level-up flow below). (2026-10-07; per level-up rather than per challenge since 2026-10-08)
- The final release has around 8 to 12 weapons, and each level-up offers 3 to choose from. (2026-10-07; per level-up since 2026-10-08)
- The Game Data Agent works out how weapon upgrades scale from level to level, starting from the Unity prototype's upgrade values (below). (2026-10-08)
- **Starting gun:** the player starts every run with it. It has no visible weapon on the car, only the bullets it fires. It fires only when an enemy is within range, aims automatically, and fires at set intervals. (2026-10-08)
- **Exhaust flamethrower:** fires flames out of the car's exhaust, only while the car is drifting. (2026-10-08)
- Both MVP weapons copy the behaviour of the matching weapons in the board's Unity prototype (its starting gun and its Flame Exhaust): targeting, firing, the flame's shape and what turns it on. A report on how they work there is task T-022. (2026-10-08)
- Their upgrades also copy the Unity prototype's: the same upgrade tiers and what each tier changes. (2026-10-08)
- **Level-up flow in the MVP:** each level-up offers 2 choices and the player takes 1. The player starts every run with the gun, so the first level-up offers "get the flamethrower" or "upgrade the gun"; once the player has both, each level-up offers "upgrade the gun" or "upgrade the flamethrower". (2026-10-08)

## Content

(To be written.)

## Open questions

- (After MVP) Upgrading how often the starting gun fires.

## References

- Unity prototype weapons report: [weapons/unity-weapons-report.md](weapons/unity-weapons-report.md) (being written in task T-022).
