---
id: T-236
title: Level creator: rotate between the art's views, mirror, and rooftops and ramps at heights 3 and 6
status: needs-playtest
from: project-lead
to: level-challenge
lead: Goal-G-005
epic: level-challenges
milestone: mvp
goal: G-005
user_facing_text: yes
changes_visuals: yes
depends_on: [T-233, T-235]
documents_affected: []
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/data/level/creator_texts.json, game/data/level/creator_assets.json, game/scripts/level_creator/editor.gd, game/scripts/level/elevation_layer.gd, game/tools/check_height_data.py, game/data/level/elevation_sample_map.json]
files_expected_to_change: [game/scripts/level_creator/editor.gd, game/scripts/level_creator/asset_panel.gd, game/scripts/level_creator/level_document.gd, game/tests/unit/level_creator/test_editor_rotate_heights.gd, game/README.md]
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

Rotating in the creator means switching between the views the art exists in and mirroring them, since the art has only the angles that were generated (Level design, Decisions, 'Level creator', board 2026-10-21). Before placing, the selected asset steps through the views and mirrors its catalogue entry lists (creator_assets.json), and only those; the preview under the cursor shows the current one. Rooftops can be placed at height 3 or 6; a 6 stands on a 3 and is written with the 'on' field, as in the elevation sample map's height data. Ramps are placed 0 to 3 or 3 to 6, with the side they climb. The level data written must pass check_height_data.py. The rotate, mirror and height labels come from creator_texts.json. Add the rotate, mirror and height controls to game/README.md, 'Level creator'. Screenshot of rooftops at 3 and 6 with their ramps in the editor in art-archive/<this task's id>/screenshots/.

The board's review: In the level creator, rotate and mirror pieces before placing them, and build a rooftop at 3 and a 6 on it with their ramps.

## Acceptance criteria

- [ ] A unit test per asset kind: stepping rotate and mirror on the selected asset offers exactly the views and mirrors its catalogue entry lists, and no others. (QA: pass: six per-kind tests, all pass)
- [ ] A unit test places a rooftop at 3, a rooftop at 6 on it (its 'on' field naming the 3), a ramp 0 to 3 and a ramp 3 to 6 with the side they climb; the level data written to a temporary file passes python game/tools/check_height_data.py. (QA: pass: test runs the checker on the temp file, passes)
- [ ] The rotate, mirror and height labels come from creator_texts.json, and the test that scans the creator's scripts for hard-coded label strings still passes. (QA: pass: label test and test_creator_texts_only pass in full suite)
- [ ] game/README.md, 'Level creator', lists the rotate, mirror and height controls. (QA: pass: README line 1350)
- [ ] A screenshot of rooftops at 3 and 6 with their ramps in the editor is in art-archive/<this task's id>/screenshots/ and listed in the result notes. (QA: pass: three heights*.png in diff, listed in notes)
- [ ] The full GUT suite passes. (QA: pass: all tests passed)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-21, Blocked → In progress

Goal runner (G-005): started, in C:\solid-carbide-worktrees\T-236.

### 2026-10-21, In progress → In QA

Goal runner (G-005): the agent is done; QA is checking it.

### 2026-10-21, In QA → Needs playtest

Goal runner (G-005): QA passed; merged into playtest/G-005.

## Result notes

Level/Challenge Design Agent, 2026-10-21. An earlier session left this work uncommitted in the folder and was cut off. I checked it, tested it and committed it, then added the README section, the screenshots and these notes.

**What was built**
- `game/scripts/level_creator/editor.gd`: added Rotate and Mirror buttons on the top bar, and the R and M keys. Rotate steps the picked asset through the `views` its catalogue entry lists (creator_assets.json) and Mirror through its `mirrors`, only those, wrapping round. Each button is greyed out when the asset has nothing to switch to. A height label on the top bar names the picked rooftop's or ramp's height. The preview under the mouse shows the art of the current view and mirror, see-through: `PREVIEW_ALPHA` 0.65, a proposal. Rooftop and ramp art is drawn exactly where it will stand once placed.
- `game/scripts/level_creator/level_document.gd`:
  - `views_of`, `mirrors_of`, `valid_view`, `valid_mirror` and `texture_of` read the asset's catalogue entry.
  - `place(id, units, view, mirror)` places the pose's art. A building writes its look (a short building's mirror is look 1). A boulder writes its variant (`a_mirror`). A rooftop or ramp writes `view` and `art`, and a ramp writes its `side` from the view's art: nw gives south / west, se gives north / east.
  - Heights: a 6 that stands wholly on a 3 gets `on` = the 3's id. A ramp's `platform` is the rooftop at its top height whose side its top end touches (check_height_data.py's rule). These links are filled in again after every place and delete.
- `game/scripts/level/elevation_layer.gd`, `elevation_platform_drawing.gd`, `ground_height.gd`: a placed piece is drawn with the art its view names (`art`), moved from where that art stands on the elevation sample map (`art_offset`, `shift_art`). Pieces without `art` (the game's own maps) are drawn as before.
- `game/scripts/level_creator/asset_panel.gd` did not need changes. Its `LABEL_KEYS` already map rooftops and ramps to their height texts.
- All labels come from `creator_texts.json`: `rotate_label`, `mirror_label`, `rooftop_height_3/6`, `ramp_height_0_3/3_6`. The hint line already listed R and M.
- `game/README.md`, "Level creator": new bullet "Rotate, mirror and heights (T-236)" with the controls; the tests and screenshots are listed.

**Tests** (`game/tests/unit/level_creator/test_editor_rotate_heights.gd`, 15 tests)
- One test per asset kind (ground, road, building, boulder, rooftop, ramp): rotate and mirror offer exactly the catalogue's views and mirrors, in order and round again, and the button states match.
- Mirrored art placed; rotated rooftop and ramp art and side; the preview follows the view.
- Rooftops at 3 and 6 (the 6's `on` names the 3) with ramps 0 to 3 (south) and 3 to 6 (west): the level data is saved to a temporary file and passes `check_height_data.py` (and `check_level.py`). The same for the se view (north / east).
- The links follow places and deletes; the labels come from the texts; the R and M keys work.

**Runs**
- Full GUT suite: 1350/1350 passed, including `test_creator_texts_only.gd`, the hard-coded label scan.
- `python -m unittest discover -s game/tools -p "test_*.py"`: 416 OK (1 skipped).

**Screenshots** (`game/tests/fixtures/level_creator_heights_demo.tscn`, `level_creator_heights_nw.tscn`, `level_creator_heights_se.tscn`; built through the editor's own place and rotate)
- `art-archive/T-236/screenshots/heights.png`: both sets, plus a picked rooftop 6 rotated to se, previewed on the street.
- `art-archive/T-236/screenshots/heights-nw.png`: nw view, a 3 with a 6 on it, a ramp 0 to 3 and a ramp 3 to 6.
- `art-archive/T-236/screenshots/heights-se.png`: the same in the se view.

**Notes for the playtest**
- Rooftop and ramp sizes are fixed by the catalogue footprints, so a ramp links only where its top end exactly touches the rooftop's side. Snapping is the next ticket (T-237). Until then, a ramp placed off by a tile stays unlinked (`platform` ""), and check_height_data.py will flag it.
- In the screenshots the preview draws over a rooftop's edge, because it is see-through and nothing stops it from overlapping. Overlap checks aren't part of this ticket.

**Other**
- PixelLab: 0 generations.
- Refusals: one `cd /c/...` inside a Bash command was refused (cd outside the allowed path form). It wasn't needed, and I ran the commands from the working folder instead.
- Godot's line-ending-only `.import` changes are left uncommitted.
- Documents affected: none (game/README.md only).
- 2026-10-21, in-qa → needs-playtest: QA passed every criterion (goal G-005).
