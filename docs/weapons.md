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

### Unity prototype weapons

Facts from the Unity prototype weapons report (sections 1 to 5). No new decisions.

- The prototype's starting gun is its "Simple Gun" (`SimpleGunWeapon`, data asset `Weapon_MachineGun`): the only weapon on the car when a run starts.
- The gun checks for living enemies within 12 units of the car's centre every 1.26 seconds and fires one bullet at the closest. Bullets fly straight from the car's centre at 15 units per second, deal 2 damage, and are removed on their first hit. Bullets that miss are never removed.
- The Flame Exhaust is on while the car is drifting (W or S held with A or D) at 0.85 units per second or more, and for 0.2 seconds after. It damages enemies inside a rectangle behind the car that starts each drift at half size and reaches full size (about 2.6 wide and 3.25 deep) after 1 second of drifting.
- An enemy entering the flame takes 2 damage at once, and every enemy inside takes 2 more every 0.2 seconds. The flame takes this damage from the gun's stats; its own asset's damage (1) is not used.
- Each weapon has 8 tiers: getting it is tier 1, and each later pick applies the next of 7 upgrades. The gun gets more bullets, faster fire, a wider range and, last, bullets that pierce the first enemy. The flame gets a bigger area, more damage, a longer burn flash, faster car steering and, last, an always-on flame.
- The prototype's level-up offers 3 choices drawn at random from power-ups, new weapons and the next tiers of owned weapons. A weapon at tier 8 is no longer offered, and when nothing is left the only choice is 4 coins.
- The report lists every value with its source, the differences from Solid Carbide's level-up flow, notes on porting to Godot, and open questions for the board: [weapons/unity-weapons-report.md](weapons/unity-weapons-report.md).

## Open questions

- (After MVP) Upgrading how often the starting gun fires.

## References

- Unity prototype weapons report: [weapons/unity-weapons-report.md](weapons/unity-weapons-report.md).
