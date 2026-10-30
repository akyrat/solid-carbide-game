---
id: T-398
title: Level creator: sidewalks painted with automatic curbs, and parked and broken cars as obstacles at four facings (placeholders)
status: needs-playtest
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-396, T-393, T-394, T-401]
documents_affected: [docs/level-design.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/data/level/creator_texts.json]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/data/level/, game/tools/check_level.py, game/tests/unit/, game/docs/level/, docs/level-design.md, art-archive/]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
lead: the name of the Project Lead session that owns the task; empty until a session claims it with python tools/task_status.py T-NNN --lead <Name> (tasks/README.md, "Owners").
epic and milestone: one of the ids listed in tasks/README.md.
goal: the goal id (G-001) when the goal runner wrote or reused the task; empty otherwise (tasks/README.md, "Goal runs").
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

Build the pieces with code-drawn placeholders in the city's palette; T-399 swaps the final art in. It starts after T-393 (object heights) and T-394 (chained pairs) are merged, since it touches the same creator code.
1. **Sidewalk** (Ground): painted with a brush like roads. Wherever a sidewalk tile meets a road the editor adds the curb edge itself (straights, outer and inner corners), as roads join themselves. In the run the car drives up over the curb: the sidewalk is a step under the 0.1-unit curb rule (Drifting, Decisions, "Curbs"), not a wall. Enemies cross it as they do today's ground.
2. **Parked car** and **broken car** (Obstacles): a few looks each (chosen by key, like other pieces' looks), each at four facings, top right, bottom right, bottom left, top left (turned by key). Solid obstacles like boulders: the car crashes into them, they cut the combo, and they can be paired (and chained) for thread the needle. They respect what they stand on (T-393's fix).
3. Names from T-396 into `creator_texts.json`. Saved levels keep the new pieces; levels saved before open unchanged; `check_level.py` accepts them. The game's own map is unchanged.

4. **Meteor crater** (Ground; board, 2026-10-30, added after this ticket was written; Level design, Decisions): holes the meteors left in the ground, a few looks chosen by key, placed on the ground (not painted). Not an obstacle: the car drives over it with no crash, and enemies cross it. Its name comes from T-401, so this ticket also depends on T-401.

The board's review: paint sidewalks along roads, place parked and broken cars at each facing and a few craters in the creator, then press Play, drive over the curbs and the craters and into the cars.

The board's decision (Level design, Decisions, "Sidewalks and parked cars in the level creator", 2026-10-30). The board: "add sidewalk assets that fit with the road ... and the buildings and other assets that we have, and make sure that it works well, consider the curb as well. And I also want a few different car assets that are just sitting parked, just normal, boring kind of cars. Generate some broken ones as well. And make it so that they sit at four rotations: top right, bottom right, bottom left, top left. This is for the level creator." The board's answers: parked cars are solid obstacles like boulders (crash into them, pairable for thread the needle); sidewalks are painted like roads with the curb added automatically where they meet a road, and the car drives up over the curb; PixelLab up to 50 generations for the whole set (T-397 and T-399 together), sample first. The tickets: T-396 (piece names), T-397 (art sample), T-398 (the pieces in the creator and the run, placeholders), T-399 (the full art set, swapped in). The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): read copies only, never write or commit them.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The sidewalk paints like a road and the curb appears by itself on every edge where it meets a road, straights and corners (tests). (QA: pass - tests cover straights, outer and inner corners, curb follows road changes)
- [ ] In a run the car drives up over the curb onto the sidewalk and back down, with no crash or bump to a stop (test). (QA: pass - drive test, no crash or slowing; a visible lift is not required by the criterion or the 0.1 curb rule)
- [ ] Parked and broken cars place at the four facings and each look, crash the car, cut the combo, and can be paired for thread the needle (tests). (QA: pass - facing, model, crash, combo and pairing tests)
- [ ] The new pieces save and reopen, an earlier level opens unchanged, check_level.py accepts them, and the game's own map builds as before (tests). (QA: pass - save/reopen, old level, check_level and own-map tests)
- [ ] The side panel shows T-396's names, read from `creator_texts.json`. (QA: pass - panel names test)
- [ ] Level design, Content and game/docs/level/ describe the pieces and their controls. (QA: pass - level-design.md and game/docs/level/level-creator-pieces.md both changed; qa_check's documents line is a directory-match artefact)
- [ ] Screenshots of sidewalks with curbs and cars at each facing in the editor, and a GIF of driving over a curb in a run, are in `art-archive/<id>/screenshots/`. (QA: pass - 4 files incl. curb_drive.gif)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass - qa_check ran all three sets green: 715, 579, GUT 2041)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Build G (street) started: the level-challenge agent is on it in C:\solid-carbide-worktrees\T-398.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

**Done (level-challenge, 2026-10-30).** Placeholders only, no PixelLab call (0 generations). Everything the board places is in the creator and plays in a run.

- **Sidewalk (Ground):** painted like a road (left-drag paints, right-drag erases, Del erases under the mouse), one ground tile (2 x 2 units) at a time (proposal, so a sidewalk can be one tile wide). It never paints over a road, building, platform or ramp. The curb is added by itself on every edge where it meets a road: straights, outer corners (two edges) and inner corners (road only diagonal), 47 curb pieces. The curbs follow the roads: painting or erasing a road next to a sidewalk changes its curb (`SidewalkBrush.rejoin`, run on every write of the ground cells).
- **In the run** the sidewalk is ground at the street's height, with the curb drawn on the tile (T-397's approved look, the surface drawn 3 art px raised). The car drives over both curbs with no crash, no slowing and no height change, which is the 0.1-unit curb rule with a 0 step. **For the playtest:** the car doesn't visibly lift onto the sidewalk. A real 0.1 step would need sidewalks in the height data, so I didn't add one. Say if the board wants it.
- **Parked car (3 models) and Broken car (2 models), under Obstacles:** V steps the model ("Model {n} of {count}"). R turns through the four facings, and the top bar names them ("Facing top right", bottom right, bottom left, top left: north, east, south, west). They are props, so they are solid like boulders: the car crashes, the combo is cut, enemies go round them, they stand at the height under them and respect edges (T-393), and they pair and chain for thread the needle. Proposals: footprint 2 x 3 units (3 along the facing), 1.35 high (broken 0.95), rect collision. Placeholder boxes from `build_prop_art.py` with a pale facing arrow, in muted city colours, no red.
- **Meteor crater (Ground, 3 models):** placed with a click, one ground tile each, drawn as a decal over the ground under everything else. No body: the car drives over it, enemies cross it, and it never blocks the start. Proposal: it goes on the street only and is refused where it would reach onto a building, platform or ramp. The placeholder is T-397's crater script with three seeds and hole sizes. As T-397 said, it reads small on the road.
- **Names** from T-396 and T-401 are copied into `creator_texts.json` (9 keys, every earlier key unchanged). The sidewalk shows no top-bar hint, because no sidewalk hint text exists and no placeholder text is used.
- **Saving:** sidewalks are ground tiles like the roads, cars are props, and craters go in a new `craters` list. `check_level.py` checks the craters. Levels saved before open unchanged (test). The game's own map has none of these pieces. Read-only check of the board's levels in the main checkout: the results are the same as master's checker (the kaiju_city and mynewlevel ramp messages and level_01's missing spawn were already there).
- **Tools:** `game/tools/build_street_pieces.py` (build/check) draws the sidewalk sheet and the craters from T-397's sample functions. `build_prop_final_art.py` now skips props without a SPECS entry (the cars, until T-399). T-399 swaps the art by replacing `art/ground/sidewalk_tiles.png` (+json), `art/craters/*` (+`data/level/craters.json`) and the car textures in `props.json`.
- **Tests:** new `game/tests/unit/level_creator/test_creator_street_pieces.gd` (18 tests), `game/tools/test_build_street_pieces.py`, `StreetPiecesTest` in `test_build_creator_assets.py`, `TestCheckCraters` in `test_check_level.py`. Earlier tests were updated for the 4 new buttons, the 5 new props and the new kind `crater` (test_creator_families, test_creator_props, test_creator_assets, test_build_prop_art, test_build_prop_final_art, test_check_level).
- **Test counts:** `python -m unittest discover -s game/tools -p "test_*.py"` 715 tests OK (1 skipped). `python -m unittest discover -s tools -p "test_*.py"` 579 tests OK. `bash game/tools/run_tests.sh` 2041/2041 passed.
- **Screenshots** (`art-archive/T-398/screenshots/`):
  - `editor_sidewalks.png`: two roads crossing with sidewalks and their curbs (straights and corners), three craters, the cars.
  - `editor_cars_facings.png`: every car model at each of the four facings, a parked car picked, top bar "Facing bottom right".
  - `curb_drive.gif`: a run, the car driving east off the road, up over the curb, across the sidewalk, down the far curb and over a crater, with no crash.
  - `run_on_sidewalk.png`: a frame of that drive.
  - Fixtures: `game/tests/fixtures/t398_street_editor.tscn` and `t398_curb_drive.tscn`.

Board review files: art-archive/T-398/screenshots/editor_sidewalks.png, art-archive/T-398/screenshots/editor_cars_facings.png, art-archive/T-398/screenshots/curb_drive.gif

**Documents affected:** `docs/level-design.md` (Content, new "Level creator: sidewalks, parked cars and meteor craters"), `game/docs/level/level-creator-pieces.md` (new "Sidewalks, parked cars and meteor craters (T-398)").
- 2026-10-30, in-progress → in-qa: Built with placeholders: sidewalk brush with automatic curbs (47 pieces), parked (3) and broken (2) cars at four facings as pairable obstacles, meteor craters (3) as ground decals. Tests: game/tools 715 OK, tools 579 OK, GUT 2041/2041. Screenshots and GIF in art-archive/T-398/screenshots/.
- 2026-10-30, in-qa → needs-playtest: QA round 1: all 8 criteria pass; curb is drawn only with no lift, which no criterion requires
