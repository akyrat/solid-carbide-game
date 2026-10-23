---
id: T-264
title: "Level creator: closed ramps, arrows up or down, and S, M and L platforms"
status: in-qa
from: project-lead
to: level-challenge
lead: Coursework
epic: level-challenges
milestone: mvp
goal:
user_facing_text: yes
changes_visuals: yes
depends_on: [T-261]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/scripts/level/elevation_platform_drawing.gd, game/scripts/level/elevation_layer.gd, game/scripts/level_creator/, game/tools/build_creator_textures_t255.py, tasks/T-251-resizable-rooftops-and-ramps.md, tasks/T-255-art-creator-textures.md, tasks/T-262-creator-panel-grouped.md]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/tools/, game/art/creator_pieces/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-264/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22), three fixes to T-251's pieces, all drawn in the engine (no PixelLab):

1. **Closed ramps:** every ramp (each direction, each height step) is a closed block: its tall end gets a wall down to what it stands on, in the ramp side's texture, even where it meets a rooftop or building. Today that end is open and the ramp looks hollow.
2. **Arrows up or down:** today the ramp arrows point up the slope on some directions and down it on others. Every ramp, in every direction and height step, can have its arrows pointing **up** or **down** the slope, the board's choice per ramp (key A, labels from T-261), saved with the ramp; the default is up. The arrows always match the choice.
3. **Platform sizes:** besides dragging any size, a platform at height 3 or 6 can be placed in one click at **S 8 x 8**, **M 16 x 16** or **L 32 x 32** units (labels from T-261), chosen on the top bar; the plain click's default becomes M (today it is 84 x 30). Snapping and the overlap refusal apply as before.

The game's own map is unchanged. Built on T-262's branch (the Project Lead makes your folder). End with screenshots of ramps in all four directions with arrows up and with arrows down, their tall ends closed, and of S, M and L platforms at both heights.

## Acceptance criteria

- [ ] Tests show every ramp draws a wall at its tall end, in every direction and height step (QA: pass; 12 new tests in test_creator_ramps.gd pass; in the screenshots the tall end reads closed: east side wall is visible beside the platform in ramps_up_close, and the north/west ends meet the rooftop so the block is closed, though against a rooftop the end wall itself is hidden, as the agent noted)
- [ ] Tests show the arrows point up or down the slope as chosen, in every direction and height step, the choice is saved and reopened, and the default is up (QA: pass; arrows up/down, saved and default-up tests pass; ramps_up_close and ramps_down_close show the arrows flipping as chosen)
- [ ] Tests show S, M and L platforms place at 8, 16 and 32 units square at heights 3 and 6, and dragging still sizes them freely (QA: pass; S/M/L and drag tests pass)
- [ ] Screenshots are in `art-archive/T-264/screenshots/`; `game/README.md` describes the three; the game's own map is unchanged; the full GUT suite and all Python tool tests pass (QA: pass; 7 screenshots present, README section present, map data not touched by T-264, GUT 1551/1551, game/tools 483 OK, tools 451 OK)

The board's review: place ramps both ways round and S, M and L platforms.
Board review files: the screenshots in `art-archive/T-264/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-23, Blocked → In progress

Started on T-263's branch: closed ramps, arrows up or down, S, M and L platforms.

### 2026-10-23, In progress → In QA

Built: walls at every ramp's tall end, arrows up or down per ramp (A), one-click S, M and L platforms. Sent to QA.

## Result notes

Level/Challenge Design Agent, 2026-10-23.

**Built (no PixelLab):**
- **Closed ramps:** `elevation_platform_drawing.gd` `textured_faces()` now draws a wall at every ramp's tall end (`join_edge()`), down to what the ramp stands on, in the ramp side's texture, in all four directions and all height steps. The outline follows it. On the east and south ends the wall faces the view; on the west and north ends it faces away and is drawn behind the top (so against a rooftop it is mostly hidden, as geometry, but the block is closed).
- **Arrows up or down:** a ramp of any size has an optional `arrows` (`"up"` default, `"down"`) in the map file. `GroundHeight` reads it; the drawing's `arrow_direction()` gives the flat direction, and the top face flips the texture's v for "down". Key A (in `editor.gd` `KEY_ACTIONS`, `arrows_pick`) and the top bar's "Arrows up" and "Arrows down" (T-261 labels) set it for the next ramp; with a ramp selected and none picked, A turns that ramp's. `LevelDocument.place(..., arrows)` and `set_ramp_arrows`. The preview shows the choice.
- **Platform sizes:** top bar "S", "M", "L", "Any size (drag)" with a platform picked (`editor.gd` `PLATFORM_SIZES`: 8, 16, 32, a click places that square; default M, was 84 x 30). "Any size" is dragging, and its click gives M. Drags size freely; snapping and the overlap refusal unchanged.
- The size buttons show only with a platform picked, the arrow buttons only with a ramp picked.

**Proposals for the playtest:** A also turns a selected ramp; "Any size (drag)" plain click = M; the hidden-end walls.

**Tests:** new `game/tests/unit/level_creator/test_creator_ramps.gd` (12 tests: wall at the tall end for 3 ramps x 4 directions, wall reaches the base, arrows up and down in every direction and step through the uvs, default up, key A, saved and reopened, selected ramp, S, M, L at heights 3 and 6, default M, drag keeps its size, preview, overlap refusal, buttons). Older tests that assumed the 84 x 30 and 30 x 30 plain click now pass those sizes explicitly (`test_snapping.gd`, `test_editor_save.gd`, `test_editor_rotate_heights.gd`, `test_editor_place_delete.gd`, `test_creator_end_to_end.gd`), and `test_creator_pieces_any_size.gd` was updated for the closed ramp and the M click.
- Full GUT suite: 1551 of 1551 passed (the first full run was 15 failing from those old default sizes, now fixed).
- `python -m unittest discover -s game/tools`: 483 OK (1 skipped). `python -m unittest discover -s tools`: 451 OK.
- The game's own map is unchanged (its test still passes).

**Screenshots** in `art-archive/T-264/screenshots/` (fixture `game/tests/fixtures/level_creator_ramps_demo.gd` and the `level_creator_ramps_*.tscn` and `level_creator_sizes.tscn` scenes): `ramps_up.png`, `ramps_down.png` (a 3 platform with ramps from all four sides), `ramps_up_close.png`, `ramps_down_close.png`, `ramps_up_close_west.png`, `ramps_down_close_west.png`, `sizes.png` (S, M, L at heights 3 and 6). I looked at them: arrows point up the slope and down it as chosen, S, M and L read as 8, 16 and 32. One honest limit: the tall-end wall is visible only where the ramp's tall end faces the view and is not behind a rooftop; the screenshots show it on the south-facing sides, not as a distinct feature against the rooftop.

**Documents updated:** `game/README.md` ("Level creator", "Closed ramps, arrows up or down, platform sizes (T-264)"); `docs/level-design.md` (Content, "Level creator: closed ramps, arrows and platform sizes").
