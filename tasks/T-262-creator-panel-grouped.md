---
id: T-262
title: "Level creator: one button per kind of piece, in six groups, with looks chosen by keys"
status: in-progress
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
files_to_read_first: [tasks/README.md, docs/level-design.md, game/README.md, game/scripts/level_creator/, game/tools/build_creator_assets.py, game/data/level/creator_assets.json, game/data/level/props.json, game/data/level/creator_buildings.json]
files_expected_to_change: [game/scripts/level_creator/, game/scenes/level_creator/, game/tools/build_creator_assets.py, game/data/level/, game/tests/, game/README.md, docs/level-design.md, art-archive/T-262/screenshots/]
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

The board's decision (Level design, Decisions, "Level creator rework", 2026-10-22; the plan it read: https://claude.ai/artifact/2TXG35AkZFYXKvfNUUPfNN). Today the side panel has about 126 buttons, one per rotation, mirror and variant (98 of them roads), and lookalikes sit in different places. Rework it to one button per kind of thing, in six groups from the ground up, with T-261's names:

- **Roads:** Road, Centre line, Zebra crossing, Cracked road (the brush itself is T-263; until then each opens today's tiles for that kind).
- **Ground:** Gravel (its looks), Pavement (if the existing pavement art can be a ground tile; if not, leave it out and say so).
- **Levels:** Platform (heights with H, style with T), Ramp (its height steps, direction with R).
- **Buildings**, smallest to tallest: Small building, Long building, Low-rise (today's short buildings), Skyscraper.
- **Obstacles:** Boulder, Barrier, Cones, Crates.
- **Decoration:** Street lamp, AC unit, Water tank, Roof vent, Rooftop sign.

A piece's variants are keys, not buttons: **V** next look, **R** turn, **M** mirror, **H** height (3 / 6), with T (style) as today. The selected piece shows a **looks strip** under it: small pictures of its looks, clickable, with the counter from T-261. The catalogue builder writes families (one entry per kind, listing its looks, turns, mirrors and heights) so new art adds looks, not buttons. Saved levels and the run are unchanged: a placed piece still writes the same data as today, so earlier levels load and play as before. Every label from `creator_texts.json`; the controls hint is T-261's new line.

Built on the level creator's build: the Project Lead makes your folder from `playtest/creator-set`. T-263 (road brush), T-264 (ramps and platforms) and T-265 (banners) are built on your branch afterwards, so keep the family data and the key handling in one place each. End with screenshots of the whole panel and of the looks strip for a skyscraper and a boulder.

## Acceptance criteria

- [ ] The panel shows the six groups with one button per kind (about 25 in all), labels from `creator_texts.json`; V, R, M and H step through a piece's looks, turns, mirror and heights, and the looks strip shows and picks them (tests and screenshots) (QA: pass / fail)
- [ ] Every look, turn and mirror the old panel offered can still be placed (a test walks the old catalogue and finds each in a family) (QA: pass / fail)
- [ ] Levels saved before this ticket open, place and play as before, and new saves pass `check_level.py` (tests) (QA: pass / fail)
- [ ] Screenshots are in `art-archive/T-262/screenshots/`; `game/README.md` "Level creator" describes the panel; the full GUT suite and all Python tool tests pass (QA: pass / fail)

The board's review: browse the panel and place a few pieces with their looks.
Board review files: the screenshots in `art-archive/T-262/screenshots/`.

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-22, Blocked → In progress

Started: one button per kind of piece in six groups, looks on keys.

## Result notes

Level/Challenge Design Agent, 2026-10-23.

**Built.** The side panel has 20 buttons, one for each kind of piece, in six groups (Roads, Ground, Levels, Buildings, Obstacles, Decoration). Each button shows its first look's art and its T-261 name. V, R, M and H step a piece's look, turn, mirror and height, and T sets the style as before. The Rotate and Mirror buttons step the same way, and they are greyed out when there is nothing to step to. Under the picked piece's group, a looks strip shows the heading "Looks", one clickable picture for each look, and "Look n of count". The hint is `controls_hint_rework`; its font shrinks (down to 10 px) when the line is wider than the map view. Every label comes from `creator_texts.json`.

**Proposals for the playtest:**
- **Road:** the plainer asphalts a0 (with a0m as its mirror), g6 and g9.
- **Cracked road:** the visibly cracked g4, g5 and g7, plain tiles only.
- **Centre line:** the right and left half tiles on every asphalt, then T-252's corner, T-junction, crossroads and dead end (R turns them) and the first approved road tile. 17 looks.
- **Zebra crossing:** the three zebra tiles on every asphalt. 18 looks.
- **Road tiles:** R switches to the tile along the other axis.
- **Skyscraper:** 12 looks, the 6 towers times their 2 bodies. The second body was in the art but the old panel never offered it. It is written as `look: 1`, which the run already draws.

**Pavement is left out:** the only pavement art is the 960 x 486 block pavement under buildings, not a 2 x 2 ground tile.

**For T-263, T-264 and T-265:**
- **Family data:** written in one place, `game/tools/build_creator_assets.py` (`family_entries` with `GROUPS`, `FAMILY_ORDER`, `SIMPLE_FAMILIES`, `HEIGHT_FAMILIES` and the road lists). It goes into `creator_assets.json` under `groups` and `families`.
- **Stepping:** one place, `game/scripts/level_creator/creator_families.gd`.
- **Key handling:** one place, `editor.gd` `KEY_ACTIONS` → `step_pick` → `apply_member`. The keys A and B belong there.
- **Panel:** `asset_panel.gd` holds `picked_family`, `member` and `show_member`. `pick()` takes a family id or an asset id.

**Saved data is unchanged:** a member places through `LevelDocument.place` as before. The only addition is an optional `variant`, used only for a skyscraper's second body.

**Also changed:** rebuilding the catalogue brought in T-256's prop art paths, which the committed catalogue had missed. The panel icons are now the final prop art.

**Tests:**
- New file `game/tests/unit/level_creator/test_creator_families.gd`:
  - the groups and labels
  - the strip and its position
  - V, R, M and H through key events
  - clicking a look
  - a skyscraper's second body
  - every old pose found in a family and placing the same data as the old way
  - the board's own pre-T-262 level (copied unchanged as `game/tests/fixtures/t262_level_saved_before.json`, from creator-set's `data/levels/level_01.json`): it opens, takes new pieces, keeps its own, gives the same `check_level.py` report as before, and plays. That report has 4 problems, all ramps not on a rooftop, which were there before this ticket.
  - a new level with every kind passes `check_level.py`
  - the hint fits
- Updated the old panel tests in `test_editor_place_delete.gd`, `test_creator_props.gd`, `test_road_pieces.gd`, `test_editor_rotate_heights.gd` and `test_creator_pieces_any_size.gd`.
- Added `FamilyTest` to `game/tools/test_build_creator_assets.py`.

**Results:**
- Full GUT suite: 1382 of 1382 passed.
- `python -m unittest discover -s game/tools`: 478 OK.
- `python -m unittest discover -s tools`: 451 OK.

**Screenshots** in `art-archive/T-262/screenshots/` (fixtures `game/tests/fixtures/level_creator_panel_*.tscn`):
- `panel.png`: the panel top, nothing picked
- `panel_end.png`: the panel bottom
- `panel_skyscraper.png`: the Skyscraper strip, look 5 of 12
- `panel_boulder.png`: the Boulder strip, mirrored, look 2 of 2

At the 1152 x 648 screenshot size, the top bar wraps onto an empty second line. That was already the case (T-251's flow bar).

**Documents updated:**
- `game/README.md`, "Level creator", "The side panel: one button per kind of piece (T-262)"
- `docs/level-design.md`, Content, "Level creator: one button per kind of piece"
