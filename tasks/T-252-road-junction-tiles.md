---
id: T-252
title: "Level creator: road corners, T-junctions, crossroads and dead ends"
status: done
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/tools/build_ground_tiles.py, game/art/ground/ground_atlas.json, game/tools/build_creator_assets.py, game/data/level/creator_assets.json]
files_expected_to_change: [game/tools/, game/art/ground/, game/data/level/creator_assets.json, game/scripts/level/, game/scripts/level_creator/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-252/screenshots/]
model: sonnet
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). The creator has straight road tiles (plain, lane lines, zebra crossings, in both directions) but no way to turn or join roads. Add, drawn by script from the existing road tiles (`build_ground_tiles.py`; no PixelLab), the road pieces a street network needs, in every rotation: **corners** (4), **T-junctions** (4), a **crossroads**, and **dead ends** (4), at the same 2 x 2 unit tile size and in the ground atlas's style (asphalt, white lines, light cracks; Visual style, Decisions, "Ground"). Add them to the catalogue (rebuild `creator_assets.json`) under Roads, with their names from T-250, and make the existing ground tiles' x and y versions both show. The game's own map is unchanged.

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. End with a screenshot of a small street grid built in the creator using every new piece.

## Acceptance criteria

- [ ] The atlas and catalogue have corners, T-junctions and dead ends in 4 rotations and a crossroads; their lines join the straight tiles' lines without gaps (tests on the tile data, and the screenshot) (QA: pass; atlas and catalogue hold 4 corners, 4 T-junctions, 4 dead ends and a crossroads; test_lines_continue_the_straight_tiles checks the line pixels, and the screenshot shows lines running straight across every join with the existing two-tile straights)
- [ ] The tiles pass `check_sprite_rules.py`; the game's own map's ground is unchanged (a test) (QA: pass; test_pieces_pass_check_sprite_rules and the old-tiles-unchanged and games-own-ground GUT tests pass)
- [ ] The screenshot is in `art-archive/T-252/screenshots/`; `game/README.md` describes the pieces; the full GUT suite and all Python tool tests pass (QA: pass; screenshot present, README describes the pieces, GUT all passed, tools 439 OK, game/tools 425 OK)

The board's review: lay out a street grid with corners and junctions.
Board review files: the screenshot in `art-archive/T-252/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started: road corners, T-junctions, crossroads and dead ends, drawn by script.

### 2026-10-22, In progress → In QA

Built: corners, T-junctions, a crossroads and dead ends at the wide road's size, joining today's straights. Sent to QA.

### 2026-10-22, In QA → Needs playtest

QA passed all 3. Ready to play in the creator: lay out a street grid with corners, T-junctions, a crossroads and dead ends.

## Result notes

Level/Challenge agent, done (no PixelLab call, no cost).

- **Reworked after the first version** so the pieces join today's two-tile-wide roads (the Project Lead's change).
- **Built:** 13 road pieces, each 2 x 2 tiles (4 x 4 units): 4 corners, 4 T-junctions, a crossroads, 4 dead ends. `build_ground_tiles.py` appends their 52 tiles to the ground atlas (indexes 87 to 138, so every older tile and the game's own ground are unchanged) and draws `art/ground/road_pieces.png` (each piece as a 256 x 128 diamond, the panel icon and the preview). Each tile is the plain asphalt plus the straight tiles' own centre-line pixels on the tile edges of the open sides, so on every open side the two tiles next to the road carry exactly `line_r` and `line_l`'s line (same dash phase, along y and along x), and the lines meet at the piece's centre. The straights have no edge lines, so none are drawn.
- **Dead ends** end in a white kerb line across the full road (0.75 to 1 unit from the closed side) with gravel beyond it; they read clearly in the screenshot.
- **Catalogue:** one entry per piece and rotation (`road-piece_<name>`, footprint 4 x 4, `parts` = four tile entries marked `"part": true`, hidden from the panel by `LevelDocument.panel_entries`), listed first under Roads, with T-250's labels over each button. One click places all four tiles; `LevelSnapping.placement` moves the piece in so all four are on the map and the outline is 4 x 4. Delete removes one tile at a time (a proposal to revisit if the board wants whole-piece delete).
- **The one-tile pieces were dropped** (my call): they did not join the two-tile roads and would only clutter the panel.
- **x and y versions:** all older x and y ground tiles were already separate catalogue entries and shown in the panel; nothing needed changing. Rotation is by choosing the rotation's own button (Rotate is greyed out for roads, as before).
- **Builder:** the only change in `build_creator_assets.py` is in `ground_entries` (a stable sort putting the pieces first); T-251's changes in `elevation_entries` should merge cleanly, and a rebuild regenerates the catalogue.
- **Tests:** `RoadPieceTests` in `tools/test_build_ground_tiles.py` (old tiles and cells unchanged by hash; every rotation; open-side tiles carry exactly the straight tiles' line pixels over plain asphalt; lines reach only open edges; dead-end kerb and gravel; sprite rules and tiling for all 52 tiles; the sheet matches), `tools/test_build_creator_assets.py`, `tests/unit/level_creator/test_road_pieces.gd` (placing all four tiles, atlas indexes, ground rows, edge clamp, panel labels and hidden parts, the game's ground unchanged). The existing panel test now uses `panel_entries`. Full GUT suite and both Python sets pass (see the final run in the report).
- **Screenshot:** `art-archive/T-252/screenshots/street_grid.png` (fixture `tests/fixtures/level_creator_roads_demo.tscn`): a street grid of today's two-tile straights plus every piece (a ring with four corners and four T-junctions around a crossroads), and two short roads closed with dead ends in all four rotations. Seen: the lines run straight across every join and the dead-end kerbs show clearly.
- **Process notes:** one command (`sha256sum` on a file) and one scratchpad script run were refused by the status guard and skipped; I did not work around them. One early edit of the builder used an inline Python heredoc by mistake.
- 2026-10-27, needs-playtest → done: The board's playtest of the creator build (playtest/creator-set, 2026-10-28): every check ticked on the playtest page, everything works fine.
