---
id: T-252
title: "Level creator: road corners, T-junctions, crossroads and dead ends"
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/tools/build_ground_tiles.py, game/art/ground/ground_atlas.json, game/tools/build_creator_assets.py, game/data/level/creator_assets.json]
files_expected_to_change: [game/tools/, game/art/ground/, game/data/level/creator_assets.json, game/scripts/level/, game/scripts/level_creator/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-252/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). The creator has straight road tiles (plain, lane lines, zebra crossings, in both directions) but no way to turn or join roads. Add, drawn by script from the existing road tiles (`build_ground_tiles.py`; no PixelLab), the road pieces a street network needs, in every rotation: **corners** (4), **T-junctions** (4), a **crossroads**, and **dead ends** (4), at the same 2 x 2 unit tile size and in the ground atlas's style (asphalt, white lines, light cracks; Visual style, Decisions, "Ground"). Add them to the catalogue (rebuild `creator_assets.json`) under Roads, with their names from T-250, and make the existing ground tiles' x and y versions both show. The game's own map is unchanged.

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. End with a screenshot of a small street grid built in the creator using every new piece.

## Acceptance criteria

- [ ] The atlas and catalogue have corners, T-junctions and dead ends in 4 rotations and a crossroads; their lines join the straight tiles' lines without gaps (tests on the tile data, and the screenshot) (QA: pass / fail)
- [ ] The tiles pass `check_sprite_rules.py`; the game's own map's ground is unchanged (a test) (QA: pass / fail)
- [ ] The screenshot is in `art-archive/T-252/screenshots/`; `game/README.md` describes the pieces; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: lay out a street grid with corners and junctions.
Board review files: the screenshot in `art-archive/T-252/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started: road corners, T-junctions, crossroads and dead ends, drawn by script.

## Result notes

Level/Challenge agent, done (no PixelLab call, no cost).

- **Built:** 15 tiles appended to the ground atlas by `build_ground_tiles.py` (indexes 87 to 101, so every older tile and the game's own ground are unchanged): 4 corners, 4 T-junctions, a crossroads, 4 dead ends, and the 2 one-tile-wide straights that join them. Drawn from the approved road tile and the plain asphalt, no new colours. The creator catalogue (`creator_assets.json`, rebuilt) lists them first under Roads, one entry per rotation (`road-piece_*`); the panel shows T-250's labels (`road_corner`, `road_t_junction`, `road_crossroads`, `road_dead_end`) over each button.
- **Design choice to check (a proposal):** the pieces are one-tile-wide roads (2 units) with the approved dashed line in the middle, because the older tiles' centre line sits on a tile edge (two tiles make a road) and cannot meet a corner or T in one tile. Each arm's line is exactly a half of the straight tile's line, so lines join with the dash phase kept. A dead end's closed side is gravel (gravel0's pixels) from 1.5 units on. The older wide-road tiles do not join these.
- **x and y versions:** all older x and y ground tiles were already separate catalogue entries and shown in the panel; nothing needed changing. Rotation is by choosing the rotation's own button (Rotate is greyed out for roads, as before).
- **Builder:** the only change in `build_creator_assets.py` is in `ground_entries` (a stable sort putting the pieces first); T-251's changes in `elevation_entries` should merge cleanly, and a rebuild regenerates the catalogue.
- **Tests:** `RoadPieceTests` in `tools/test_build_ground_tiles.py` (old tiles and cells unchanged by hash, every rotation present, arm lines equal the straights' halves, lines reach exactly the open edges, dead-end gravel, `check_sprite_rules.check_rows` on each piece, tiling), `tools/test_build_creator_assets.py`, `tests/unit/level_creator/test_road_pieces.gd`. Full GUT suite passed (1379 tests, before the final test-file tidy; the new GUT file re-run below), both Python sets run.
- **Screenshot:** `art-archive/T-252/screenshots/street_grid.png` (fixture `tests/fixtures/level_creator_roads_demo.tscn`): a 5 x 5 street grid with every piece, plus two short dead-end roads. Seen: the lines join at the tile edges, the ring with the crossroads reads as a street network; the dead ends are subtle against the gravel ground.
- **Process notes:** one command (`sha256sum` on a file) and one scratchpad script run were refused by the status guard and skipped; I did not work around them. One early edit of the builder used an inline Python heredoc by mistake.
