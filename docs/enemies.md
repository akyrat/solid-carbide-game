---
title: Enemies
gdd_order: 4
scope: Which enemies exist, what they look like, how they move, deal damage and behave, including the boss.
agents_work_on: [enemy-behavior]
agents_read: [game-data]
---

# Enemies

## Summary

Each level ends with its own final boss; in the first level, Crash City, it is the kaiju. The MVP boss is a huge, slow sprite that walks toward the player and deals contact damage. Its one special move rains meteors that become obstacles laid out as a challenge, and completing those challenges is the only way to make the boss vulnerable.

## Decisions

- Each level ends with a different type of monster as its final boss. The kaiju is only the first level's boss. (2026-10-03)
- MVP boss: a sprite much bigger than the player, walking slowly toward the player, with contact damage. (2026-10-03)
- The boss has one special move. After a short animation, several meteors rain down at once. In 2D, each is a meteor sprite falling top to bottom, with an impact animation on landing. (2026-10-03)
- Before the meteors land, a danger warning area shows on the ground for 2 seconds. A meteor that lands on the player deals damage and knocks them back. (2026-10-03)
- Landed meteors become obstacles, laid out as one of the challenge designs (for example, two meteors). Once they land, a guide arrow appears between them, for example a curved figure-eight, to show this is the challenge to complete. (2026-10-03)
- The boss becomes vulnerable only by completing the challenges its own meteors create. Those use a different color than the challenges already on the map. (2026-10-03)
- Over a run, the number of enemies grows slightly. Enemies do not get tougher. (2026-10-07)

## Content

(To be written.)

## Open questions

- Idea under consideration: a semi-transparent shield on the boss, in the same color as the arrow of the challenge it spawned, to signal that it is invulnerable.
- How long does the boss stay vulnerable after a challenge is completed?
- How often does the boss use the meteor move, and can it start another while a challenge is still uncompleted?
- How exactly does the number of enemies grow across the 7 minutes before the boss?

## References

(None yet.)
