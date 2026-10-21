---
title: Enemies
gdd_order: 4
scope: Which enemies exist, what they look like, how they move, deal damage and behave, including the boss.
agents_work_on: [enemy-behavior]
agents_read: [game-data]
---

# Enemies

## Summary

Each level ends with its own final boss; in the first level, Crash City, it is the kaiju. The MVP boss is a huge, slow sprite that walks toward the player and deals contact damage. Its one special move rains meteors that land as boulders, new obstacles on the roads. Weapons can damage it at any time.

## Decisions

- Each level ends with a different type of monster as its final boss. The kaiju is only the first level's boss. (2026-10-03)
- MVP boss: a sprite much bigger than the player, walking slowly toward the player, with contact damage. (2026-10-03)
- The boss has one special move. After a short animation, several meteors rain down at once. In 2D, each is a meteor sprite falling top to bottom, with an impact animation on landing. (2026-10-03)
- Before the meteors land, a danger warning area shows on the ground for 2 seconds. A meteor that lands on the player deals damage and knocks them back. (2026-10-03)
- Landed meteors become boulders, plain obstacles like the map's own, where they land. No challenge or arrow comes with them, since challenges are left out of the MVP (Level design, Decisions). (2026-10-03; plain boulders, 2026-10-11, replacing meteors laid out as a challenge with a guide arrow)
- A boulder left by a meteor stays for 10 seconds after it lands, then fades away and is gone. (board, 2026-10-15)
- A meteor never lands on a boulder left by an earlier meteor that is still there (standing or fading); once that boulder is gone, its spot is free again. (board, 2026-10-16; task T-147)
- **The kaiju can be damaged at any time.** It has no shield and no vulnerability windows. (2026-10-11; replaces becoming vulnerable only by completing its meteor challenges, 2026-10-03, and the shield, 2026-10-08)
- Over a run, the number of enemies grows slightly. Enemies do not get tougher. (2026-10-07)
- The MVP minion walks on four legs towards the player (how it looks: Visual style, Decisions). Its health, contact damage and knockback are balancing numbers for the Game Data Agent; it does not copy a Unity prototype enemy. (2026-10-08)
- The Game Data Agent proposes the kaiju's health, together with the player's weapon damage; the board judges it in playtests. (2026-10-08; no longer counted in vulnerability windows, 2026-10-11)
- The Game Data Agent, with the Enemy Behavior Agent, works out the balancing numbers: how enemy numbers grow over the 7 minutes (within "slightly"), the coin drop chance and amounts, and how often the kaiju drops meteors and how many. The board judges them in playtests. (2026-10-08)
- When the kaiju is defeated it always drops a few coins (100% chance). Its death ends the run straight away, so its coins are added to the run's coins as the run ends, without being picked up. (board, 2026-10-13)
- Where and how minions spawn, and how often their contact damage applies, are proposed by the Enemy Behavior Agent with the Game Data Agent; the board judges them in playtests. (2026-10-09)
- Killing the kaiju ends the run at once, as a win. (2026-10-09)
- The higher the player's combo (Game loop architecture, Decisions), the more minions spawn, on top of the slow growth over the run. It can be switched off, so the board can judge in playtests whether to keep it; the Game Data Agent proposes how strongly the combo raises spawning. (2026-10-10)
- Polish for the MVP, once the MVP is playable end to end: minions get a damage animation when hit, and when two minions bump into each other they fall down, get up again and carry on running at the car. How long they stay down is proposed by the Enemy Behavior Agent; the board judges it in playtests. (board, 2026-10-14)
- The kaiju walks round buildings and boulders, like the minions, rather than through them. (board, 2026-10-14)

- **Enemies follow the car up the ramps** (board, 2026-10-21, after playing the full game on the elevation map, where enemies ignored every raised surface): enemies treat rooftops as raised ground they can only reach by the ramps. To reach a car on a rooftop they find their way to a ramp, drive or walk up it and follow the car, with pathfinding over the map's streets, ramps and rooftops; a rooftop's edge blocks them like a wall from below. (T-207)

- **Health drops** (board, 2026-10-21): enemies also drop health pickups, at the same drop rate as the coins. Picking one up restores 30% of the car's health (never above its maximum). It looks like a red gas canister with a white cross on it (look: Visual style, Decisions). (T-220, art T-221)
## Content

### The minion (built in task T-044)

What the game does now, with the numbers in `game/data/enemies.json` (see References). How it is built, and the damage function the weapons call: `game/README.md`, "Minions".

- **Look:** a placeholder for now: a light green four-legged lizard shape with a tail, drawn in code, facing the way it walks, about one unit (the car's width) across. The final minion art comes from a separate art task.
- **Spawning:** the game keeps a number of minions around the car that grows in a straight line from 12 at the start of the run to 20 at the 7-minute mark (the kaiju's arrival), then stays there. While fewer are around, one comes in every half second, just beyond the edge of the visible screen, at a random point on the map that is clear of buildings and boulders, so they walk in from the edges. Minions the car has left a whole screen behind disappear, and new ones come in at the screen's edge, so the swarm stays around the car. The higher the combo, the more minions are kept around (Decisions; see "The combo raises spawning" below).
- **Movement:** each minion walks straight towards the car at 6 units a second, a bit over half the car's cruise speed. Minions push a little apart from each other so they spread around the car. They do not walk through buildings, walls or boulders: they slide along them and walk round one that is in the way. They never block or push the car.
- **The combo raises spawning:** the wanted count is multiplied by the combo's spawn multiplier (Game loop architecture, The combo; numbers in the combo data), live as the combo changes: no combo, no extra minions; the higher the combo, the more, up to the data's maximum. A setting (`combo_raises_spawning`, on by default; how to flip it is in `game/README.md`, Minions) switches it off for playtests.
- **Contact damage:** while a minion touches the car's body, it hits the car once every half second, the first hit as soon as it touches: 5 health off the car (which also cuts the combo, Game loop architecture) and a knockback away from the minion. Several minions touching the car each hit it.
- **Health and death:** 4 health. The weapons damage it; at 0 it dies and disappears.
- **Knocked back by a weapon (built in task T-167):** a weapon can push a minion (the windshield wiper does; Weapons). The weapon gives a direction and a distance in units (the flat world's units, like every distance here); the minion is pushed that far in that direction over 0.15 seconds at an even speed, without walking, then walks towards the car again. It is stopped by buildings, walls and boulders just as its walking is (it slides along them and is never pushed into one). A second push during a push adds to what is left. Only minions can be pushed: the kaiju has no knockback and is never pushed. The 0.15 seconds is a proposed feel number in the code (`KNOCKBACK_SECONDS`); the distance is the weapon's number. How to call it: `game/README.md`, "Minions".
- **Coins:** a dying minion drops coins 60% of the time, 2 coins each time, around where it died: placeholder gold coins on the ground. Driving over a coin collects it and adds it to the run's coins. Coins stay on the ground until collected or the run ends.
- **Boulders fade:** a boulder a meteor left stays 10 seconds after it lands, fully visible and solid. Then it fades out over 2 seconds (still drawn and still solid while it fades) and is gone: it no longer blocks the car or anything else, and its spot is free again. The 10 seconds and the 2-second fade are in `meteor_attack` (`boulder_lifetime_seconds`, `boulder_fade_seconds`; the fade's length is a proposed number). The map's own boulders never fade. The flat view's placeholder circles vanish at the end without fading (only the boulder art is see-through).
- **Pause and new runs:** minions and coins stand still while the game is paused, and are all gone when a new run starts.
- **Draw order:** minions and coins are drawn in the buildings' depth order like the car: behind a building that covers them, in front of the rest. Buildings fade only for the car, so a minion behind an opaque skyscraper is hidden by it.

### The kaiju (built in task T-045)

What the game does now, with the numbers in `game/data/enemies.json` (see References). How it is built, and how the weapons and the HUD reach it: `game/README.md`, "The kaiju". Its meteor attack: below.

- **Look:** a placeholder for now: a large dark slate green Godzilla-style shape drawn in code, seen from the side, with a lighter belly, pale cyan back plates and yellow eyes, facing left or right the way it walks and stomping as it walks. It stands on a ground circle 4 units across (four times the car's width) and is 7 units tall (over twice the car's length). The final kaiju art comes from a separate art task.
- **Arrival:** when the run reaches the boss time (7 minutes in, 1:00 left), the kaiju appears at a random point just beyond the edge of the visible screen, its whole drawing out of view, on the map and clear of buildings and boulders. One kaiju per run.
- **Movement:** it walks straight towards the car at 3 units a second, half a minion's speed. Like the minions, it does not walk through buildings, walls or boulders: it slides along them and walks round one that is in the way (confirmed by the board, 2026-10-14). It never blocks or pushes the car.
- **Contact damage:** while it touches the car's body, it hits the car once a second, the first hit as soon as it touches: 20 health off the car (which also cuts the combo) and a knockback of 16 units a second away from the kaiju.
- **Health and damage:** 500 health. Weapons damage it at any time, as soon as it has appeared, the same way they damage minions; there is no shield and no vulnerability window. Any overlap with its body on the ground (the 4-unit circle) counts as a flamethrower hit (board, 2026-10-14; minions keep the centre rule). Its health, and each change to it, can be read for the HUD (no HUD shows it yet).
- **Death:** at 0 health it dies and disappears. Its 10 coins are added to the run's coins at once, without a pickup, and then the run ends as a win, so the coins count in the coins saved.
- **Pause and new runs:** the kaiju stands still while the game is paused, and is gone when a new run starts; it arrives again at the new run's boss time.
- **Draw order:** like the minions, in the buildings' depth order: behind a building that covers it, in front of the rest.
- **Playtest switch:** for the board's playtest of this task, the kaiju arrives 30 seconds into the run instead of at 7 minutes, so it can be seen, fought with the weapons and killed early; it is set back to 7 minutes right before the task merges (board, 2026-10-14). Nothing else in the run moves (`game/data/playtest.json`; how to switch it: `game/README.md`, "The kaiju").

### The kaiju's meteor attack (built in task T-046)

What the game does now, with the numbers in `game/data/enemies.json`, `meteor_attack` (see References). How it is built: `game/README.md`, "The kaiju", "The meteor attack".

- **When:** while the kaiju is on the map, its first attack starts 5 seconds after it appears, then one every 8 seconds.
- **Windup:** each attack starts with a short placeholder animation of 1 second: pale yellow rings pulse above the kaiju's head.
- **Warning:** then 3 warning circles appear on the ground at once, each where a meteor will land, and stay 2 seconds. Each lies within 10 units of the car (where the car was when they appeared), only where the map's placement check accepts a boulder (inside the map, off buildings and other boulders), never on or next to a boulder a meteor left that is still there (standing, fading or waiting for the car to move off; a free ground gap of 1.5 units, `boulder_clearance_units`, because the boulder's drawing is taller than its circle), not overlapping or next to another meteor still to land (same gap), and not on the kaiju. If no spot is free, fewer meteors fall; once a boulder is gone its spot is free again (T-147). A circle is the size of the boulder it will leave (3 units across). Placeholder look: a hazard amber disc with a thick, pulsing amber edge and an inner ring that closes in as the meteor gets near. Amber, not red, because only Redgull's things and the kaiju alert signs use red (Visual style, Decisions); the final look comes from a separate art task.
- **Falling and impact:** in the last half second a placeholder meteor (a dark purple rock with a magenta glow and trail) falls onto the circle; when it lands, a placeholder burst of grey dust shows for half a second.
- **Hitting the car:** a meteor that lands with the car's centre within 1.5 units (the boulder's radius) takes 15 health off the car (which also cuts the combo) and knocks it back at 20 units a second, away from where it landed. One landing anywhere else does nothing to the car.
- **New boulders:** each landed meteor leaves a plain boulder where it landed, the same size, look and collision as the map's own, so the car bounces off it and enemies walk round it. No challenge or arrow comes with it. If the car or the kaiju is on the spot as the meteor lands, the boulder appears as soon as they have moved off it (the car is knocked away at once on a hit), so nothing is trapped inside a boulder.
- **Pause and new runs:** the attack, the warning circles and the falling meteors stop while the game is paused, nothing lands once the run is over, and a new run clears them all.
- **Playtest switch:** for the board's playtest of this task the kaiju arrives 30 seconds into the run (the T-045 switch, above), so its first attack comes 35 seconds in; it is set back to 7 minutes right before the task merges.

### Enemies on the rooftops and ramps (built in task T-207)

What the game does on a map with rooftops and ramps (the elevation map, Level design), following the decision "Enemies follow the car up the ramps". On the MVP map nothing here applies and the enemies walk as described above. Points marked "proposal" go beyond the decision and wait for the board's playtest. How it is built: `game/README.md`, "Enemies on the rooftops and ramps".

- **Standing on the ground:** every enemy stands on the ground under it: on the street, on a rooftop, or part way up a ramp, and is drawn lifted by that height, in the depth order at that height (over the rooftop it stands on, under a higher rooftop or a building in front of it).
- **Edges are walls:** a rooftop's edge stops an enemy like a wall, from below and from above, so an enemy changes level only along a ramp. It keeps its whole body off an edge, and slides along it. The sides of a ramp are walls too, except near its foot, where the ramp is still low (proposal). A weapon's knockback cannot push a minion over an edge either.
- **Finding the way:** on the car's own surface (the street, one rooftop, one ramp) an enemy walks straight at the car as before. Otherwise it follows a path to the car over the streets, ramps and rooftops, round buildings and boulders, going up or down each ramp along its middle; the path is renewed about once a second, and at once when the car changes surface.
- **Spawning:** minions come in from the screen's edges on the street only, never on a rooftop or a ramp. The kaiju arrives on the street too (proposal).
- **Staying round the car:** a minion on its way to a ramp is not removed for being far off screen, as long as it is within 120 units of the car (half the map; others are removed a screen beyond the visible one, as before), so minions walking round to a far ramp still arrive (proposal).
- **Contact damage at the car's level:** a minion or the kaiju only hits the car when the car's height (in the air too) is within 1 unit of the ground the enemy stands on: a car on a rooftop is safe from the minions on the street below its edge, and a car that jumps higher than 1 unit over a minion is not hit (proposal for the 1 unit).
- **Pushing apart:** minions push apart only from minions at their own level (proposal).
- **The kaiju (proposal):** the same rules as the minions: it climbs the ramps (its 4-unit body fits the 10-unit ramps), edges stop it, it is drawn at its height and only hits the car at its level, although it is taller than the highest rooftop.
- **Coins:** a coin is drawn at the height where its minion died, and stays on that level. Picking one up is unchanged: driving over it, at any height (proposal).
- **Weapons:** unchanged by this task: the weapons find and hit enemies at any height (proposal; a later weapons task can change it).

## Open questions


## References

- Enemy numbers (the minion, how many minions are kept around over the run, coin drops, the kaiju and its meteor attack): [../game/data/enemies.json](../game/data/enemies.json), read through `game/scripts/data/enemy_data.gd`; the reasons for each number are in task T-039's result notes.
