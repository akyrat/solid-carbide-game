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
- Where and how minions spawn, and how often their contact damage applies, are proposed by the Enemy Behavior Agent with the Game Data Agent; the board judges them in playtests. (2026-10-09)
- Killing the kaiju ends the run at once, as a win. (2026-10-09)
- The higher the player's combo (Game loop architecture, Decisions), the more minions spawn, on top of the slow growth over the run. It can be switched off, so the board can judge in playtests whether to keep it; the Game Data Agent proposes how strongly the combo raises spawning. (2026-10-10)

## Content

(To be written.)

## Open questions


## References

(None yet.)
