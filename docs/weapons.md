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

- The MVP has 2 weapons: the starting gun and the exhaust flamethrower (below). Each level-up offers 1 of them to choose. (2026-10-07; per level-up rather than per challenge since 2026-10-08)
- The final release has around 8 to 12 weapons, and each level-up offers 3 to choose from. (2026-10-07; per level-up since 2026-10-08)
- The Game Data Agent works out how weapon upgrades scale from level to level. (2026-10-08)
- **Starting gun:** the player starts every run with it. It has no visible weapon on the car, only the bullets it fires. It fires only when an enemy is within range, aims automatically, and fires at set intervals. (2026-10-08)
- **Exhaust flamethrower:** fires flames out of the car's exhaust, only while the car is drifting. (2026-10-08)

## Content

(To be written.)

## Open questions

- Starting gun: which enemy does it aim at when several are in range (for example the nearest)? Its range, interval and damage are balancing numbers for the Game Data Agent.
- Exhaust flamethrower: does it use the same "drifting" as XP (W or S held together with A or D; Game loop architecture, Decisions)? Does the flame point straight back from the exhaust, and does it damage every enemy it touches?
- (After MVP) Upgrading how often the starting gun fires.
- How many upgrade levels does each weapon have (the Final GDD says up to 20), what do upgrades change (the Final GDD says damage, projectile count or size, attack speed), and does choosing a weapon you already have upgrade it?

## References

(None yet.)
