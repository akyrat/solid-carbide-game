---
id: G-003
title: Build the elevation system in a test scene, as written in docs/drif...
status: paused
art_cap: 20
art_used: 0
iteration: 1
max_iterations: 20
created: 2026-10-19
lead: Goal-G-003
---

## Goal

Build the elevation system in a test scene, as written in docs/drifting.md (Decisions, 'Elevation', 2026-10-19) and docs/level-design.md (Decisions, 'Raised areas and ramps'): the car gets a real height above the ground with gravity, takeoff and landing; one raised platform with a ramp on one side to drive up and drop-off edges to jump off; the car's drawing lifts with its height while its shadow stays on the ground. Include PixelLab art for the ramp and the raised platform. Do not rebuild the trick system yet.

## Goal acceptance criteria

- [ ] A test scene for elevation exists on the branch playtest/G-003 (path recorded in game/README.md, section on the elevation test scene) and runs headless in Godot 4.6 for at least 10 seconds with no script errors in the log; the drift prototype stays the project's main scene. (QA: pass / fail)
- [ ] The scene holds exactly one raised platform, with a ramp on one side and drop-off edges on its other sides, as in docs/level-design.md, Decisions, 'Raised areas and ramps'. (QA: pass / fail)
- [ ] GUT tests on playtest/G-003 pass and show that the car has a height separate from its map position: on flat ground it stays at 0; driving up the ramp raises it to the platform's height; driving along the platform keeps it there; driving off a drop-off edge or the ramp's top at speed makes it airborne, with its height following gravity until it lands; landing sets its height to the ground under it and its vertical speed to 0. (QA: pass / fail)
- [ ] A screenshot (or captured frames) from the running test scene, saved in the goal's folder, shows the car in the air off the drop-off edge with its drawing lifted up the screen and its shadow on the ground under its map position; a second one shows the car on the platform. (QA: pass / fail)
- [ ] The ramp and the raised platform are drawn with PixelLab art in game/art/ (each with its PixelLab record .json), every other generation in art-archive/<task>/, the total PixelLab generations for the goal at or under its art cap (20), and the art follows docs/visual-style.md, Decisions (32 art px per unit drawn at 0.5, hard pixel edges, no semi-transparent pixels, no Redgull red). (QA: pass / fail)
- [ ] All the existing test sets still pass on playtest/G-003 (the drift prototype's driving tests unchanged: flat driving behaves as before). (QA: pass / fail)
- [ ] No trick system code is on playtest/G-003: no arrow-key tricks, grinds, air rotation or self-jump key (checked by searching the goal's diff). (QA: pass / fail)
- [ ] docs/drifting.md (Content) and docs/level-design.md (Content) describe what was built, with every proposed number listed as a proposal for the board's playtest; docs/visual-style.md records the ramp and platform art; the docs staleness check passes after the long GDD is regenerated. (QA: pass / fail)

## Open questions

- How big is the test platform and how high, and how long or steep is the ramp? Level design gives the map's raised areas the size of a 2 by 2 grid of blocks as an example, but nothing sets the test scene's sizes or the height in units.
- What is the platform in the world (a raised road, an overpass, a rooftop, a rubble mound), and what is its surface? Visual style has no decision on it, and the PixelLab art prompt depends on it.
- What happens when the car drives into a drop-off edge from the ground below: does it bounce off like a wall, at the same 'Wall bounce' setting?
- Can the car drive off the ramp's sides, or do they act as drop-off edges or walls?
- Can the car steer, speed up or brake while in the air, or does it keep its speed and heading until it lands?
- How does a landing feel: no effect, a squash in the drawing, lost speed, or a bounce? Is there damage or a limit for a landing from a big height?
- Does the camera follow the car's drawing (lifted with its height) or its position on the ground?
- Does the shadow change with height (smaller or fainter higher up, as in the trick prototype) or stay the same? And when the car flies over the platform, is the shadow drawn on the platform's top?
- Do the flat top-down view (V) and the tuning panel need to support height, and should the gravity and takeoff numbers get tuning panel sliders? Sliders would need labels, which need a Narrative Theme text task first.
- How is the 'bigger when high' option switched for the playtest (a key, a tuning panel toggle, a constant), and how much bigger?
- How does the board open the test scene: as a separate scene opened with F6 in the editor, or should the goal's build make it the main scene for the playtest?
- Does the car's drawn shadow need its own art, or is a script-drawn shadow enough (the goal asks for PixelLab art only for the ramp and the platform)?

## Sub-goals

| rank | id | title | score | why | verdict | tickets |
|---|---|---|---|---|---|---|
| 1 | S1 | Ground-height data for the test scene: one platform, one ramp, drop-off edges | unblocks 6, value 5 | The car's height needs to know how high the ground is under it. Level design says the map's data format leaves room for heights and ramps from the start, for the board's later level editor. | covered | T-182 |
| 2 | S2 | The car's real height: gravity, takeoff and landing | unblocks 5, value 5 | This is the heart of the goal (Drifting, Decisions, 'Elevation'): a height separate from the map position, with gravity, a takeoff speed and a landing. | in-flight | T-183 |
| 3 | S4 | The illusion of height: lifted car drawing, shadow on the ground, placeholder platform and ramp | unblocks 3, value 5 | In this 2D game height is only seen through the drawing: the car lifts up the screen with its height while its shadow stays on the ground (Drifting, Decisions, 'Elevation'). The functional work starts with placeholders, not waiting for the art. | in-flight | T-185 |
| 4 | S5 | PixelLab art for the ramp and the raised platform | unblocks 1, value 5 | The board asked for PixelLab art for both in this goal. | in-flight | T-186 |
| 5 | S3 | How the platform's sides meet the car | unblocks 1, value 4 | Driving up the ramp and jumping off the edges only works if the platform's sides behave consistently with the car's height (driving into a drop-off edge from the ground, landing on the platform, falling off it). | in-flight | T-184 |
| 6 | S7 | Document the build and keep the docs in sync | unblocks 0, value 4 | A task is not done until its affected docs are updated; the separate docs are the source of truth and the goal's criteria check them. | in-flight | T-188 |
| 7 | S6 | Option: car drawn slightly bigger when high | unblocks 0, value 2 | Drifting, Decisions names drawing the car slightly bigger when high as an option for the board's playtest. | in-flight | T-187 |

### S1: Ground-height data for the test scene: one platform, one ramp, drop-off edges

Needs: nothing.

- The test scene's layout is stored as data (a file under game/data/ or the scene's own data), with one raised platform (its outline and height) and one ramp on one of its sides (its footprint, the side it climbs, its bottom and top heights); the format is described in game/README.md.
- A ground-height query returns the height at any map point: 0 off the platform, the platform's height on top, and a straight rise along the ramp from 0 at its foot to the platform's height at its top; GUT tests cover a point in each zone and on the ramp's middle.
- The query tells a ramp from a drop-off edge: tests show that crossing the ramp side changes height gradually, and crossing any other edge is a step.

### S2: The car's real height: gravity, takeoff and landing

Needs: S1.

- The car has a height and a vertical speed, separate from its flat top-down position; its flat driving physics (50 steps per second, the Unity values) is unchanged, checked by the existing driving tests passing unchanged.
- GUT tests: on the ramp the car's height follows the ground; at the ramp's top or a drop-off edge with enough speed it leaves the ground with a takeoff vertical speed taken from its speed and the ramp's slope; in the air its height follows gravity; it lands when its height reaches the ground under it, and its vertical speed becomes 0.
- Gravity and any takeoff or landing numbers are in one place in data or code, listed in game/README.md as proposals for the board's playtest.

### S4: The illusion of height: lifted car drawing, shadow on the ground, placeholder platform and ramp

Needs: S2.

- In the isometric view the car's drawing is offset up the screen by its height (16 px per unit in the flat world, as the rest of the drawing), and a shadow is drawn at the car's map position on the ground under it; a test checks the offset for a known height.
- The platform and ramp are drawn in the isometric view with script-drawn placeholders (no Redgull red), in depth order with the car, so the car on the ground behind the platform is drawn under it and the car on the platform over it.
- Screenshots from the running scene, saved with the task, show the car on the ground, on the ramp, on the platform and in the air past a drop-off edge, each with its shadow.

### S5: PixelLab art for the ramp and the raised platform

Needs: S4.

- The Asset Generation Agent writes its planned PixelLab calls and their cost in the task's result notes before calling, within the goal's art cap of 20, one round with no regeneration; weak results are noted, not regenerated.
- Game-ready ramp and platform images are in game/art/ with their PixelLab record .json files; every other generation is kept in art-archive/<task>/.
- The art follows Visual style, Decisions: 32 art px per unit drawn at scale 0.5, hard pixel edges, no semi-transparent pixels, about 30 colours or fewer per sprite (checked by script), transparent background, no Redgull red.
- The art replaces S4's placeholders in the test scene, which still runs headless without errors; a screenshot shows the car on the platform and in the air beside it with the final art.
- docs/visual-style.md records the ramp and platform art (what was made, with how many generations).

### S3: How the platform's sides meet the car

Needs: S1, S2.

- GUT tests show the behaviour of the car meeting a drop-off edge from the ground below, as written in the docs (the proposal for the open question, recorded in docs/drifting.md or docs/level-design.md).
- GUT tests show the car landing on the platform's top when its jump ends over it, and landing on the ground when it ends off it; it never ends a step inside the platform.
- Driving off the ramp's sides (not its top) behaves as the docs' recorded proposal says, with a test.

### S7: Document the build and keep the docs in sync

Needs: S3, S5.

- docs/drifting.md, Content, has an 'Elevation test scene' section: where the scene is, how to run it, what the car's height does, and every proposed number marked as a proposal.
- docs/level-design.md, Content, describes the test platform, ramp and drop-off edges and the height data format.
- game/README.md has the scene's path, how to run it, its data format and the code's main functions.
- The docs staleness check passes after the long GDD is regenerated.

### S6: Option: car drawn slightly bigger when high

Needs: S4.

- A switch, off by default, makes the car's drawing scale up with its height; how it is switched is recorded in game/README.md.
- A test checks the drawing's scale is 1 at height 0 and larger at a known height when the switch is on, and always 1 when it is off.

## Scoring

Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. A sub-goal is therefore always ranked before every sub-goal that needs it. A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.

## Tickets

- T-182: Elevation test scene: ground-height data (one platform, one ramp, drop-off edges) and a ground-height query (S1, written)
- T-183: The car's real height: gravity, takeoff from the ramp's top and drop-off edges, and landing (S2, written)
- T-184: Elevation: how the platform's sides meet the car (drop-off edge from below, landing on top or beside, the ramp's sides) (S3, written)
- T-185: Elevation test scene: the car's drawing lifts with its height, a shadow on the ground, placeholder platform and ramp (S4, written)
- T-186: Art: the ramp and the raised platform for the elevation test scene (PixelLab) (S5, written)
- T-187: Elevation test scene: an option to draw the car slightly bigger when high (off by default) (S6, written)
- T-188: Elevation test scene: final check of its documentation in Drifting, Level design and the game README (S7, written)

## Iteration log

- 2026-10-19, iteration 0: started: planning.
- 2026-10-19, iteration 0: priority scoring: 7 sub-goals ranked, 8 goal criteria, 12 open questions.
- 2026-10-19, iteration 0: gap detection: 0 covered, 0 in flight, 7 missing; wrote 7 tickets.
- 2026-10-19, iteration 0: building.
- 2026-10-19, iteration 1: T-182 (S1, level-challenge, sonnet): passed (done, QA rounds 1), merged into playtest/G-003; art 0; agent: T-182 is built and committed on its branch. The data file `game/data/level/elevation_test.json` holds a list of platforms and a list of ramps, with one 16 by 16 platform at height 3 and an east-side ramp rising from 0 to 3. `game/scripts/level/ground_height.gd` has `height_at`, `is_ramp`, `ramp_at` and `edge_between`. 9 new GUT tests pass, and the full headless suite passes with no existing test changed. The new sections are in `game/README.md` and `docs/level-design.md`, with every number marked as a proposal. I left the Godot `.import` line-ending changes out of the commit. Refused, got past and not blocking: QA: {"tool_input": {"command": "$p='C:\\solid-carbide-worktrees\\T-182\\tasks\\T-182-elevation-test-scene-ground-height-data.md'\n$c=Get-Content $p -Raw -Encoding utf8\n$c=$c.Replace('(QA: pass / fail)','(QA: pass)')\n[IO.File]::WriteAllText($p,$c,(New-Object Text.UTF8Encoding $false))\ngit add tasks/T-182-elevation-test-scene-ground-height-data.md\ngit commit -m \"T-182: QA round 1 pass\" -m \"Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>\""}, "tool_name": "PowerShell", "tool_use_id": "toolu_01YJi9hpegroDrjuWprJHYDT"} / QA: A PowerShell edit using New-Object Text.UTF8Encoding was refused by the constrained-language mode. It wasn't essential, so I made the same edit with the Edit tool instead.. Rescan: S1 covered, S2 in-flight, S3 in-flight, S4 in-flight, S5 in-flight, S6 in-flight, S7 in-flight.
- 2026-10-19, iteration 1: paused (see Pauses).
- 2026-10-19, iteration 1: resumed: its last pause (refusal: a headless session reported a refusal that blocked its work) can't be checked by the runner; --force.
- 2026-10-19, iteration 1: paused (see Pauses).

## Pauses

- 2026-10-19 [refusal]: QA on T-183 reported a refusal; the runner never works around one: [{'tool_name': 'Bash', 'tool_use_id': 'toolu_018U4HWX8W9jCnN8npTi9WZh', 'tool_input': {'command': 'python -c "\np=\'tasks/T-183-the-car-s-real-height-gravity.md\'\ns=open(p,encoding=\'utf-8\').read()\na=s.index(\'## Acceptance criteria\');b=s.index(\'## Updates\')\nseg=s[a:b].replace(\'(QA: pass / fail)\',\'(QA: pass)\')\ns=s[:a]+seg+s[b:]\ns=s.rstrip(\'\\n\')+\'\\n\\nQA round 1: all 8 criteria pass. Full GUT 982/982; existing driving tests unchanged in diff; test_car_height.gd 11 tests; numbers in car_height.gd and game/README.md.\\n\'\nopen(p,\'w\',encoding=\'utf-8\').write(s)\n"'}}, "PreToolUse hook refused the Bash command (a python one-liner editing tasks/T-183-the-car-s-real-height-gravity.md to mark criteria): 'Task statuses change only through the status script'. The edit only touched criteria marks and a note, not status/qa_rounds/lead. I did not work around it."]
- 2026-10-19 [merge]: Merging task/T-183-the-car-s-real-height-gravity into playtest/G-003 conflicted; the merge was aborted.

