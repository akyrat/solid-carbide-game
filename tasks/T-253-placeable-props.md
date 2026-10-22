---
id: T-253
title: "Level creator: props (barriers, cones, crates, rooftop kit) as obstacles, in four rotations"
status: in-progress
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-250]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level/mvp_map.gd, game/scripts/level_creator/, game/tools/build_creator_assets.py, docs/game-loop-architecture.md]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/scenes/, game/tools/, game/data/level/, game/art/props/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-253/screenshots/]
model: sonnet
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). Add a **Props** category to the creator: pieces for laying out tracks on the streets and filling rooftops. The set (the Project Lead's plan; names from T-250): **concrete barrier** (a long low road barrier, 4 x 1 units), **traffic cones** (a small cluster), **crate stack**, **AC unit**, **water tank**, **roof vent**, **street lamp**, **rooftop sign**. Footprints are your proposals, on the 2 x 2 unit grid where they can be (the barrier can be 1 unit deep).

- Each prop comes in **four rotations** (facing north, east, south, west; R steps through them) and can be placed on the ground or on a rooftop (it stands at the height under it).
- Each prop is a **solid obstacle**: the car crashes into it like a boulder (the same crash rule, which cuts the combo), and enemies find their way round it. Your proposal: the cones and the lamp may be small round obstacles.
- **Placeholder look first:** a simple code-drawn shape per prop and rotation (a box with its top and two visible faces, never Redgull red), so the art can wait. T-256 generates the final art and swaps it in: keep each prop's textures per rotation in one data file (for example `data/level/props.json`) with its footprint and collision, so T-256 only changes art files and that data.
- Saved levels keep their props and pass `check_level.py` (extend it to check props lie inside the map). The game's own map is unchanged.

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. Run this after T-251 if both are in flight (the Project Lead builds it on T-251's branch), so props stand on the new rooftops. End with a screenshot of every prop in its four rotations placed in the creator, and a short GIF of the car crashing into a barrier in a run.

## Acceptance criteria

- [ ] Tests show each of the 8 props can be placed in four rotations on the ground and on a rooftop, is saved and reopened, and the saved level passes `check_level.py` (QA: pass / fail)
- [ ] Tests show the car collides with a prop (and the combo is cut as with a boulder) and enemies path round it (QA: pass / fail)
- [ ] Each prop's art, footprint and collision live in one data file; labels come from `creator_texts.json`; no Redgull red (QA: pass / fail)
- [ ] The screenshot and GIF are in `art-archive/T-253/screenshots/`; `game/README.md` describes props; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place props on the streets and rooftops, and drive into them.
Board review files: the screenshot and GIF in `art-archive/T-253/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started on T-251's branch: eight props as obstacles in four rotations, placeholder look first.

## Result notes

Written by the agent when it finishes.

**Built (Level/Challenge Design Agent, on T-251's branch).** A **Props** category with the eight props (names from T-250's `creator_texts.json`), each in four rotations (R), placed on the street or a rooftop, saved in the level's new `props` list, drawn and solid in the run.
- **One data file:** `game/data/level/props.json` holds per prop its footprint, height, collision (rect or circle), label key, the placeholder look, and per rotation the sprite PNG and its anchor pixel. T-256 swaps art by changing `game/art/props/*.png` and the `textures` entries only. The catalogue's `prop` entries come from it through a separate function, `prop_entries`, in `build_creator_assets.py` (one added line in `build()`), so a rebuild merges with T-252/T-254.
- **Placeholder art:** `game/tools/build_prop_art.py build` draws boxes and cylinders in code (no PixelLab, no cost): top and two faces, dark outline, a pale arrow on the top showing the facing; 32 sprites, at most 30 colours, alpha 0/255, no Redgull red (`check`).
- **Engine:** `game/scripts/level/level_props.gd` (`LevelProps`): a static body per prop on collision layer 1 (the car's `hit_obstacle` fires, so the combo is cut exactly as for a boulder), a sprite lifted by the ground height under its centre, in `map.prop_sprites`; `map.depth_sprites()` joins them to the boulders in the car's, the enemies' and the elevation layer's depth tests. `enemy_navigation.gd` closes the cells a prop takes; `is_open_spot` and both enemies' `is_free_spot` refuse spots inside one. Small hooks in `mvp_map.gd`, `elevation_layer.gd`, `enemy_depth.gd`, `enemy_navigation.gd`, `minion_spawner.gd`, `kaiju_boss.gd`.
- **Creator:** `level_document.gd` (place, piece_at, delete, placed_pieces, `height_at`, rotated footprint), `asset_panel.gd` (category, labels), `editor.gd` (preview of the picked rotation's sprite at its height). `check_level.py` has `check_props` (known prop and rotation, turned footprint, inside the map).

**Proposals for the playtest (all in `docs/level-design.md`, "Level creator: props"):** footprints (barrier and sign 4 x 1, tank 4 x 4, the rest 2 x 2), heights, the collision shapes (round for cones 0.9, tank 1.8, vent 0.9, lamp 0.4), no overlap refusal for props (only "would leave the map"), props snap to the 2 x 2 grid only, a prop's height is the ground under its centre. Known limit: the physics is flat, so a car in the air above a rooftop prop crashes into it. Open for the board: the top bar shows the prop's name but no "facing north" text (T-250 wrote none; the arrow on the sprite shows it), so a text task would be needed if the board wants one.

**Tests:** `tests/unit/level_creator/test_creator_props.gd` (16 tests: the catalogue, data file and labels, all 8 x 4 on the ground and on a rooftop, saved, reopened, `check_level.py` exit 0, outside-the-map refusal, select and delete, preview, height, the car crashing into a rectangular and a round prop and each of the eight with the combo cut by `ComboData.after_collision`, enemies' path round a barrier, spawn spots, no red), `tools/test_build_prop_art.py`, `tools/test_check_level.py` (`TestCheckProps`); `test_creator_assets.gd` and `test_build_creator_assets.py` know the new kind.

**Screenshots and GIF** (`art-archive/T-253/screenshots/`): `creator_street.png`, `creator_roof.png`, `creator_close.png` (every prop in four rotations, rows = props, columns north/east/south/west, on the street and on a rooftop at height 3), `creator_panel.png` (the Props category in the panel, the water tank's preview under the mouse), `drive.gif` and `drive_end.png` (the car driving into a barrier, a crate stack and a lamp in a run, crashing at each).
