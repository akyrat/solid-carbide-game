---
id: G-004
title: Build the drive-only elevation sample map as written in docs/level-...
status: paused
art_cap: 50
art_used: 0
iteration: 1
max_iterations: 20
created: 2026-10-19
lead: Goal-G-004
---

## Goal

Build the drive-only elevation sample map as written in docs/level-design.md (Decisions, 'Elevation sample map', 2026-10-19) and docs/visual-style.md (Decisions, 'Elevation sample map art'): a city-sized map with three layers (street 0, first floor 3, second floor 6) joined by ramps (street to first floor, first floor to second), raised areas as building rooftops and ramps as parking-garage ramps, using the approved elevation system (the car's height, edges, see-through raised areas, the round shadow), with its map file holding heights and ramps for a later level editor, and its PixelLab art. Drive-only: no enemies, weapons or run timer. Do not build tricks or a level editor.

## Goal acceptance criteria

- [ ] On branch playtest/G-004, a drive-only elevation sample map scene exists (e.g. game/scenes/elevation_sample/elevation_sample_map.tscn), runs headless for at least 10 seconds with no script errors, and its run command is written in game/README.md and in docs/level-design.md (Content, 'Elevation sample map'). (QA: pass / fail)
- [ ] The scene contains no enemies, no weapons, no run timer, no likes/levels and no level-up screen: QA checks that no enemy, weapon, timer or run-state node exists in the running scene tree, and that the car drives with W/A/S/D only. (QA: pass / fail)
- [ ] The sample map's file (e.g. game/data/level/elevation_sample_map.json) exists and holds the map's roads/ground, buildings, boulders, raised areas (platforms with height) and ramps (with bottom and top height) as data. A test confirms that the only heights used are 0, 3 and 6, with at least one raised area at 3 and one at 6, at least one ramp from 0 to 3, and at least one ramp from 3 to 6. (QA: pass / fail)
- [ ] The map is city-sized: a test confirms its extent equals the MVP map's (240 by 240 units) unless the board's answer to the open questions says otherwise, and it keeps the MVP map's roads, buildings and boulders outside the raised areas. (QA: pass / fail)
- [ ] A reachability test drives the car with the real driving code (scripted inputs, headless) from the start onto a height-3 rooftop by a street ramp, then up a 3-to-6 ramp onto a height-6 rooftop, and then off a height-6 edge into the air, landing at a lower height. The test passes, and it logs the car's maximum height and airtime. (QA: pass / fail)
- [ ] The approved elevation system is reused, not copied or changed in behaviour: the elevation test scene's existing tests (test_ground_height, test_car_height, test_elevation_edges, test_elevation_drawing, test_elevation_see_through, test_elevation_art) still pass, and the sample map uses car_height.gd, GroundHeight, car_shadow.gd (round shadow) and the shared see-through fade (map_building.gd faded_alpha, mvp_map.gd SEE_THROUGH constants). (QA: pass / fail)
- [ ] See-through works on the sample map: tests show that a raised area or ramp at height 3 or 6 that covers the car fades to 0.15 over 0.15 s, the same way the map's buildings do, and that the car is never drawn over a raised area it is behind, including at a wall hit on a raised area's back side. (QA: pass / fail)
- [ ] Every raised area and ramp on the sample map is drawn with PixelLab art (rooftops with parapet, vents, AC units, a small rooftop sign and light cracks; building-wall sides with lit windows; concrete parking-garage ramps) in the City colours palette. The art is in game/art/, the raw generations and records are in art-archive/<task>/, the total PixelLab generations are 50 or fewer and are logged in the result notes, and an art check confirms at most 30 colours per sprite, no semi-transparent pixels, hard edges and no Redgull red. (QA: pass / fail)
- [ ] No trick system and no level editor exist on the branch: no new trick input, trick HUD or editor scene/tool was added (QA diffs playtest/G-004 against master). (QA: pass / fail)
- [ ] The MVP run is unchanged: the main scene still starts a run on the MVP map, and all three test sets (Godot unit tests, Python tool tests, per-run tests) pass on playtest/G-004. (QA: pass / fail)
- [ ] Screenshots exist (committed, paths listed in the tickets) of the car on the street, on a ramp from 0 to 3, on a height-3 rooftop, on a ramp from 3 to 6, on a height-6 rooftop, in the air after jumping off a height-6 edge with its round shadow on the ground below, and behind a see-through raised area. (QA: pass / fail)
- [ ] docs/level-design.md (Content, 'Elevation sample map'), docs/visual-style.md (the art's results, under 'Elevation sample map art'), and game/README.md describe what was built, and the docs staleness check passes after the long GDD is regenerated. (QA: pass / fail)

## Open questions

- Layout: how many raised areas at height 3 and at height 6, where they go on the city map, and how big they are. The docs give only '2 by 2 blocks' as an example of a raised area's size. Do rooftops replace building blocks, or can they also span the roads between blocks (covering the road under them)?
- Does a height-6 area sit on top of a height-3 rooftop (stacked, reached by a ramp on that rooftop), or beside it? And must a 3-to-6 ramp start on a first-floor rooftop?
- Ramp sizes and slopes: should the street and rooftop ramps reuse the test scene's 12-unit run per 3 units of rise, and where do they sit (on roads, in the gravel, inside blocks)? A ramp on a 24-unit road narrows it, and its sides are walls.
- Should the low parapet wall at rooftop edges be drawing only (the car drives over it and drops off the edge, as the docs' drop-off rule implies), or a real wall that stops the car?
- Do the MVP map's boulders stay only on the streets, or can some sit on rooftops? Do the tall buildings (15 units) stay next to the raised areas as walls at every height?
- How does the board play it? The test scene was F6-only and not reachable from menus. The Builds tab's Play starts the main scene. Options: a temporary menu entry, a separate launch command, or making it the main scene on the playtest branch only (recommended: a main-menu entry or a flag on the playtest branch only, so the MVP run stays untouched).
- Where does the car start (street or gravel centre), and does the scene need a pause or quit screen, or any on-screen text? If text, a Narrative Theme task is needed first.
- Is the sample map a separate map file and scene beside the MVP map (assumed here), or should it later replace the MVP map's layout?
- Art details the docs leave to the agents: how many rooftop and wall variants, whether the rooftop sign carries Japanese-like marks (City brief), and how the 50-generation cap is split between rooftops, walls and ramps.

## Sub-goals

| rank | id | title | score | why | verdict | tickets |
|---|---|---|---|---|---|---|
| 1 | S1 | Multi-level height data and query (map file format) | unblocks 6, value 5 | The map file has to hold three layers, ramps that start on a rooftop (3 to 6), and areas next to or on top of each other, in a format a later level editor can edit. Today's format assumes one platform and ramps from 0. | covered | T-193, T-182 |
| 2 | S2 | The sample map's layout file | unblocks 4, value 5 | The goal is a city-sized map with three layers made by the agents; this is the map itself, as data a level editor could later edit. | in-flight | T-194 |
| 3 | S3 | The car's height across three layers | unblocks 4, value 5 | The approved car height model was only tested on one platform at 3 from the street. The goal needs ramp takeoffs from 3 to 6, drops from 6 onto 3 or 0, and walls between layers. | in-flight | T-195 |
| 4 | S4 | The drive-only sample map scene | unblocks 3, value 5 | The thing the board plays: the city with the car, its camera, the ground art, the buildings and boulders, and the raised areas, with nothing from the run. | in-flight | T-196 |
| 5 | S5 | Depth order and see-through for many raised areas and buildings | unblocks 1, value 5 | The approved see-through and depth rules were built for one platform. On a city map with many rooftops at two heights, next to tall buildings, the car must never vanish or wrongly draw over something it is behind. | in-flight | T-197 |
| 6 | S6 | PixelLab art: rooftops and parking-garage ramps | unblocks 1, value 5 | The goal names its PixelLab art: raised areas as building rooftops and ramps as concrete parking-garage ramps, following the City brief and City colours, and not reusing the test scene's castle-stone art. | in-flight | T-198 |
| 7 | S7 | Integration, screenshots and docs on playtest/G-004 | unblocks 0, value 4 | The board plays the result once at the end. Everything has to work together on the build branch, with the MVP run untouched and the docs describing what was built. | in-flight | T-199, T-200 |

### S1: Multi-level height data and query (map file format)

Needs: nothing.

- The height data format supports platforms at any height and ramps with a non-zero bottom_height (a ramp from a height-3 rooftop up to a height-6 rooftop). Its fields are documented in game/README.md and docs/level-design.md (Content).
- GroundHeight loads the new file and returns the right height_at, ramp_at and area_index_at for points on the street, on a height-3 area, on a height-6 area, on a 0-to-3 ramp and on a 3-to-6 ramp (unit tests).
- A validator (script or test) rejects a file with overlapping areas that are not meant to stack, ramps that do not touch the area they climb to, or ramp heights that don't match the heights at their two ends, and it accepts the sample map file.
- elevation_test.json still loads unchanged, and test_ground_height.gd passes.

### S2: The sample map's layout file

Needs: S1.

- A script (e.g. game/tools/build_elevation_sample_map.py) builds the sample map file from the MVP map's roads, buildings and boulders, adding raised areas (rooftops) at heights 3 and 6 and ramps from 0 to 3 and from 3 to 6. Its Python tests pass.
- Tests on the file: the heights used are exactly {0, 3, 6}; there is at least one raised area at 3 and one at 6, at least one ramp from 0 to 3 and at least one from 3 to 6; every height-6 area can be reached from the street by driving up ramps; no ramp foot is blocked by a building, a boulder or the map's edge; no boulder sits on a raised area's or a ramp's footprint (unless the board answers otherwise).
- The MVP map's own file (mvp_map.json) is unchanged.
- An overview picture of the layout (flat, with the heights coloured) is committed and linked from docs/level-design.md, with every layout choice marked as a proposal for the board's playtest.

### S3: The car's height across three layers

Needs: S1.

- Headless unit tests with the real car code on the sample map's ground: driving up a 0-to-3 ramp and up a 3-to-6 ramp follows the ramp; leaving the top of a 3-to-6 ramp at cruise speed takes off with the ramp's slope; driving off a height-6 edge lands on the height-3 area or on the street, whichever is under it; on a height-3 rooftop, the side of a height-6 area is a wall the car bounces off.
- car_height.gd's constants (GRAVITY, RAMP_TAKEOFF_MIN_SPEED, RAMP_TAKEOFF_FACTOR, STEP_CLIMB_MAX) and its behaviour on the test scene are unchanged; test_car_height.gd and test_elevation_edges.gd pass.
- The MVP map's tall buildings and boulders still block the car at every height it can reach (test).

### S4: The drive-only sample map scene

Needs: S2, S3.

- The scene loads the sample map file and shows the isometric ground art, the buildings (see-through as on the MVP map), the boulders, every raised area and ramp (the script drawing as a placeholder until S6), the car with its final sprite lifted by its height, and the round shadow on the ground under it.
- There are no enemies, weapons, run timer, likes, levels or HUD run-state nodes in the scene tree (test). W/A/S/D drive the car, and the camera follows as in the elevation test scene.
- The scene runs headless for 10 seconds with no errors. The run command is in game/README.md, and how the board opens it is answered as the board decides (see open questions).
- Screenshot fixtures and committed screenshots show the car on the street, on each kind of ramp, on height 3, on height 6, and in the air with its shadow below.

### S5: Depth order and see-through for many raised areas and buildings

Needs: S4.

- The depth order works across every raised area, ramp and building: the car and its shadow are drawn under any area or building they are behind and lower than its top, and over the ones they are on, above or in front of. Tests cover a car on height 3 behind a height-6 area, a car in the air at height 6+ over a height-3 area, and a car behind a building next to a raised area.
- Every raised area and ramp that covers the car fades to mvp_map.gd's SEE_THROUGH_ALPHA over SEE_THROUGH_FADE_TIME using map_building.gd's faded_alpha (shared, not copied); areas that don't cover it stay opaque (tests).
- Driving into the back sides (top-left and top-right on screen) of a height-3 and a height-6 area keeps the car under the area through the hit (tests like test_elevation_see_through.gd).
- Screenshots show the car behind a see-through height-3 area and a height-6 area.

### S6: PixelLab art: rooftops and parking-garage ramps

Needs: S2, S4.

- The planned PixelLab calls and their cost are written in the task's result notes before any call. The total is 50 generations or fewer, one round, no regeneration, with a 600 s HTTP timeout.
- A build script projects the textures onto the faces of every raised area and ramp in the sample map file (top, the visible south and east walls with lit windows, the ramps' concrete surface). Rooftop details (parapet, vents, AC units, a small rooftop sign, light cracks) are drawn on the tops. A check mode and its Python tests pass.
- Art check: hard pixel edges, no semi-transparent pixels, at most 30 colours per sprite, transparent background, 32 art px per unit drawn at 0.5, no Redgull red, cool blue-grey city palette (not the boulders' navy/purple). Raw generations and records are in art-archive/<task>/, and game-ready art is in game/art/.
- The scene draws the art in place of the script drawing, with the script drawing kept as a fallback. The see-through fades the art with its area (test). Weak results are noted in the result notes and in visual-style.md, not regenerated.
- Screenshots of the art in the game: street, rooftop at 3, rooftop at 6, a ramp, and a see-through area.

### S7: Integration, screenshots and docs on playtest/G-004

Needs: S5, S6.

- On playtest/G-004 all three test sets pass, the MVP run still starts from the main menu on the MVP map, and no trick or level-editor code was added (diff against master).
- The scripted reachability drive (street to 3 to 6, then a jump off 6) passes on the merged branch, and its log of max height and airtime is in the ticket.
- docs/level-design.md (Content, 'Elevation sample map'), docs/visual-style.md (the art results) and game/README.md are updated, with every number and layout choice marked as a proposal. The long GDD is regenerated and the staleness check passes.
- The final screenshot set (see the goal criteria) is committed, and its paths are listed for the board.

## Scoring

Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. A sub-goal is therefore always ranked before every sub-goal that needs it. A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.

## Tickets

- T-193: Elevation sample map: height data for three layers (stacked areas, ramps between rooftops) and a height-data validator (S1, written)
- T-194: Elevation sample map: the layout file, built by script from the MVP map, with rooftops at 3 and 6 and parking-garage ramps (S2, written)
- T-195: Elevation sample map: the car's height across three layers, and a scripted drive from the street to 6 and off (S3, written)
- T-196: Elevation sample map: the drive-only scene (the MVP map's city with rooftops and ramps, placeholder drawing) (S4, written)
- T-197: Elevation sample map: depth order and see-through across every raised area, ramp and building (S5, written)
- T-198: Art: rooftops and parking-garage ramps for the elevation sample map (PixelLab) (S6, written)
- T-199: Elevation sample map: final documentation and the final screenshot set (S7, written)
- T-200: QA: the elevation sample map on playtest/G-004, before the board's playtest (S7, written)
- T-182: Elevation test scene: ground-height data (one platform, one ramp, drop-off edges) and a ground-height query (S1, covered)

## Iteration log

- 2026-10-19, iteration 0: started: planning.
- 2026-10-19, iteration 0: priority scoring: 7 sub-goals ranked, 12 goal criteria, 9 open questions.
- 2026-10-19, iteration 0: gap detection: 0 covered, 0 in flight, 7 missing; wrote 8 tickets.
- 2026-10-19, iteration 0: building.
- 2026-10-19, iteration 1: T-193 (S1, level-challenge, opus): passed (done, QA rounds 1), merged into playtest/G-004; art 0; agent: T-193 is finished in C:\solid-carbide-worktrees\T-193, in 3 commits on its branch. Platforms can now name the area they stand on with an optional `on` field, which GroundHeight keeps. I added the three-layer fixture (game/tests/fixtures/height/three_layers.json) and a validator, `python game/tools/check_height_data.py <file>`, which prints OK for both elevation_test.json and the fixture; its 17 Python tests reject every case the ticket lists, plus a few more. The existing query already handled ramps between rooftops (heights 1.5 and 4.5 halfway up, the right areas and side normals, a 3-unit drop between floors), so no code fix was needed. 11 new GUT tests check this, including the car's height following both ramps up and landing on the height-3 floor. The new fields and the validator are documented in game/README.md and docs/level-design.md. elevation_test.json and its three test files are unchanged against master. All three test sets pass (GUT 1054/1054, game Python tools 303 OK, project tools 331 OK). There are no screenshots because nothing is on screen yet, as the result notes say. Godot left its usual line-ending-only .import changes in the folder; I didn't commit them. The SessionStart hook said this session has no name and that port 8765 is taken by the main checkout's task board; I didn't act on that because I'm a goal-run agent. Rescan: S1 covered, S2 in-flight, S3 in-flight, S4 in-flight, S5 in-flight, S6 in-flight, S7 in-flight.
- 2026-10-19, iteration 1: paused (see Pauses).

## Pauses

- 2026-10-19 [stop]: Claude reported an error for step 'agent': You've hit your session limit · resets 2:40pm (Europe/London)

