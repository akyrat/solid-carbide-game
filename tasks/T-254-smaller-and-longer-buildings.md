---
id: T-254
title: "Level creator: smaller and longer buildings"
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
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, game/README.md, game/scripts/level/map_building.gd, game/scripts/level/building_towers.gd, game/scripts/level_creator/, game/tools/build_creator_assets.py]
files_expected_to_change: [game/scripts/level/, game/scripts/level_creator/, game/tools/, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-254/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator piece set", 2026-10-22). Every building today is 12 x 12 units. Add two new footprints to the creator's Buildings: a **small square building** (6 x 6 units) and a **long building** (12 x 6 units, and 6 x 12 by rotating, R), both short buildings whose roofs show, at a height you propose (today's short buildings are 4.3). They are solid like today's buildings, see-through when the car is behind them (as today), and enemies path round them. Placeholder look first: a code-drawn box in the city's palette (cool blue-grey walls, pale lit windows; Visual style, Decisions, "City colours"), never Redgull red; T-257 generates the final art and swaps it in, so keep each footprint's textures per rotation and mirror in one data file. Names from T-250. The game's own map is unchanged.

Built on the level creator's build: the Project Lead makes your folder from `playtest/G-005`, not `master`. End with a screenshot of both new buildings (both rotations of the long one) beside today's buildings in the creator.

## Acceptance criteria

- [ ] Tests show the small and long buildings (both rotations) can be placed, saved, reopened and pass `check_level.py`, collide with the car and are pathed round by enemies (QA: pass / fail)
- [ ] Their art per rotation lives in one data file; labels from `creator_texts.json`; no Redgull red; the game's own map unchanged (QA: pass / fail)
- [ ] The screenshot is in `art-archive/T-254/screenshots/`; `game/README.md` describes them; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: place the new buildings and drive round them.
Board review files: the screenshot in `art-archive/T-254/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started: a small square building and a long building for the creator, placeholder look first.

## Result notes

Written by the agent when it finishes.

Built (Level/Challenge agent, 2026-10-22):
- **Pieces:** `building-small` (6 x 6) and `building-long` (12 x 6, views `ew`; 6 x 12, view `ns`, by Rotate), each with a mirror (second window pattern, written as the building's `look`). Labels `building_small` / `building_long` from `creator_texts.json` on their panel buttons.
- **One data file** for the art per rotation and mirror: `game/data/level/creator_buildings.json` (texture, `footprint_units` of that view, `anchor_art_px`). The catalogue builder (`build_creator_assets.py`, one small function `piece_building_entries`) copies it in; T-257 swaps paths and anchors there. Placeholder PNGs in `game/art/buildings/creator/`, drawn by `game/tools/build_creator_buildings.py` (palette B, pale lit windows, no Redgull red; `--check` verifies).
- **Code:** `LevelDocument.footprint_of` (a texture's own footprint wins), used by `place`, `LevelSnapping.placement` and the editor preview; `BuildingTowers.piece_of` / `_setup_piece` draw a map entry whose asset is one of them (a MapBuilding fade node with a box outline). Walls and pathfinding read the entry's `w`/`h`, unchanged. The game's own map is unchanged.
- **Proposal for the board:** height **4.3 units** for both (same as today's short buildings).
- **Tests:** `tests/unit/level_creator/test_small_long_buildings.gd` (8: catalogue, data file, labels, place/save/reopen/`check_level.py`, mirror look, car wall per footprint, fade, enemy path round), `tools/test_build_creator_buildings.py`, updated `test_build_creator_assets.py`. Full GUT suite: 1381/1381 passed. Python: game/tools 422 tests OK (1 skipped), tools 439 tests OK.
- **Screenshot:** `art-archive/T-254/screenshots/new_buildings.png` (skyscraper, short building, small, long, long rotated; fixture `tests/fixtures/level_creator_buildings_demo.tscn`). Looked at it: boxes read as buildings, both long rotations right, sit on their footprints.
- **Documents:** `game/README.md` (Level creator section), `docs/level-design.md` (Decisions).
- No refusals.
