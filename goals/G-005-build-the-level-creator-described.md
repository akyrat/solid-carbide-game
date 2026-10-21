---
id: G-005
title: Build the level creator described in docs/level-design.md, Decision...
status: building
art_cap: 0
art_used: 0
iteration: 4
max_iterations: 20
created: 2026-10-21
lead: Goal-G-005
session: Coursework
---

## Goal

Build the level creator described in docs/level-design.md, Decisions, 'Level creator' (board, 2026-10-21): a separate Godot app or scene (launched like the game, not reachable from the game's menus, not part of what players get) that lists the levels made so far, plays any of them as a full run (8 minutes, enemies, kaiju, as the game's own run on the elevation map), and creates or edits a level: a side panel with every asset already in the game (ground tiles, roads, buildings, boulders, rooftops and ramps at heights 3 and 6), place, rotate between the views the art has and mirror, delete, snapping to the map's tile grid and to close neighbours, and save. Levels are saved in the same map-file format the elevation map uses, so the run, the heights and the enemies' pathfinding work on them unchanged. No new art. The board plays it once at the end: it must be possible to create a level from nothing, save it, see it in the list, and play it.

## Goal acceptance criteria

- [ ] A level creator scene exists in the game project (e.g. game/scenes/level_creator/level_creator.tscn) with a launch command or script documented in game/README.md, 'Level creator'; it opens headless without errors, and it is not reachable from any of the game's menus (no button or scene change to it in the main menu, pause or garage scripts) and is excluded from export presets. (QA: pass / fail)
- [ ] With an empty levels folder the creator's first screen shows only a 'new level' button; with N saved levels it lists exactly N entries (a test checks both cases). (QA: pass / fail)
- [ ] A scripted end-to-end test, driven on branch playtest/G-005, creates a level from nothing in the editor scene (places ground/road tiles, at least one building, one boulder, a height-3 rooftop with a 0-to-3 ramp and a height-6 rooftop with a 3-to-6 ramp, uses rotate/mirror and delete at least once), saves it, returns to the list and finds it there, then starts a full run on it: the run's timer starts at 8:00, minions spawn, and the run's map has the saved level's buildings, boulders, platforms and ramps. (QA: pass / fail)
- [ ] Every level file the creator saves passes python game/tools/check_height_data.py and the creator's own level validator, and is in the same map-file format as game/data/level/elevation_sample_map.json (the same top-level fields the run reads: map, buildings, ground_rows, legend, pattern_copies/boulders, platforms, ramps). (QA: pass / fail)
- [ ] Loading game/data/level/elevation_sample_map.json into the editor and saving it without changes gives a file the run builds into the same map (same buildings, boulders, platforms and ramps); a test checks it. (QA: pass / fail)
- [ ] On a saved custom level with a ramp, enemy navigation builds a path from the street to a rooftop through the ramp (a unit test on the saved file). (QA: pass / fail)
- [ ] A run started from the game's main menu still plays on game/data/level/elevation_sample_map.json, unchanged; the existing GUT unit tests, the Python tool tests and the run tests all pass on playtest/G-005. (QA: pass / fail)
- [ ] No new art: the set of PNG files under game/art/ on playtest/G-005 is the same as on master before the goal, and no PixelLab call is recorded in any G-005 ticket. (QA: pass / fail)
- [ ] Screenshots of the level list (empty and with levels), the editor with its side panel and placed pieces at heights 0, 3 and 6, and a run on a custom level are saved under art-archive/<ticket>/screenshots/ for the goal's tickets. (QA: pass / fail)

## Open questions

- How the creator is launched: a scene in the same Godot project started by a command/script (proposal), or a separate Godot project that shares the game's assets?
- Where levels are saved: a folder in the repo (e.g. game/data/level/levels/, so they are kept in git; proposal) or the user's data folder (user://)?
- Buildings: the map file stores buildings as 30 by 30 block rectangles and the game picks the 4 skyscrapers and their variants per block by a rule. Does the board place whole blocks (format unchanged), or individual skyscrapers/short buildings with a chosen view and mirror (which needs optional new fields the run must read)?
- Map size: always 240 by 240 units like today, or chosen per level?
- The car's start: always the map's centre (0, 0) as in the run today, or placed by the board in the editor? What happens if something is built at the start?
- Rooftop and ramp sizes: any rectangle the board drags out, or fixed pieces (e.g. a 30 by 30 block rooftop, a 10 by 12 ramp as on today's map)?
- Boulders: placed one at a time, or as the Single Boulder / Two Boulders pattern copies?
- Ground: what an empty cell is on a new level (road, gravel or nothing), and whether gravel counts as a ground tile in the panel.
- Are the kaiju alert banners and signs on buildings part of the panel, or left out?
- Assets with no mirrored art: may the creator flip them in the engine, or offer only the views and mirrors that exist as files?
- How a level is named: typed by the board, or an automatic name?
- After a run on a custom level ends (win, loss or quit), does the board go back to the creator's list, or to the game's own end screens?
- Can levels be deleted or copied from the list?
- Is undo needed in the editor?
- The creator's text is never shown to players: does it still need the Narrative Theme Agent's text task (planned, following the project rule), or may it use plain labels?

## Sub-goals

| rank | id | title | score | why | verdict | tickets |
|---|---|---|---|---|---|---|
| 1 | S2 | Level storage, listing and validation | unblocks 7, value 5 | The creator must list the levels made so far, load one to edit or play, and save files the run accepts unchanged. | covered | T-231 |
| 2 | S4 | Text for the creator's screens | unblocks 7, value 4 | Project rule: any text a task shows on screen comes from the Narrative Theme Agent first, with no placeholder text; the list and editor screens need button and label text. | covered | T-233 |
| 3 | S3 | Catalogue of every asset already in the game | unblocks 6, value 5 | The side panel must offer every existing asset (ground tiles, roads, buildings, boulders, rooftops, ramps) with the views and mirrors the art actually has, without new art. | covered | T-232 |
| 4 | S6 | Editor scene: canvas, side panel, place and delete | unblocks 5, value 5 | The core of creating a level: see the map as the game draws it, pick an asset from the panel, place it, delete it. | in-flight | T-235, T-232 |
| 5 | S7 | Rotate, mirror and heights | unblocks 3, value 5 | The goal asks to rotate between the art's views and mirror before placing, with rooftops and ramps at heights 3 and 6 as on today's map. | in-flight | T-236 |
| 6 | S1 | The run can play any map file | unblocks 2, value 5 | The creator plays levels as the game's own run; today the run's layout path is a constant, so the run, the elevation layer and enemy navigation must take a level path while the game's default stays the elevation sample map. | covered | T-230 |
| 7 | S5 | Creator launch and level list screen | unblocks 2, value 5 | The board opens the creator like the game and picks a level or creates a new one. | in-flight | T-234, T-233, T-231 |
| 8 | S9 | Save and reopen levels | unblocks 2, value 5 | Levels must be saved in the elevation map's file format so the run, the heights and pathfinding work unchanged, and existing levels must be editable. | in-flight | T-238, T-231 |
| 9 | S10 | Play a level as a full run from the creator | unblocks 1, value 5 | The board must play any listed level as the game's own run: 8 minutes, enemies, kaiju, on the elevation map. | in-flight | T-239 |
| 10 | S8 | Snapping to the tile grid and to close neighbours | unblocks 1, value 4 | The board wants pieces to align with little effort. | in-flight | T-237 |
| 11 | S11 | End-to-end check: from nothing to playing | unblocks 0, value 5 | The board's playtest condition: create from nothing, save, see it in the list, play it. | in-flight | T-240 |

### S2: Level storage, listing and validation

Needs: nothing.

- A levels folder is defined and documented in game/README.md, 'Level creator' (location per the open question's answer or the agents' proposal).
- A script/class provides list_levels(), load_level(path) and save_level(path, data); a unit test saves a level, lists it, loads it back and gets equal data.
- A level validator (extending python game/tools/check_height_data.py or calling it) also checks: every building, rooftop, ramp and boulder lies inside the map; edges of buildings, rooftops and ramps lie on even units (enemy_navigation.gd's CELL = 2); ground_rows' size matches the map; it has Python tests that pass on a valid file and fail on each broken case.
- elevation_sample_map.json passes the validator.

### S4: Text for the creator's screens

Needs: nothing.

- A text file (or section in hud-and-menus.md / level-design.md as the agent proposes) lists each piece of creator text: the list screen's title and new-level button, the play and edit actions, the side panel's category names, rotate/mirror/delete/save labels and the save confirmation, each with where it appears.
- Every text the UI tasks S5 to S9 show is taken from that list (a test or grep finds no other hard-coded label strings in the creator scripts).

### S3: Catalogue of every asset already in the game

Needs: nothing.

- A data file (e.g. game/data/level/creator_assets.json), built by a script from the existing art data (skyscrapers.json, boulders.json, the ground atlas, the elevation platform and ramp art), lists each placeable asset with its id, kind, footprint in units, the views and mirrors it has, and for rooftops and ramps the heights 3 and 6 (ramps 0-to-3 and 3-to-6).
- A test checks every texture the catalogue names exists under game/art/ and that every building, boulder, ground and elevation texture the map uses today appears in the catalogue.
- No PNG under game/art/ is added or changed.

### S6: Editor scene: canvas, side panel, place and delete

Needs: S3, S2, S4.

- The editor draws the level in the game's isometric view with the game's own map and elevation drawing code (the same scripts as the run).
- The side panel shows every asset in the creator catalogue, grouped by kind.
- A scripted test places one of each kind (ground tile, road, building, boulder, rooftop, ramp) and the level data then holds each; deleting one removes it from the data and the drawing.
- Screenshot of the editor with the panel and placed pieces.

### S7: Rotate, mirror and heights

Needs: S6.

- Before placing, the selected asset can step through its catalogued views and mirror; only views and mirrors the art has are offered (a test per asset kind).
- Rooftops can be placed at height 3 and at 6 (a 6 standing on a 3, written with the 'on' field); ramps 0-to-3 and 3-to-6 with the side they climb; the result passes check_height_data.py.
- Screenshot of rooftops at 3 and 6 with their ramps in the editor.

### S1: The run can play any map file

Needs: nothing.

- run.gd (or its start function) accepts a layout file path; with none given it uses game/data/level/elevation_sample_map.json exactly as today (existing run tests pass unchanged).
- A unit test starts a run on a copy of elevation_sample_map.json saved under another path with one building and one platform removed: the run's map has one building and one platform fewer, and the elevation layer reads the same file (not the constant).
- A unit test on that copied file: enemy navigation builds and returns a path from a street cell to a rooftop cell that passes through a ramp.
- game/README.md, 'The run', says how to start a run on another map file.

### S5: Creator launch and level list screen

Needs: S2, S4.

- The creator scene opens from a documented command/script (game/README.md, 'Level creator') without errors, headless and windowed.
- No game menu script references the creator scene, and the export presets exclude it.
- With no levels, the screen shows only the new-level button; with levels, it lists each by name with its play and edit actions (unit tests for both).
- Pressing new level opens the editor scene with an empty map; pressing edit opens the editor with that level loaded.
- Screenshots of the empty and filled list are saved.

### S9: Save and reopen levels

Needs: S6, S7, S2.

- Saving writes a map file to the levels folder with map, legend, ground_rows, buildings, boulders (pattern_copies), platforms and ramps that passes the S2 validator.
- Opening elevation_sample_map.json in the editor and saving gives a file the run builds into the same buildings, boulders, platforms and ramps (test).
- A saved level appears in the list screen after saving (test).

### S10: Play a level as a full run from the creator

Needs: S1, S5, S9.

- Pressing play on a listed level starts the run on that file: timer at 8:00, minions spawning, the kaiju appearing at its usual time (a test fast-forwards the run state), and the map holding the level's pieces.
- Enemy navigation on the custom level finds a path through its ramp (test).
- When the run ends the board gets back to the creator (or as the open question's answer says).
- Screenshot of a run on a custom level.

### S8: Snapping to the tile grid and to close neighbours

Needs: S6.

- Every placed piece snaps to the map's tile grid, so its edges lie on even units (a test with off-grid cursor positions).
- A piece placed within the snap distance of a neighbour (documented value, a proposal) lines its edge up with that neighbour's edge, for example a ramp's top end onto a rooftop's side (unit tests).
- Pieces that would overlap in a way the validator refuses are not placed, or are flagged (as the agent proposes).

### S11: End-to-end check: from nothing to playing

Needs: S7, S8, S9, S10.

- A scripted test on playtest/G-005 creates a level from an empty creator, places at least one asset of every kind with rotate/mirror and delete used, saves, finds it in the list and starts a full run on it with the timer at 8:00 and minions spawning.
- All existing test sets pass, and a run from the game's main menu still uses elevation_sample_map.json.
- game/README.md, 'Level creator' explains how to open it, where levels are saved and the controls.

## Scoring

Ranked by code, not by Claude: first by how many other sub-goals wait on it (directly or further down the chain), then by value (Claude's estimate, 1 to 5), then by Claude's order. A sub-goal is therefore always ranked before every sub-goal that needs it. A dependency cycle is refused. Score column: unblocks N (sub-goals waiting on it), value V.

## Tickets

- T-230: The run can play any map file, with the elevation sample map as the default (S1, written)
- T-231: Level creator: the levels folder, saving, listing and loading levels, and a level validator (S2, written)
- T-232: Level creator: a catalogue of every placeable asset already in the game, built by script (S3, written)
- T-233: Text: the level creator's screens (S4, written)
- T-234: Level creator: its own launch command and the level list screen (S5, written)
- T-235: Level creator: the editor's map canvas, the side panel, placing and deleting pieces (S6, written)
- T-236: Level creator: rotate between the art's views, mirror, and rooftops and ramps at heights 3 and 6 (S7, written)
- T-237: Level creator: pieces snap to the tile grid and to close neighbours (S8, written)
- T-238: Level creator: save a level, and reopen it (S9, written)
- T-239: Level creator: play a listed level as a full run, and come back to the creator (S10, written)
- T-240: QA: the level creator end to end, from an empty creator to playing a level (S11, written)

## Iteration log

- 2026-10-21, iteration 0: started: planning, by the session Coursework.
- 2026-10-21, iteration 0: priority scoring: 11 sub-goals ranked, 9 goal criteria, 15 open questions.
- 2026-10-21, iteration 0: gap detection: 0 covered, 0 in flight, 11 missing; wrote 11 tickets.
- 2026-10-21, iteration 0: building.
- 2026-10-21, iteration 1: T-231 (S2, level-challenge, sonnet): passed (done, QA rounds 1), merged into playtest/G-005; art 0; agent: T-231 is built and committed on its branch. It adds `LevelStore` (list, load and save levels), the `check_level.py` validator and a 'Level creator' section in `game/README.md`. I propose `game/data/levels/` (read as `res://data/levels/`) as the levels folder, written up in the result notes for the board. The sample map passes the validator, the 15 new validator tests and the 6 new GUT tests pass, the Python tool suite (408 tests) passes, and the full GUT suite passes. There is nothing to screenshot (tooling only), and the result notes say so. Rescan: S1 in-flight, S2 covered, S3 in-flight, S4 in-flight, S5 in-flight, S6 in-flight, S7 in-flight, S8 in-flight, S9 in-flight, S10 in-flight, S11 in-flight.
- 2026-10-21, iteration 2: T-233 (S4, narrative-theme, sonnet): passed (needs-playtest, QA rounds 1), merged into playtest/G-005; art 0; agent: I wrote game/data/level/creator_texts.json with 26 pieces, each with a text and a "where it appears" note. I added a "Level creator text" section to docs/level-design.md, Content, pointing to the JSON, and wrote the result notes (text only, nothing to screenshot). Everything is committed on the task branch. I did not validate the JSON with a parser, because my `python -c` check was refused. The longest button is "Back to list" (12 characters) and the longest category name is "Buildings" (9), both checked by eye. The controls hint uses R, M and Del, which are my proposal, so the creator's scripts must use the same keys. Refused, got past and not blocking: narrative-theme: {"tool_input": {"command": "python -c \"import json;d=json.load(open('game/data/level/creator_texts.json'));print(len(d),max(len(v['text']) for k,v in d.items() if k!='note' and 'text' in v))\""}, "tool_name": "Bash", "tool_use_id": "toolu_01HCF43kfr379TKPpNs8mv4L"} / narrative-theme: Wanted to run `python -c` to parse creator_texts.json and measure text lengths; it needs approval and was refused. I skipped it (not essential) and checked by eye instead.. Rescan: S1 in-flight, S3 in-flight, S4 covered, S5 in-flight, S6 in-flight, S7 in-flight, S8 in-flight, S9 in-flight, S10 in-flight, S11 in-flight.
- 2026-10-21, iteration 3: T-232 (S3, level-challenge, sonnet): passed (done, QA rounds 1), merged into playtest/G-005; art 0; agent: Wrote game/tools/build_creator_assets.py, which builds game/data/level/creator_assets.json from the existing art data. The catalogue has 104 entries (ground, road, building, boulder, rooftop at heights 3 and 6, ramp 0-3 and 3-6), each with footprint, views, mirrors and texture paths, plus a list of the building pavements. Running the script twice gives the same file. The 8 Python tests and the 8 GUT tests pass, the README line is added, and no PNG changed. It is committed on the task branch; nothing to screenshot (data and tooling), noted in the result notes. Godot's `.import` files show as modified from the test run; I left them uncommitted. Rescan: S3 covered, S1 in-flight, S5 in-flight, S6 in-flight, S7 in-flight, S8 in-flight, S9 in-flight, S10 in-flight, S11 in-flight.
- 2026-10-21, iteration 4: T-230 (S1, game-loop, opus): passed (done, QA rounds 1), merged into playtest/G-005; art 0; agent: The run can now play any map file. run.gd has a `layout_path` setting (it starts at the elevation sample map, and an empty value falls back to it), and `start_run(path)` can also set it. That one path builds the map, the elevation layer and, through the map, the enemies' navigation, so the main menu's run is unchanged. New test file tests/unit/run/test_run_layout_path.gd (9 tests) uses a user:// copy of the map with one building and roof-se-6 (with its ramp) removed; the full GUT suite passes headless (1311 of 1311), game/README.md "The run" says how to start a run on another map file, and the result notes say there is nothing to screenshot. Rescan: S1 covered, S5 in-flight, S6 in-flight, S7 in-flight, S8 in-flight, S9 in-flight, S10 in-flight, S11 in-flight.

## Pauses

None yet.

