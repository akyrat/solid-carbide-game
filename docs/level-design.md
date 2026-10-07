---
title: Level design
gdd_order: 3
scope: What the map looks like, plus the designs for the driving challenges. The board defines the challenges geometrically or visually at first, then agents build from that.
agents_work_on: [level-challenge]
agents_read: [enemy-behavior]
---

# Level design

## Summary

The MVP has one map: a city laid out as a grid of building blocks, with roads of different widths running between them. Obstacles stand on the roads in set patterns, and some of those pattern groups become driving challenges, marked by an arrow painted on the ground. A challenge is a curved corridor with a width, which gives the player room for tolerance.

## Decisions

- A challenge is defined as a curved corridor with a width, so there is room for tolerance. (2026-10-03)
- The car counts as in the challenge as long as any part of it is touching the corridor. (2026-10-03)
- The MVP map is a city laid out as a grid: blocks of buildings, with roads running between the blocks. (How it looks: Visual style, Decisions.) (2026-10-07)
- Roads are between 5 and 10 times as wide as the player's car. A street never widens along its length; instead, some streets are wider than others, and a wide road can join a narrower one. (2026-10-07)
- Map sizes are measured in units, where 1 unit is the drawn car's width (the smaller of its two dimensions; Drifting, Decisions). It is the same unit the driving values use. (2026-10-07)
- The MVP map is 80 by 80 units: an 8-unit perimeter road on each side, around 4 blocks of 10 and 3 roads of 8 in each direction. (2026-10-07)
- A wide road, 8 units wide, runs around the whole edge of the map. The map ends in a hard stop at its edges. (2026-10-07)
- Inside the perimeter road, building blocks of 10 by 10 units are laid out in a 4 by 4 grid, separated by roads 8 units wide (3 roads in each direction). (2026-10-07)
- The centre of the map is an open square of 28 by 28 units with no blocks. Its ground is gravel, not road. (2026-10-07)
- Obstacles are placed on the roads. In the MVP the only obstacle is a crashed meteor boulder; more kinds come later. (2026-10-07)
- Some obstacles are on the map from the start; others appear during the run, dropped by the boss (Enemies, Decisions). (2026-10-07)
- The obstacles on the map from the start are placed in set patterns, called obstacle pattern groups. The MVP has 3 patterns, which the board will define. (2026-10-07)
- For the MVP, the board does no level design itself. The Level/Challenge Design Agent makes the map once, following the rules in this document and the board's descriptions and drawings, and every run uses that same map. (2026-10-07)
- 30% of the obstacle pattern groups on the map become challenges. Each challenge gets an arrow that appears under it, animated as if painted on the ground, showing the player how to drive the challenge. The arrow's animation is designed in advance. (2026-10-07)

## Content

(To be written.)

## Open questions

- What do the 3 obstacle patterns look like? Are they also the MVP's 3 challenge types (the Final GDD promises 3)? (The board will explain the challenges and obstacles next.)
- How many obstacle pattern groups does the MVP map have, and where can they be placed?
- After the MVP: the board plans to draw future maps by hand, and may explore generating a new map for every run.
- Which 30% of pattern groups become challenges: chosen at random each run, or fixed? Rounded how?
- What happens to a challenge after it is completed: does it disappear, stay, or respawn elsewhere?
- How does the challenge corridor (Decisions) relate to the painted arrow: does the arrow mark the corridor?

## References

(None yet.)
