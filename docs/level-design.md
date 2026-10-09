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
- The car counts as in the challenge as long as any part of it is touching the corridor. "The car" here is the drawn car (1 by 3 units), not its smaller physics body. (2026-10-03; drawn car confirmed 2026-10-08)
- The MVP map is a city laid out as a grid: blocks of buildings, with roads running between the blocks. (How it looks: Visual style, Decisions.) (2026-10-07)
- Roads are between 5 and 10 times as wide as the player's car. A street never widens along its length; instead, some streets are wider than others, and a wide road can join a narrower one. (2026-10-07)
- Map sizes are measured in units, where 1 unit is the drawn car's width (the smaller of its two dimensions; Drifting, Decisions). It is the same unit the driving values use. (2026-10-07)
- The MVP map is 80 by 80 units: an 8-unit perimeter road on each side, around 4 blocks of 10 and 3 roads of 8 in each direction. (2026-10-07)
- A wide road, 8 units wide, runs around the whole edge of the map. The map ends in a hard stop at its edges. (2026-10-07)
- Inside the perimeter road, building blocks of 10 by 10 units are laid out in a 4 by 4 grid, separated by roads 8 units wide (3 roads in each direction). (2026-10-07)
- The centre of the map is an open square of 28 by 28 units with no blocks. Its ground is gravel, not road. (2026-10-07)
- Obstacles are placed on the roads. In the MVP the only obstacle is a crashed meteor boulder; more kinds come later. (2026-10-07)
- In the MVP, obstacles are circles, all 3 units across (one car length), so they never block a road. (2026-10-08; replaces the 2026-10-07 decision of 3, 6 or 9 units)
- In the MVP, a challenge includes up to 2 obstacles. (2026-10-07)
- Each challenge's arrow path is shaped to its obstacles, using scripts from the Driving & Drift Agent that show what the car can actually drive and how it behaves. (2026-10-07)
- Some obstacles are on the map from the start; others appear during the run, dropped by the boss (Enemies, Decisions). (2026-10-07)
- The obstacles on the map from the start are placed in set patterns, called obstacle pattern groups. The board defines the patterns. (2026-10-07)
- The MVP has 2 obstacle patterns, each drawn by the board (Content, "MVP challenges") (2026-10-08; replaces the earlier plan of 3):
  - **Single Boulder:** 1 boulder, with 2 possible challenges: one loop clockwise and one counter-clockwise around it.
  - **Two Boulders:** 2 boulders, with 1 possible challenge: a figure-eight around both.
- A pattern can have several possible challenges: each challenge is a different arrow path around the same obstacles. (2026-10-08)
- For the MVP, the board does no level design itself. The Level/Challenge Design Agent makes the map once, following the rules in this document and the board's descriptions and drawings, and every run uses that same map. (2026-10-07)
- 30% of the obstacle pattern groups on the map become challenges. Each challenge gets an arrow that appears under it, animated as if painted on the ground, showing the player how to drive the challenge. The arrow's animation is designed in advance. (2026-10-07)
- Which pattern groups are challenges is set in advance, the same every run. The Level/Challenge Design Agent makes the first choice, and the board adjusts it if needed. (2026-10-08)
- The painted arrow marks the challenge's corridor (the corridor in the first Decision). The arrow is as wide as the car is long (3 units), so the player doesn't have to follow its centre line exactly: the car only has to touch the arrow. The Driving & Drift Agent's scripts make sure each path is drivable. (2026-10-08)
- The Level/Challenge Design Agent decides how many copies of each pattern are placed on the map, and where. (2026-10-08)
- A challenge is completed when the drawn car touches its corridor continuously from the arrow's start to its end, in the arrow's direction. Leaving the corridor midway means starting again from the start. (2026-10-08)
- When a challenge is completed, its arrow disappears and the player gets XP on the XP bar. The group's boulders stay on the map as plain obstacles for the rest of the run. (2026-10-08)
- When a pattern with several possible arrows becomes a challenge, the Level/Challenge Design Agent picks one of its arrows. (2026-10-08)
- The board draws each challenge as its own drawing in Crash City Grid (References): one drawing per arrow path, kept in a folder per obstacle pattern. Every drawing in a pattern's folder has the same boulders; only the arrow differs. (2026-10-08)
- The board's drawings are rough sketches of each challenge's general shape, not exact layouts. The Level/Challenge Design Agent makes them fit the map (for example the 8-unit roads), with whatever reasonable adjustments that needs (size, spacing, how tight the loops are), while keeping the shape: how many boulders, which way the arrow goes around each one, and the overall path (a loop, a figure-eight). The Driving & Drift Agent's check confirms the fitted versions can be driven. (2026-10-08)

## Content

### MVP challenges

The board's sketches of the 3 MVP challenges, one per arrow path. They show the general shape only; the fitted versions on the map are the Level/Challenge Design Agent's (Decisions). Each drawing's data (boulders and arrow points, in units from the sheet's centre) is in a `.json` file next to its picture. The pale band is the 3-unit corridor, the white dot is the start, and the arrowhead is the finish.

| Pattern | Challenge | How the arrow goes |
|---|---|---|
| Single Boulder | [arrow 1](level-design/single-boulder/arrow-1.svg) | One loop around the boulder, clockwise |
| Single Boulder | [arrow 2](level-design/single-boulder/arrow-2.svg) | One loop around the boulder, counter-clockwise |
| Two Boulders | [arrow 1](level-design/two-boulders/arrow-1.svg) | A figure-eight: clockwise around the top boulder, counter-clockwise around the bottom one |

![Single Boulder, arrow 1](level-design/single-boulder/arrow-1.svg)
![Single Boulder, arrow 2](level-design/single-boulder/arrow-2.svg)
![Two Boulders, arrow 1](level-design/two-boulders/arrow-1.svg)

### MVP map

The MVP map as built in Godot (task T-019), in flat placeholder colours: dark grey roads, the tan gravel centre, purple buildings, dark boulders with an orange rim, and blue challenge arrows. The art replaces the colours later.

![The MVP map, flat top-down](level-design/mvp-map.png)

![The MVP map, isometric](level-design/mvp-map-iso.png)

**Coordinates.** Positions are in units from the map's centre, x to the right and y down, as in Crash City Grid, so the map runs from -40 to 40. The blocks start at -32, -14, 4 and 22 on each axis; the gravel centre runs from -14 to 14. The road crossings are at -36, -18, 0, 18 and 36 on each axis (0, 0 is in the gravel).

**Fitted patterns.** Each sketch has a fitted version next to it (`arrow-1.fitted.json` and `.svg`), made by a script from the sketch. The sketch's boulders are kept, 3 units across and as far apart as drawn, and its arrow points are moved as little as possible until the arrow's centre line stays at least 2 units from each boulder's centre (the rock's radius plus half the car's width) and the 3-unit corridor stays at least 0.25 units from every building:

| Fitted version | Made to fit | Around each boulder |
|---|---|---|
| [Single Boulder, arrow 1](level-design/single-boulder/arrow-1.fitted.svg) | A crossing of two 8-unit roads, the boulder on its centre | Clockwise, 387 degrees (sketch: 389) |
| [Single Boulder, arrow 2](level-design/single-boulder/arrow-2.fitted.svg) | A crossing of two 8-unit roads, the boulder on its centre | Counter-clockwise, 400 degrees (sketch: 431) |
| [Two Boulders, arrow 1](level-design/two-boulders/arrow-1.fitted.svg) | A straight 8-unit road, the boulders on its centre line, 7 units apart | Clockwise 408 degrees, then counter-clockwise 339 (sketch: 422 and 332) |

The figure-eight is squeezed across the road (its loops are 4.5 units wide at the centre line instead of about 8) and keeps its length along it.

**Pattern copies and challenges.** 12 copies; 30% of 12 is 3.6, rounded half up to 4 challenges. The rotation turns the fitted version clockwise on screen.

| Copy | Pattern | Centre | Rotation | Challenge |
|---|---|---|---|---|
| copy-01 | Single Boulder | -18, -18 | 0 | challenge-1, arrow 1 (clockwise) |
| copy-02 | Single Boulder | 0, -18 | 0 | |
| copy-03 | Single Boulder | 18, -18 | 0 | |
| copy-04 | Single Boulder | -18, 0 | 0 | |
| copy-05 | Single Boulder | 18, 0 | 0 | |
| copy-06 | Single Boulder | -18, 18 | 0 | |
| copy-07 | Single Boulder | 0, 18 | 0 | |
| copy-08 | Single Boulder | 18, 18 | 0 | challenge-2, arrow 2 (counter-clockwise) |
| copy-09 | Two Boulders | 0, -36 (top side of the perimeter road) | 90 | challenge-3 |
| copy-10 | Two Boulders | 36, 0 (right side) | 0 | |
| copy-11 | Two Boulders | 0, 36 (bottom side) | 90 | challenge-4 |
| copy-12 | Two Boulders | -36, 0 (left side) | 0 | |

**Completing a challenge.** The map checks the drawn car (a 3 by 1 unit rectangle on the car's position and heading) against each open challenge every physics step. A run starts when the car touches the arrow's start; it moves forward while the car keeps touching the corridor, and only along the stretch of arrow the car is on, so crossing a figure-eight or passing the start of a loop does not skip ahead. Not touching the corridor at all, even for one step, ends the run. Reaching the arrow's end completes the challenge.

**Drivability.** The fitted challenges have not yet been checked with the Driving & Drift Agent's script (task T-021). All 4 challenges need that check.

## Open questions

- (After MVP) The board plans to draw future maps by hand, and may explore generating a new map for every run.

## References

- The board's challenge drawings: `docs/level-design/` (Content, "MVP challenges"). They are exported from Crash City Grid with `python tools/export_challenge_drawings.py <folder of downloaded drawings>`.
- The MVP map's layout data (Content, "MVP map"): [../game/data/level/mvp_map.json](../game/data/level/mvp_map.json), with the buildings, ground cells, pattern copies, boulders and challenges (arrow points and centre lines) in units from the map's centre. It and the fitted patterns are made with `python game/tools/build_mvp_map.py`; how to open the map in Godot: [../game/README.md](../game/README.md), section "MVP map".
- Crash City Grid, the map editor the board and the Project Lead draw the map in: https://claude.ai/artifact/R9AUtdNttfHKNgeqGDCPAH (private to the board). Each map is saved as an 80 by 80 grid of cells, plus its boulders, pattern groups, challenges and arrow paths, in units from the map centre; the Project Lead reads it and copies what the Level/Challenge Design Agent needs into its tasks.
