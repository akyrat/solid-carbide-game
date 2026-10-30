---
id: T-405
title: Short buildings (low-rise, small, long) become connectable platforms at height 3, and everything on platforms works at its height
status: in-qa
from: project-lead
to: level-challenge
lead: Greenbull
epic: level
milestone: mvp
goal:
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/level-design.md, docs/visual-style.md, game/docs/level/]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/drifting.md, docs/visual-style.md, tasks/T-393-creator-objects-ignore-heights.md, game/docs/level/level-creator.md, game/docs/level/level-creator-pieces.md, game/docs/level/elevation-sample-map.md, game/scripts/level_creator/, game/scripts/level/, game/data/level/]
files_expected_to_change: [game/scripts/level_creator/, game/scripts/level/, game/scripts/run/, game/data/level/, game/art/buildings/, game/tools/, game/tests/unit/, game/docs/level/, docs/level-design.md, docs/visual-style.md, art-archive/]
model: opus
qa_rounds: 0
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

The board's decision (Level design, Decisions, "Short buildings become platforms", 2026-10-30). The board: "when I'm on platforms, a lot of stuff seems to not be working ... If I have a low-rise building directly placed on top of a platform, I hit the invisible building, which is correctly rendered under the platform, but I still hit it and I can't reach the end of the platform. And we don't define what happens when the player jumps off a platform and can he go over a building. So I'm deciding that the low-rise buildings no longer exist and they're just like better platforms. Keep the same asset but make it a platform, treat it as a platform, make the assets so that they can connect, and fix any bugs with altitude." The board's answers: height **3** (the art's walls trimmed by script), and the **small and long buildings too**; only skyscrapers stay solid buildings.

1. **Platforms:** the low-rise, small and long pieces become platforms at height 3 with their own art (walls trimmed by script from today's art; no PixelLab; keep the originals in `art-archive/<id>/`). The car drives on their roofs like a rooftop, reaches them by today's 0-to-3 ramps, falls off their edges, and enemies treat them as rooftops (today's navigation). Rooftop decorations (AC units, water tanks, vents, signs) still go on them, at their height. Whether they keep the see-through rule when the car is behind them is your proposal.
2. **Connecting:** two of them placed side by side (or a low-rise next to a 3-high rooftop) join into one surface: no walls or roof edges drawn between them, no seam the car bumps on. Script work on the art (edge and corner pieces cut from the existing art) where needed.
3. **Altitude audit:** list in the result notes every collider in the level (building bodies, platform and ramp walls, props, obstacles, the spawn point) and check each works at its height: nothing below a platform stops the car on top of it; the car that jumps off a platform falls to the ground or a lower platform; a skyscraper blocks it at any height. Fix what doesn't, with a test each. Pickups (gift packs and the others) are T-402's: don't change their code.
4. **Saved levels and the game's own map:** short buildings in them load as these platforms; `check_level.py` and the drivability check accept them. The board's levels are in the main checkout's `C:\solid-carbide-game\game\data\levels\` (untracked): copy them into your worktree to test (uncommitted), never write or commit them.

This ticket's worktree is branched from T-393's branch (its depth rule for objects on rooftops, waiting for the board's playtest), so it merges after T-393. Other agents work on the creator at the same time (T-394 pairs, T-400 small ramp, T-402 gift packs): keep to the buildings, platforms and colliders.

The board's review: in the creator, place short buildings side by side and next to rooftops, connect them with ramps, put props on them, press Play, drive across them, jump off them and try to reach every edge; open the board's own levels.

## Acceptance criteria

Written by the Project Lead. Each one must be something the QA/Integration Agent can realistically verify. QA writes a pass or fail next to each.

- [ ] The low-rise, small and long pieces are platforms at height 3: the car drives on them, reaches them by a 0-to-3 ramp and falls off their edges; enemies follow it there (tests). (QA: pass / fail)
- [ ] Two placed side by side, or one next to a 3-high rooftop, join with no wall or roof edge drawn between them and no bump crossing the join (tests, screenshots). (QA: pass / fail)
- [ ] The result notes list every collider and how it works at height; nothing below a platform stops the car on top of it, a jump off a platform lands on the ground or a lower platform, and a skyscraper blocks at any height (a test each). (QA: pass / fail)
- [ ] Saved levels with short buildings and the game's own map load them as platforms; check_level.py and the drivability check accept them (tests); the board's level files are unchanged and uncommitted. (QA: pass / fail)
- [ ] Level design (Content), Visual style and game/docs/level/ describe the platforms, the joins and the audit; the original art is kept in `art-archive/<id>/`. (QA: pass / fail)
- [ ] Screenshots of joined short platforms in the editor and the run, and a GIF of driving across them and jumping off, are in `art-archive/<id>/screenshots/`. (QA: pass / fail)
- [ ] All three test sets pass (`python -m unittest discover -s game/tools -p "test_*.py"`, `python -m unittest discover -s tools -p "test_*.py"`, `bash game/tools/run_tests.sh`), with the counts in the result notes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-30, Open → In progress

Started in build E (Platforms & heights), on top of T-393 and T-394.

### 2026-10-30, In progress → In QA

Short buildings are now platforms at 3 that join seamlessly, plus the altitude audit; all three test sets green apart from the known timing flake. Ready for QA.

## Style review

Only for art and text tasks: one entry per round of the style loop (`tasks/README.md`, "The style loop"), written by the loop's tool.

## Result notes

Written by the agent when it finishes.

Level/Challenge Design Agent, 2026-10-30. Built on `playtest/platforms` (T-393 and T-394 in). T-393's notes read first: its depth fix and edge rule are kept; "a building" in the edge rule now means a skyscraper.

**What was built**

- **One place for the rule:** `game/scripts/level/short_platforms.gd` (Python mirror `game/tools/short_platforms.py`). A building entry whose asset is `short-N`, `building-small` or `building-long` is a platform at height 3 (id `building@<x>,<y>`, from where it stands). The level file is unchanged, so every saved level loads them as platforms. Only skyscrapers (and the game map's skyscraper slots) are walls (`wall_rects`).
- **Height data:** `GroundHeight.load_data` appends those platforms after the file's rooftops, so the car's height and sides, the elevation layer (drawing, depth order, see-through), the props' and boulders' heights and the enemies' grid all treat them as rooftops. `mvp_map.gd` builds no wall and no building art for them (a hidden placeholder node keeps `buildings` in layout order; `fade_items()` skips it). `enemy_navigation.gd build_for_map` closes only `wall_rects`.
- **Creator:** `LevelDocument.surfaces()` (rooftops plus short platforms) drives `rooftop_under`, `ramp_target`, `_relink` and `LevelSnapping.ramp_snap`, so a 0-to-3 ramp snaps and links to a short building and a 6 can stand on one; `_relink` also runs when a building is placed or deleted. Objects go on them like on a rooftop (T-393's edge rule). The spawn may stand on one (`level_spawn.gd`, `check_level.py`). The catalogue shows the platform art in the panel and the preview (`build_creator_assets.py platform_art`, height 3).
- **Art, no PixelLab:** `game/tools/build_short_platform_art.py` (`--check`). It cuts the 8 low-rise bodies and the 6 small and long textures into `game/art/buildings/platforms/`: 14 sources x 4 images (alone, roof with no parapet, north-south parapets only, west-east only) plus `platforms.json`. Each wall loses a band under its top lip (134 or 138 rows become 96). The small and long buildings are widened to fill their footprint (one unit repeated in the middle) and lose their pavement. The parapets come out by reading the roof one unit further in. The rooftop props are never cut: the art is rebuilt from the PixelLab pieces in `art-archive/T-129/raw` and `T-257/raw` without its props (the rebuild is checked to equal today's files pixel for pixel), cut, and the props are pasted back whole. Originals copied to `art-archive/T-405/originals/` (they also stay in place, the old MVP map uses them).
- **Joins:** `elevation_platform_drawing.gd` building mode draws the roof from the clean piece, then each edge's parapet only where the edge is open (from the one-axis pieces, so a parapet never shows the corner of the other), the full corner where both edges are open, and the front walls only where open. `elevation_layer.gd joined_gaps` finds where a rooftop or short platform at its height or higher stands across an edge. Ramps break the parapet, as on rooftops. A rooftop's own parapet and outline also break along a short platform beside it. Same height, so no bump: the car crosses at exactly 3 (test).
- **The game's own map:** each short slot of its 30 x 30 blocks (5 on the sample map) is a platform on its 12 x 12 footprint. The block's skyscraper slots stay walls (15 x 15 with their pavement), and the pavement ring round a short one is open street. The old MVP map without heights is unchanged.

**Altitude audit (every collider, how it works at height)**

| Collider | At height |
|---|---|
| Skyscraper, a block's skyscraper slot (`map.walls`) | Wall at any height (test: blocked at 0, 3, 12, 40). |
| Map edges (`map.walls`) | Wall at any height (unchanged). |
| Short building, rooftop | No body. Its sides stop a car below its top (GroundHeight). A car at or above it drives or lands on it. Nothing of a short building remains under a rooftop (the board's bug: test with a low-rise half under a rooftop). |
| Ramp | No body. Its sides are ground-height walls, its foot and top are open (unchanged). |
| Props (8 kinds) | Before: a body at any height. Now from the ground under the centre to that ground + its height (`base_units`/`top_units`). `mvp_map.update_car_obstacles` makes it passable to a car above or below it, called after every car step in the run and the elevation sample scene (tests: a street barrier stops a car on the street, not one flying over it; a car on a rooftop passes a street boulder that reaches under the rooftop's edge). |
| Placed boulders | Same, from their ground up by their diameter. |
| Meteor boulders | Same, from the street up by their diameter. |
| Spawn point | Not a body. The car starts at the ground's height, a short building's 3 included. |
| Pickups | T-402's, not touched. |

Jumping off a platform lands on the ground (test: off the rooftop over a barrier) or on a lower platform (test: off a 6 onto a low-rise at 3).

**Proposals for the board's playtest**

1. See-through: a short building fades while it covers the car behind it, like the rooftops (never when the car is on it).
2. A prop or boulder across the join between two short buildings is refused (T-393's one-surface rule); it could be allowed later.
3. A car that lands overlapping a prop or boulder keeps passing through it until clear (it slides off rather than being pushed out).
4. Prop and boulder heights: a prop's drawn height (props.json), a boulder's diameter.
5. Game map: the pavement round a block's short building is open street, and there is no ramp to the 5 platforms (reached only from the air).
6. Old levels: a prop whose centre lies inside a short building (Kaiju City's prop-19) now stands on its roof and blocks a car up there.

**T-411 (the car's whole footprint, not built here).** Today the car's height uses its centre point (`car_height.gd _walk`), so the drawn front can pass 1.5 units into a short building's side before the bounce, and the car hangs 1.5 units over an edge before it falls. My work doesn't change that. With T-411's recommended approach A, the sides would meet the drawn outline and nothing here would need to change: joined short platforms are one height, so the outline meets no step across a join. The obstacle exceptions (`update_car_obstacles`) use the car's height and its collision shape, not its centre, so they need no change either. T-411's ramp-launch fix would make the T-405 level's ramp launch the same way it does now (it already launches at speed).

**Also noted.** The board's three level copies give the same `check_level.py` output before and after: unlinked 3-to-6, 0-to-6 and 0-to-3 ramps that touch no area at their height, already there on master. The copies were not changed or committed. The T-129 fixture `tests/fixtures/short_building_shot.tscn` no longer finds a short slot node (they are platforms now); it is a screenshot fixture only.

**Tests**

- New: `game/tests/unit/level_creator/test_short_platforms.gd` (16 tests), `game/tools/test_short_platforms.py`, `game/tools/test_build_short_platform_art.py`, a spawn test in `game/tools/test_check_level.py`, a catalogue test in `game/tools/test_build_creator_assets.py`.
- Updated for platforms: `test_small_long_buildings.gd`, `test_creator_objects_heights.gd`, `test_creator_spawn.gd`, `test_editor_rotate_heights.gd`, `test_car_height_layers.gd` (boulders now passed over at 3, 6 and in the air), the sample-map area counts (`test_elevation_sample_map`, `test_elevation_sample_art`, `test_run_elevation_map`, `test_run_layout_path`, `test_editor_place_delete`, `test_creator_pieces_any_size`, `test_play_level`), `test_creator_assets.gd`, the kaiju and minion "round a building" tests (a block with no short building).
- Counts:
  - `python -m unittest discover -s game/tools -p "test_*.py"`: 685 tests OK (1 skipped).
  - `python -m unittest discover -s tools -p "test_*.py"`: 579 tests OK.
  - `bash game/tools/run_tests.sh`: 1985 tests, 1984 passing, 1 failing: `tests/unit/run/test_run_likes.gd` `test_run_scene_drift_pays_its_combo_once_when_it_ends`. It is the same load-dependent timing test T-393 reported. Run on its own it passes 37/37. `test_short_platforms.gd` was run again on its own after its last test (check_level) was added: 16/16.

**Screenshots** in `art-archive/T-405/screenshots/`: `editor_joined.png` (joined low-rises, small and long buildings and a rooftop in the editor), `run_joined.png` (the car on them in a run), `game_map_block.png` (the game map's first block, its two short buildings as platforms), `drive_across_and_jump_off.gif` (up the ramp, across the joins, off the rooftop over a barrier into the skyscraper). Fixtures: `tests/fixtures/t405_platforms_demo*.tscn`, level `t405_platforms_level.gd`.

**Documents affected:** `docs/level-design.md` (Content, "Short buildings as platforms" with the audit table; the Props and T-393 bullets updated); `docs/visual-style.md` (Content, "Short buildings as platforms"); `game/docs/level/level-creator-pieces.md` ("Short buildings as platforms (T-405)"); `game/docs/level/level-creator.md` (pointer).

Board review files: art-archive/T-405/screenshots/editor_joined.png, art-archive/T-405/screenshots/run_joined.png, art-archive/T-405/screenshots/game_map_block.png, art-archive/T-405/screenshots/drive_across_and_jump_off.gif
