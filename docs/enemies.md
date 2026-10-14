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

## Content

### The minion (built in task T-044)

What the game does now, with the numbers in `game/data/enemies.json` (see References). How it is built, and the damage function the weapons call: `game/README.md`, "Minions".

- **Look:** a placeholder for now: a light green four-legged lizard shape with a tail, drawn in code, facing the way it walks, about one unit (the car's width) across. The final minion art comes from a separate art task.
- **Spawning:** the game keeps a number of minions around the car that grows in a straight line from 12 at the start of the run to 20 at the 7-minute mark (the kaiju's arrival), then stays there. While fewer are around, one comes in every half second, just beyond the edge of the visible screen, at a random point on the map that is clear of buildings and boulders, so they walk in from the edges. Minions the car has left a whole screen behind disappear, and new ones come in at the screen's edge, so the swarm stays around the car. The higher-combo extra spawning (Decisions) has a hook in place but is not wired yet.
- **Movement:** each minion walks straight towards the car at 6 units a second, a bit over half the car's cruise speed. Minions push a little apart from each other so they spread around the car. They do not walk through buildings, walls or boulders: they slide along them and walk round one that is in the way. They never block or push the car.
- **Contact damage:** while a minion touches the car's body, it hits the car once every half second, the first hit as soon as it touches: 5 health off the car (which also cuts the combo, Game loop architecture) and a knockback away from the minion. Several minions touching the car each hit it.
- **Health and death:** 4 health. The weapons damage it; at 0 it dies and disappears.
- **Coins:** a dying minion drops coins 60% of the time, 2 coins each time, around where it died: placeholder gold coins on the ground. Driving over a coin collects it and adds it to the run's coins. Coins stay on the ground until collected or the run ends.
- **Pause and new runs:** minions and coins stand still while the game is paused, and are all gone when a new run starts.
- **Draw order:** minions and coins are drawn in the buildings' depth order like the car: behind a building that covers them, in front of the rest. Buildings fade only for the car, so a minion behind an opaque skyscraper is hidden by it.

## Open questions


## References

- Enemy numbers (the minion, how many minions are kept around over the run, coin drops, the kaiju and its meteor attack): [../game/data/enemies.json](../game/data/enemies.json), read through `game/scripts/data/enemy_data.gd`; the reasons for each number are in task T-039's result notes.
