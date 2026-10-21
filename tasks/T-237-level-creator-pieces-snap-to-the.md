---
id: T-237
title: Level creator: pieces snap to the tile grid and to close neighbours
status: in-progress
from: project-lead
to: level-challenge
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-236]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/scripts/level_creator/editor.gd, game/scripts/level_creator/level_document.gd, game/scripts/enemies/enemy_navigation.gd, game/tools/check_level.py, game/tools/check_height_data.py]
files_expected_to_change: [game/scripts/level_creator/snapping.gd, game/scripts/level_creator/editor.gd, game/tests/unit/level_creator/test_snapping.gd, game/README.md]
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

Pieces snap to the map's tile grid and to close neighbours so they align with little effort (Level design, Decisions, 'Level creator', board 2026-10-21). Every placed piece snaps to the map's tile grid so its edges lie on even units (enemy_navigation.gd's CELL = 2; the level validator checks the same). A piece placed within a snap distance of a neighbour lines its edge up with that neighbour's edge, for example a ramp's top end onto a rooftop's side, a rooftop at 6 onto its 3's edges, a building against a road. The docs give no snap distance: propose one, write it in game/README.md, 'Level creator', and in the result notes as a proposal for the board. Pieces that would overlap in a way the validator refuses are either not placed or placed and flagged (choose one, say which in the result notes); when refused or flagged, the editor shows the overlap message from creator_texts.json. Screenshot in art-archive/<this task's id>/screenshots/ of a ramp snapped onto a rooftop's side.

The board's review: In the level creator, place pieces next to each other and check they snap into line, a ramp onto a rooftop for example.

## Acceptance criteria

- [ ] A unit test places pieces from off-grid cursor positions: every placed piece's edges lie on even units. (QA: pass / fail)
- [ ] Unit tests: a piece placed within the documented snap distance of a neighbour lines its edge up with the neighbour's edge, including a ramp's top end onto a rooftop's side; a piece placed farther away does not move to the neighbour. (QA: pass / fail)
- [ ] A unit test: a piece that would overlap in a way check_level.py refuses is not placed or is flagged (as the result notes say), and the overlap message from creator_texts.json is shown. (QA: pass / fail)
- [ ] game/README.md, 'Level creator', gives the snap distance; the result notes give it as a proposal for the board. (QA: pass / fail)
- [ ] The test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass / fail)
- [ ] A screenshot of a ramp snapped onto a rooftop's side is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass / fail)
- [ ] The full GUT suite passes. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Goal runner (G-005): started, in C:\solid-carbide-worktrees\T-237.

## Result notes

Done by the Level/Challenge Design Agent, 2026-10-22. No PixelLab calls (0 generations). No refusals.

**What was built**
- `game/scripts/level_creator/snapping.gd` (`LevelSnapping`): `placement(doc, asset_id, cursor, view, mirror)` gives where a piece goes, in three steps:
  1. **Tile grid:** the top-left corner goes on the corner of the 2 x 2 unit cell under the cursor (CELL = 2), so every building, rooftop and ramp edge lies on even units.
  2. **Close neighbours:** a building, rooftop or ramp moves when an edge is within the snap distance of a placed building's, rooftop's or ramp's edge, or for a building a road tile's, and the two are side by side. It ends up flush against the neighbour (a building against a road or a building) or lined up with it (a 6 along its 3's edges). Each axis moves to its closest edge.
  3. **Ramps:** a ramp whose top end is within the snap distance of the side it climbs, on a rooftop at its top height, goes onto that side and slides along it to lie within it. This beats step 2.
  A move that would leave the map is not made. Ground and road tiles and boulders only snap to the grid.
- `editor.gd`: `place_asset` places at the snapped corner. The preview and blue outline show the snapped place before the click (`placement_at`). A new `MessageLabel` on the top bar shows the overlap message.
- `level_document.gd`: only its header comment changed. Placement logic is untouched; the editor passes a point in the snapped cell.
- `game/README.md`, "Level creator": new "Snapping (T-237)" bullet.

**Proposal for the board: snap distance `SNAP_DISTANCE` = 4 units (two cells).** A near miss of one or two tiles lines up, and a gap of three tiles or more stays where it was clicked. It is written in game/README.md, "Level creator".

**Overlaps: chosen "not placed" (not "placed and flagged").** The overlap text in creator_texts.json already says "Can't place here". A rooftop or ramp that would overlap in a way `check_height_data.py` (run by `check_level.py`) refuses is not placed, and the top bar shows `overlap_message` until the next successful placement. Refused cases: two rooftops overlapping without one standing on the other; a ramp over a rooftop other than the one holding its whole foot. Buildings, boulders and tiles are never refused, because the level check doesn't check their overlaps.

**Tests** (`game/tests/unit/level_creator/test_snapping.gd`, 16 tests):
- Off-grid cursors: every building, rooftop and ramp edge is even, and check_level.py reports no odd unit.
- Snapping: ramp onto a rooftop's side, including sliding off a corner; ramp 3 to 6 onto a 6, with the whole layout passing check_level.py; a 6 onto its 3's edges; building against a road; building against a building. Pieces farther away don't move.
- The preview shows the snapped place.
- Refused overlaps: rooftop/rooftop, ramp half on a rooftop, rooftop over a ramp. Each is not placed and shows the message. check_level.py refuses the same rooftop layout. A 6 wholly on a 3 is still placed.
- The README gives the snap distance.

All 55 level-creator tests pass, including `test_creator_texts_only.gd`. **Full GUT suite: 1366/1366 passed.**

**Screenshots** (`art-archive/T-237/screenshots/`, from `game/tests/fixtures/level_creator_snapping_demo*.tscn`):
- `ramp_snapped.png`: a ramp 0 to 3 clicked 2 units short of a rooftop-3's south side and 2 units past its east end. It is placed snapped onto the side, within it (selected, yellow).
- `ramp_preview_snapped.png`: the same click before placing. The preview shows the snapped place.
- `overlap_refused.png`: a second rooftop across the first is refused, and the top bar shows the overlap message.

**Documents affected:** none of the game area docs. game/README.md was updated.
