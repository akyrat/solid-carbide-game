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
- A weapon at its last upgrade tier is no longer offered: the level-up offers the other weapon's next tier instead, and if both are at their last tier, the level-up is skipped and the run goes on. (2026-10-10)
- Where the Unity prototype's weapons behave in unexpected ways (Unity weapons report, section 7), the MVP copies them, with three fixes (2026-10-10):
  - **Copied:** the flame uses the gun's damage (2), not its own (1); the bullet's hit circle stays 2 units across, larger than it is drawn; the gun looks for a target only once per firing interval; the weapons never push enemies back; the flame's steering tier makes the car steer 20% faster, compounding; the flame's tier 5 only makes the burn flash last longer; reversing while steering counts as drifting, so the flame comes on.
  - **Fixed:** damage is not rounded to whole numbers, so the flame's "hotter flame" tier always adds damage; the flame's area is the same size whichever way the car faces; a bullet that misses is removed once it has flown past the gun's range.
- The exhaust flamethrower does not switch off the drift smoke (unlike the Unity prototype): smoke and flames both show. A minion is in the flames when its centre is; the kaiju is when any part of its body overlaps them. The starting gun's bullet size and its wait before the first shot stay as built (the Unity values). (board, 2026-10-14)

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

### The starting gun (built in task T-041)

What the built gun does in the game. It follows Decisions and the Unity prototype weapons report; the numbers are T-040's ([../game/data/weapons.json](../game/data/weapons.json)). How the code is put together: `game/README.md`, "Weapons".

- Every run starts with the gun at tier 1 and no other weapon; a new run puts it back to tier 1 and removes any bullets in flight. Nothing is drawn on the car, only the bullets.
- Every 1.26 seconds (at tier 1) the gun looks for living enemies whose centre is within 12 units of the car's centre. With none, it does nothing until the next check; with some, it fires a volley. It checks only at those moments, so an enemy that comes into range just after a check is shot at the next one.
- **Targeting rule:** the prototype's, closest first. Bullet 1 of a volley goes to the closest enemy in range, bullet 2 to the second closest, and so on, going round them again from the closest when there are more bullets than enemies. Bullets in a volley leave 0.05 seconds apart. Each leaves the car's centre aimed at its target's centre at that moment, with no leading, and flies straight on.
- Bullets fly at 15 units per second and hit an enemy whose body comes within 1 unit of the bullet's centre, dealing 2 damage through the enemy's damage function. A bullet is gone after its hit (after its second hit at tier 8), or once it has flown as far as the gun's range without hitting anything. Bullets never push enemies and pass through walls and boulders.
- The gun targets every damageable enemy, not only minions, so the kaiju will be shot as soon as it exists.
- The upgrade tiers (2 to 8) can be applied from code and change the gun as T-040's data says: 3 bullets a volley at tier 2 and 5 at tier 6, a shorter interval at tiers 3, 4 and 7 (1.06, 0.893 and 0.754 seconds), an 18-unit range at tier 5, and bullets passing through their first enemy at tier 8. Offering them at a level-up is built too (the level-up offers, below).
- The gun stops while the run is paused and once the run has ended.
- The bullets are placeholders for now: a small cyan dot with a white core and a dark outline, drawn about half a unit above the ground. The final bullet art comes from a separate art task.

### The exhaust flamethrower (built in task T-042)

What the built flamethrower does in the game. It follows Decisions (the prototype's Flame Exhaust with the board's fixes) and takes every number from [../game/data/weapons.json](../game/data/weapons.json). How the code is put together: `game/README.md`, "Weapons", "The exhaust flamethrower".

- **Owning it:** a run starts without it. It is one of the car's weapons next to the gun, gained at a level-up (the level-up offers, below), which also applies its upgrade tiers. A playtest switch (`game/data/playtest.json`, `flamethrower_at_start`) gives it to the car at the start of every run.
- **On and off:** on while the car is drifting (W, or S, held with A or D: the car's own drift state) at 0.85 units per second or more, and for 0.2 seconds after the drift ends. Driving straight, steering while standing still, or drifting slower than that never lights it. From tier 8 it is always on. It stops while the run is paused.
- **Area:** a rectangle behind the car, lined up with it, starting 0.175 units behind the car's centre. At full size it is 2.625 units wide and 3.25 deep, the same whichever way the car faces. Each drift starts it at half size; it grows to full size over 1 second of drifting (always full size at tier 8).
- **Who is inside:** a minion is inside when its centre is. An enemy that reports its body size, such as the kaiju, is inside when any part of its body overlaps the area (board, 2026-10-14).
- **Damage:** an enemy entering the flame takes 2 at once and flashes orange for 0.38 seconds; every 0.2 seconds while the flame is on, every enemy inside takes 2 more. No limit on how many it hits, no push. It burns every enemy, through their damage function.
- **Tiers:** tiers 2, 4 and 6 make the area bigger (x1.2, x1.2, x1.3); tier 3 multiplies the damage by 1.2 (2.4 per hit, not rounded); tier 5 makes the flash 0.5 seconds longer; tier 7 makes the car turn 20% faster; tier 8 keeps it always on at full size.
- **Look:** placeholder flames (orange and yellow squares) out of the exhaust, drawn just under the car, sized with the area. The drift smoke still shows with the flames (board, 2026-10-14). The final flame art replaces the placeholder.

### The level-up offers (built in task T-043)

What the built level-up offers do. It follows Decisions ("Level-up flow in the MVP"). The screen that shows them is a separate UI task; how the code is put together: `game/README.md`, "Weapons", "The level-up offers".

- When a level-up's weapon choice starts (the run is paused for it, Game loop architecture), the car's weapons decide the choices. There are 3 possible choices: upgrade the gun, get the flamethrower, upgrade the flamethrower. The gun's upgrade is offered while the gun is not at its last tier. The flamethrower is offered as "get" while the car does not have it and as "upgrade" once it does, until its last tier.
- So the first level-up of a normal run offers "upgrade the gun" and "get the flamethrower"; once the car has the flamethrower, each level-up offers "upgrade the gun" and "upgrade the flamethrower". A run that already starts with the flamethrower (the playtest switch) offers the two upgrades from the first level-up.
- Taking a choice applies it at once (the gun's or flamethrower's next tier, or the flamethrower at tier 1) and the run resumes. If several levels were reached at once, their choices follow one after another.
- A weapon at its last tier is not offered. If only one choice is left, the level-up offers just that one (the docs say nothing here; the simplest case was taken). If none is left, the choice is skipped and the run goes on, as Decisions says.

## Open questions

- (After MVP) Upgrading how often the starting gun fires.

## References

- Unity prototype weapons report: [weapons/unity-weapons-report.md](weapons/unity-weapons-report.md).
- Weapon numbers (base values and the 7 upgrade tiers of each weapon): [../game/data/weapons.json](../game/data/weapons.json), read through `game/scripts/data/weapon_data.gd`.
