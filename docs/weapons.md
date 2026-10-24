---
title: Weapons
gdd_order: 5
scope: Which weapons exist and their progression trees.
agents_work_on: [weapon-behavior]
agents_read: [game-data]
---

# Weapons

## Summary

The car's weapons fire on their own, so the player only drives. The MVP has five: a simple gun the player starts every run with, which automatically shoots at enemies in range, a flamethrower out of the exhaust that fires only while drifting, a neon underglow that hurts enemies around the car, molotovs that leave fire on the ground, and a windshield wiper that sweeps enemies away.

## Decisions

- The MVP has 2 weapons: the starting gun and the exhaust flamethrower (below); since 2026-10-18, 5 (the three new weapons, below). Each level-up offers a choice between them (the level-up flow below). (2026-10-07; per level-up rather than per challenge since 2026-10-08)
- The final release has around 8 to 12 weapons, and each level-up offers 3 to choose from. (2026-10-07; per level-up since 2026-10-08)
- **Size upgrades grow on screen** (board, 2026-10-24, after playing the game build): when a picked upgrade makes a weapon bigger (the wiper, the underglow, the flame), the weapon grows to its new size with a short animation instead of jumping to it. The damage area follows what is drawn. The timing is the Weapon Behavior Agent's proposal (T-286).
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
- The exhaust flamethrower does not switch off the drift smoke (unlike the Unity prototype): smoke and flames both show. (Since 2026-10-22 any enemy is hit when any part of it touches the drawn flame; see "A smaller exhaust flame that burns what it touches" below.) The kaiju is hit when any part of its body overlaps the flames. The starting gun's bullet size and its wait before the first shot stay as built (the Unity values). (board, 2026-10-14)
- **The flamethrower at height** (board, 2026-10-21): on a rooftop or in the air, the exhaust flames come out of the car's exhaust where the car is drawn, at its height, not somewhere else on the map; they burn what they touch at that spot. (T-206)
- **The underglow and the wiper at height** (board, 2026-10-21): the neon ring is drawn under the car at the car's height, so on a rooftop, a ramp or in the air it rises with the car instead of staying on the street; the windshield wiper's arm is lifted the same way. Their damage areas are unchanged. The molotov fire stays on the ground where the bottle landed, so it is not lifted. In the air the ring stays under the car (a proposal for the playtest). (T-225)
- **Three new weapons** (board, 2026-10-18), gained at a level-up like the flamethrower:
  - **Neon underglow:** neon lights under the car that make a circular area around it. Enemies inside take damage every second, and an enemy takes damage as soon as it enters the area.
  - **Molotovs:** thrown from the car at random, each one makes a circular area on fire where it lands. Enemies in a fire area burn and take damage.
  - **Windshield wiper:** one wiper in front of the car that sweeps in a semicircle, like a windshield wiper. Enemies it hits take damage and are knocked back. It is the only weapon that pushes enemies (the "never push enemies back" rule above is about the gun and the flamethrower).
  - They join the MVP, which then has 5 weapons. Each has 8 tiers like the gun and the flamethrower: getting it is tier 1, then 7 upgrades. Their numbers and what each tier changes are proposals by the agents, judged in the board's playtest.
  - Answers to the goal runner's questions (board, 2026-10-18): an enemy burns only while it is inside a molotov's fire area, not after it leaves. The windshield wiper sweeps all the time; it damages the kaiju but pushes only minions. The garage's damage bonus multiplies the damage of every weapon, the three new ones included. The starting gun's level-up card shows a small pixel-art gun.
- **A smaller exhaust flame that burns what it touches** (board, 2026-10-22, after playtests; replaces "a minion is in the flames when its centre is" of 2026-10-14): when the flamethrower is first picked up (tier 1) its flame is drawn 4 to 5 times smaller than today (a proposal of about a quarter of today's length and width), growing with its size tiers as before; it is drawn behind the car and behind the enemies, never over them; and its damage area is the flame as drawn, so a minion takes damage as soon as any part of it touches the visible flame (the kaiju as before, any overlap). (T-267)
- **A stronger wiper push** (board, 2026-10-22, after playtests): the windshield wiper's first level (tier 1, when it is picked up) pushes a minion back about twice the car's size; read as twice the car's length, 6 units (the car is 1 unit wide and 3 long), against 1.5 today. The later tiers keep their multipliers, so they grow from the new base. (T-266)
  - **Level-up offers with five weapons:** each level-up still offers 2 choices, now two different ones drawn at random from every choice available (getting a weapon the car doesn't have, or the next tier of one it has). The first level-up still offers "get the flamethrower" or "upgrade the gun".

## Content

### Garage damage bonus

The garage's damage bonus upgrade (Garage design) is applied at the start of every run: its percentage multiplies the damage of the gun and the flamethrower, on top of each weapon's own tier (the two multiply). Level 0 changes nothing. Built in T-062.

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
- The bullets are a small cyan neon ball with a white-hot core, pulsing in 2 frames, drawn about half a unit above the ground (art: T-071, drawn by script, `game/art/effects/bullet.png`).

### The exhaust flamethrower (built in task T-042)

What the built flamethrower does in the game. It follows Decisions (the prototype's Flame Exhaust with the board's fixes) and takes every number from [../game/data/weapons.json](../game/data/weapons.json). How the code is put together: `game/README.md`, "Weapons", "The exhaust flamethrower".

- **Owning it:** a run starts without it. It is one of the car's weapons next to the gun, gained at a level-up (the level-up offers, below), which also applies its upgrade tiers. A playtest switch (`game/data/playtest.json`, `flamethrower_at_start`) gives it to the car at the start of every run.
- **On and off:** on while the car is drifting (W, or S, held with A or D: the car's own drift state) at 0.85 units per second or more, and for 0.2 seconds after the drift ends. Driving straight, steering while standing still, or drifting slower than that never lights it. From tier 8 it is always on. It stops while the run is paused.
- **Area (T-267):** the flame as it is drawn, at every moment: the outline of the pixels of the flame art's current picture (its direction and flicker frame), at the drawn size, from the exhaust, pointing back. There is no separate rectangle any more. At tier 1 the flame is a quarter of its old size (size factor 0.625, was 2.5): about 30 screen pixels long at full size, 15 at the start of a drift. Each drift starts it at half size; it grows to full size over 1 second of drifting (always full size at tier 8). It is the same size on the screen whichever way the car faces.
- **Why the area and the art differed before (T-267):** the area was a rectangle from numbers in the data (3.25 units deep, 2.6 wide at full size, lined up with the car in the flat world), while the drawing was the 95-pixel plume scaled by the same size factor, but with no link to the rectangle: the plume was about twice as long as the rectangle's depth on the screen, the rectangle started 0.175 units behind the car's centre and the drawing 0.42, and a rectangle is not a teardrop. A minion counted only by its centre, so the flame could cover most of its body without burning it.
- **Where it starts (T-267, a proposal for the playtest):** the car's rear bumper, 1.2 units behind its centre (it was 0.42, under the car's body). At a quarter of the size the whole flame would otherwise sit under the car and not show.
- **Who is hit (T-267):** an enemy is hit when any part of its body touches the flame: its body circle (the minions' 0.5 units, the kaiju's own size) against the flame's outline. It replaces "a minion is inside when its centre is" (board, 2026-10-14; Decisions, 2026-10-22).
- **Damage:** an enemy entering the flame takes 2 at once and flashes orange for 0.38 seconds; every 0.2 seconds while the flame is on, every enemy inside takes 2 more. No limit on how many it hits, no push. It burns every enemy, through their damage function.
- **Tiers:** tiers 2, 4 and 6 make the flame, drawn and hit area, bigger (x1.2, x1.2, x1.3: size factor 0.75, 0.9, 1.17); tier 3 multiplies the damage by 1.2 (2.4 per hit, not rounded); tier 5 makes the flash 0.5 seconds longer; tier 7 makes the car turn 20% faster; tier 8 keeps it always on at full size.
- **Look:** a pixel-art flame plume (orange, yellow and a pale core) out of the exhaust in 32 directions, flickering between 2 frames, drawn behind the car and behind every enemy (one depth step under the car's, so also under enemies standing at the same depth; over the ground, rooftops and buildings), on the street, on rooftops and in the air, at the car's height. The drift smoke still shows with the flames (board, 2026-10-14). Enemies it burns show small flames on them (`burning_flames.png`). Art: T-071, from a PixelLab sample the board approved (`game/art/effects/exhaust_flame_sheet.png`).

### Numbers for the three new weapons (proposal, task T-166)

Proposals by the Game Data Agent for the board's playtest; the board judges and asks for changes. Numbers: [../game/data/weapons.json](../game/data/weapons.json). Each has 8 tiers (tier 1 is getting it; tiers 2 to 8 are 7 upgrades). Units and seconds as in the file. The garage damage bonus multiplies all of them.

- **Neon underglow:** circle of radius 2.5 around the car; 1 damage when an enemy enters and every 1 second inside. Tiers: 2 radius x1.2; 3 damage x1.5; 4 tick interval x0.75; 5 radius x1.25; 6 damage x1.5; 7 tick interval x0.67; 8 radius x1.3 (final: radius about 5.85, damage 2.25 every 0.5 seconds).
- **Molotovs:** one thrown every 3 seconds at a random spot 3 to 8 units from the car; fire area radius 1.5 lasting 3 seconds; enemies take 2 on entering and every 0.5 seconds while inside. Tiers: 2 radius x1.2; 3 throw interval x0.8; 4 damage x1.5; 5 one more molotov per throw; 6 fire lasts 1.5 seconds longer; 7 radius x1.3; 8 one more molotov per throw (final: 3 per throw every 2.4 seconds, radius 2.34, 4.5 seconds, 3 damage).
- **Windshield wiper:** one arm 2.5 units long sweeping a 180 degree semicircle in front of the car at 240 degrees per second; 3 damage per hit, the same enemy can be hit again after 0.5 seconds; minions are pushed back 6 units (twice the car's length), the kaiju is damaged but not pushed. Tiers: 2 length x1.2; 3 damage x1.4; 4 sweep speed x1.25; 5 knockback x1.5; 6 length x1.3; 7 damage x1.4; 8 sweep speed x1.3 (final: length 3.9, damage 5.9, knockback 9).

### The neon underglow (built in task T-168)

What the built underglow does in the game. It follows Decisions ("Three new weapons") and takes every number from [../game/data/weapons.json](../game/data/weapons.json) (the proposal above). How the code is put together: `game/README.md`, "Weapons", "The neon underglow".

- **Owning it:** a run starts without it. It is one of the car's weapons, gained and upgraded through the same call as the flamethrower (`upgrade("underglow")`), offered at a level-up (the level-up offers, below). A playtest switch (`game/data/playtest.json`, `underglow_at_start`, off) gives it at the start of every run.
- **Area:** a circle around the car's centre (radius 2.5 at tier 1), the same in every direction, moving with the car. A minion is inside when its centre is; an enemy that reports its body size, such as the kaiju, when any part of its body overlaps the circle (the flamethrower's rule).
- **Damage:** an enemy is hit on the step it enters, then every tick interval (1 second at tier 1) while it stays inside; each hit is the tier's damage times the garage damage bonus, through the enemy's damage function. No limit on how many it hits, no push. It stops while the run is paused and once the run has ended.
- **Leaving and coming back** (the Weapon Behavior Agent's proposal, for the board's playtest): each enemy has its own clock. An enemy that leaves and comes back before a tick interval has passed since its last hit is not hit again on entering; it is hit once its interval is over, if it is still inside. One that was out for longer is hit as it enters.
- **Tiers:** as the proposal above (radius, damage and tick interval multipliers), applied from code.
- **Look:** a placeholder neon ring drawn in code under the car, the circle as seen in the isometric view: opaque cyan with a darker inner line and a dark outline, never Redgull red, sized with the radius tiers. The final art replaces it.

### The molotovs (built in task T-169)

What the built molotovs do in the game. They follow Decisions ("Three new weapons" and the board's answer that an enemy burns only while inside) and take every number from [../game/data/weapons.json](../game/data/weapons.json) (the proposal above). How the code is put together: `game/README.md`, "Weapons", "The molotovs".

- **Owning them:** a run starts without them. They are one of the car's weapons, gained and upgraded through the same call as the others (`upgrade("molotov")`), offered at a level-up (the level-up offers, below). A playtest switch (`game/data/playtest.json`, `molotov_at_start`, off) gives them at the start of every run.
- **Throwing** (the Weapon Behavior Agent's proposal, for the board's playtest): a clock starts when the car gets them; each time it reaches the throw interval (3 seconds at tier 1), that tier's number of bottles leave the car's centre at once. Each lands at its own random spot: any direction around the car, at a distance picked evenly between 3 and 8 units. Where enemies are plays no part. A bottle takes half a second to land, along a small arc; this flight time is in the code, not the data.
- **Fire areas:** a circle on the ground where the bottle landed (radius 1.5 at tier 1), burning for the fire duration (3 seconds at tier 1), then gone. It does not move. Fire areas can overlap.
- **Damage:** an enemy inside a fire area is hit on the step it enters, then every tick interval (0.5 seconds) while it stays inside; each hit is the tier's damage times the garage damage bonus, through the enemy's damage function. An enemy that leaves takes nothing more (board, 2026-10-18). A minion is inside when its centre is; an enemy that reports its body size, such as the kaiju, when any part of its body overlaps the circle. Each fire area counts on its own, so an enemy inside two is hit by both (proposal). No push.
- **Pause and new run:** bottles in flight and fire areas stop while the run is paused or over, and a new run removes them all.
- **Tiers:** as the proposal above, applied from code. A fire area keeps the values of the tier it landed at.
- **Look:** placeholders drawn in code. The bottle is a small green bottle with a pale rag and a yellow flame, spinning as it flies. The fire is a flat circle on the ground, drawn under the buildings, enemies and car: orange with a yellow middle and a pale core, a dark rim and small yellow flickers. Never Redgull red. The final art replaces them.

### The windshield wiper (built in task T-170)

What the built wiper does in the game. It follows Decisions ("Three new weapons" and the board's answers: it sweeps all the time, damages the kaiju, pushes only minions) and takes every number from [../game/data/weapons.json](../game/data/weapons.json) (the proposal above). How the code is put together: `game/README.md`, "Weapons", "The windshield wiper".

- **Owning it:** a run starts without it. It is one of the car's weapons, gained and upgraded through the same call as the others (`upgrade("wiper")`), offered at a level-up (the level-up offers, below). A playtest switch (`game/data/playtest.json`, `wiper_at_start`, off) gives it at the start of every run.
- **The arm** (the Weapon Behavior Agent's proposal, for the board's playtest): one arm turning round a point on the nose of the car's body (half a unit ahead of its centre), 2.5 units long at tier 1. It sweeps from one side of the car to the other and back across the semicircle in front of the car (180 degrees) at 240 degrees per second, all the time, turning back at each end. The semicircle is fixed to the car, so it turns when the car turns.
- **Hits:** an enemy is hit when the arm touches its body as it sweeps. Each hit is the tier's damage times the garage damage bonus, through the enemy's damage function. **How often** (proposal): one enemy is hit at most once per pass (one sweep from one side to the other), and never twice within 0.5 seconds (the data's hit cooldown). So an enemy that stays in front of the car is hit about once per pass, about every 0.75 seconds at tier 1.
- **Knockback:** a hit minion is pushed 6 units (tier 1; 9 at the last tier) straight away from the car's centre, through the minion's knockback call (obstacles stop it). The kaiju is damaged but never pushed. The gun's bullets and the flamethrower still never push (tested).
- **Pause and new run:** the arm and its hits stop while the run is paused or over; a new run removes the wiper and puts the arm back to its start.
- **Tiers:** as the proposal above (length, damage, sweep speed and knockback multipliers), applied from code.
- **Look:** a placeholder wiper drawn in code: a dark steel arm with a pale grey rubber blade and a dark outline, from the car's nose out to the arm's tip, drawn over the car while it points down the screen and under it while it points up. Never Redgull red. The final art replaces it.

### Size upgrades grow on screen (built in task T-286)

What the built grow does. It follows Decisions ("Size upgrades grow on screen"). The numbers and reasons are the Weapon Behavior Agent's proposal for the board's playtest; the code is in `game/README.md`, "Weapons", "Size upgrades grow".

- **Which tiers grow:** the ones whose effect in `weapons.json` is a size. The windshield wiper's tiers 2 and 6 (arm length x1.2 and x1.3), the neon underglow's tiers 2, 5 and 8 (radius x1.2, x1.25, x1.3) and the exhaust flamethrower's tiers 2, 4 and 6 (flame size x1.2, x1.2, x1.3). Every other tier, and getting a weapon, plays no grow. The molotovs' tiers 2 and 7 (fire radius) play none either: each fire area is made when a bottle lands and keeps its size, so the next bottle just makes a bigger one and there is no standing weapon to grow (the board can ask for the fires on the ground to grow too).
- **When:** when the card or gift pack that raises the size is picked. The run is paused for the pick, so the grow starts as the game resumes and stands still while it is paused.
- **The curve (one place, `game/scripts/weapons/size_grow.gd`):** the size goes from the old size to the new one in **0.4 seconds** with a small overshoot (an ease-out-back, strength 3.0, about 20% of the step: a step is 20 to 30% of the size, so the size passes the new one by about 5% and settles) and ends exactly on the data's size. 0.4 seconds is long enough to read as growing and short enough that nobody waits for it; the overshoot is a small pop and not a wobble. The likes bar's spring (0.25 s, T-273) is the model; a weapon is bigger and further from the eye, so it gets a little longer.
- **Damage follows the drawing:** the wiper's reach, the underglow's circle and the flame's outline are all read from the size being drawn at each step, so nothing is hit outside what is drawn (and the overshoot is hit as drawn). Damage, timing and everything else are unchanged.
- **The wiper's art now follows its length (T-286):** the wiper's sheet was drawn for the first tier's 2.5 units and was never stretched, so the drawn blade stayed the same size at every tier while only the hit area grew. The art is now stretched by the arm's length over 2.5, so the drawing grows with the tiers and the hit area is the drawing. The underglow's ring and the flame already scaled with their size.

### The level-up offers (built in tasks T-043 and T-172)

What the built level-up offers do. It follows Decisions ("Level-up flow in the MVP" and "Level-up offers with five weapons"). The screen that shows them is a separate UI task; how the code is put together: `game/README.md`, "Weapons", "The level-up offers".

- When a level-up's weapon choice starts (the run is paused for it, Game loop architecture), the car's weapons decide the choices. Each of the five weapons gives at most one available choice: "get" it while the car does not have it, or "upgrade" it (its next tier) once it does, until its last tier (8). The gun is always owned, so it only has "upgrade the gun". That makes 9 possible choices: upgrade the gun, and get or upgrade the flamethrower, the neon underglow, the molotovs and the windshield wiper.
- Each level-up offers 2 different choices drawn at random, all equally likely, from every choice available at that moment. They are shown in a fixed order (gun, flamethrower, underglow, molotovs, wiper), not in the order drawn.
- The first level-up of a normal run (no choice taken yet, the car has only the gun) always offers "upgrade the gun" and "get the flamethrower", as Decisions says. Every level-up after that is drawn. A run that already starts with the flamethrower (its playtest switch) is not a normal run, so its first level-up is drawn too, and the flamethrower's upgrades are among the choices.
- Taking a choice applies it at once (the weapon at tier 1, or its next tier) and the run resumes. If several levels were reached at once, their choices follow one after another, each drawn on its own.
- A weapon at its last tier is not offered. If only one choice is left, the level-up offers just that one (the docs say nothing here; the simplest case was taken). If none is left, the choice is skipped and the run goes on, as Decisions says.
- **Playtest switch** `all_weapons_at_start` (`game/data/playtest.json`, false, never visible to players): true gives the car all five weapons at tier 1 at the start of every run, for the integration check and the board's playtest; the level-ups then offer only upgrades.

## Open questions

- (After MVP) Upgrading how often the starting gun fires.

## References

- Unity prototype weapons report: [weapons/unity-weapons-report.md](weapons/unity-weapons-report.md).
- Weapon numbers (base values and the 7 upgrade tiers of each weapon): [../game/data/weapons.json](../game/data/weapons.json), read through `game/scripts/data/weapon_data.gd`.
