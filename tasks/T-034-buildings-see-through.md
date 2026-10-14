---
id: T-034
title: Buildings turn see-through when the car is behind them
status: done
from: project-lead
to: level-challenge
lead:
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019, T-020]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-020-see-through-buildings-research.md, tasks/T-019-build-mvp-map.md, game/README.md]
files_expected_to_change: [the map's building code or scene, their tests, docs/level-design.md, game/README.md]
model: sonnet
qa_rounds: 1
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

**Blocked until T-019 (the MVP map) and T-020 (the research on how to do this) are done.**

In the isometric view, a tall building can hide the car. Visual style, Decisions says a building the car drives behind turns see-through. The game fades the whole object, so no sprite needs semi-transparent pixels.

Build it on the MVP map, following the approach T-020 recommends and the values the board chose (Visual style, Decisions: fade to 15% visible over 0.15 seconds, car only):
- When the car is behind a building (hidden by it on screen), that building fades.
- When the car comes out, the building fades back.
- Only the buildings actually covering the car fade, not the whole city.

The buildings are still T-019's flat placeholders. The final building art comes from a separate art task and must work with the same fade.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [x] A test places the car behind a building (covered by it on screen) and shows that building becomes see-through, while a building not covering the car stays fully opaque (QA: pass)
- [x] A test moves the car out from behind the building and shows it becomes fully opaque again (QA: pass)
- [x] Two screenshots, the car behind a building and the car in the open, show the fade (QA: pass)
- [x] The fade changes only the building's whole-object transparency: no sprite file was changed (QA: pass)
- [x] `docs/level-design.md` describes the see-through behaviour in Content without changing Summary, Decisions or Open questions, and `game/README.md` says how it works for whoever adds the final building art (QA: pass)
- [x] The full GUT suite and all Python tool tests pass (QA: pass)

The board's review: drive behind buildings and judge whether the fade reads well.

## Result notes

Built by the Level/Challenge Design Agent, following T-020's approach A (whole-building fade) with the board's values.

- **What changed on the map:** each building is now its own node (`game/scripts/level/map_building.gd`) under the map's `Buildings` node. In the isometric view it is a placeholder box that rises 15 units (`BUILDING_HEIGHT_UNITS` in `mvp_map.gd`); before this the iso buildings were flat on the ground and could never hide the car. **The 15-unit height is my placeholder, not a board decision**: one constant, to be replaced by the building art's own height (T-064). The flat view is unchanged.
- **Draw order:** buildings get a `z_index` from their front corner; the car's drawing goes just under the buildings covering it and over the rest (`map.car_z_index()`, applied to the run's `View` in `run.gd`'s `sync_view()`, a two-line change in the Game Loop's file). Ground, drift marks, arrows and boulders stay at z 0 under every building, so the drift marks' order (ground, marks, buildings, car) still holds; a test checks it.
- **The fade:** a building fades only while it covers the car: the car is behind it (not in front of either visible wall) and the drawn car (1 x 3 units, plus 1 unit of height) overlaps its on-screen outline. It changes only the node's `modulate.a`: to 0.15 over 0.15 s, and back to 1 over 0.15 s (`SEE_THROUGH_ALPHA`, `SEE_THROUGH_FADE_TIME` in `mvp_map.gd`, from Visual style, Decisions). Car only. No sprite file was changed.
- **Deviation from T-020's rule:** T-020 used one depth number (x + y) for "behind". On the 30-unit blocks that is wrong (a car just in front of a long wall has a smaller x + y than the block's front corner and would fade it), so "behind" is now "not in front of either visible wall"; the screen-overlap test is as in T-020.
- **For the art (T-064):** `game/README.md`, "MVP map", "See-through buildings": add the sprite under the building node, set `draw_placeholder` false, set `height_units` or `custom_silhouette`.
- **Tests:** `game/tests/unit/test_see_through_map.gd` (15 tests): the covering building fades to 15% while a building not covering the car stays fully opaque; moved out (into the open, or in front) it is fully opaque again; the 0.15 s timing both ways; only `modulate.a` changes; draw order; flat view; art under a building fading with it; a run started from the main menu. Full GUT suite: 398/398 passed (TESTS PASSED). Python tool tests: `game/tools` 141 OK, `tools` 115 OK.
- **Screenshots** (a run started from the main menu, fixtures `game/tests/fixtures/see_through_map_behind.tscn` and `see_through_map_open.tscn`): `docs/level-design/see-through-behind.png` (car on the road behind the block south of the gravel centre, the block at 15%, the car under it) and `docs/level-design/see-through-open.png` (car on the road in front of the same block, block opaque). `docs/level-design/mvp-map-iso.png` was retaken, since the iso buildings now rise.
- **For the board to judge in the playtest:** the placeholder height (15 units); and under a faded building the dark night colour shows, because the ground art (T-103) has no tiles on the blocks.
- **Documents affected:** `docs/level-design.md` (Content only: a new "See-through buildings" subsection, a sentence in "MVP map" and the retaken iso picture; Summary, Decisions and Open questions unchanged), `game/README.md` ("MVP map": the building node and a "See-through buildings" part). Also my working copy `agent-notes/level-challenge.md`. The long GDD is stale for Level design; regenerate it when merging.
- Godot's line-ending-only `.import` changes were reverted, not committed. No PixelLab call.

## QA round 1 (QA/Integration Agent, 2026-10-13)

All six criteria pass. Checked in C:\solid-carbide-worktrees\T-034 against the branch point (`git diff master...HEAD`).

1. **Pass.** `test_building_covering_the_car_fades_and_one_not_covering_stays_opaque` puts the car on the road behind the block (12, 66, 30, 30), where the block covers it on screen. After 0.3 s that block is `covering` at alpha 0.15, the far block and every other building stay at 1.0, and `covering_buildings()` is just that block. The same check runs in a run started from the main menu.
2. **Pass.** `test_building_becomes_fully_opaque_again_when_the_car_comes_out`: after the car moves to the open, and again after it moves in front of the block, the block is back at alpha 1.0. The 0.15 s timing is tested both ways.
3. **Pass.** In `docs/level-design/see-through-behind.png` the block over the car is see-through: the car, the road and the block's outline show through it. In `see-through-open.png` the same block is solid purple with the car in front of it. Under the faded block the untiled ground shows as near-black, as the result notes say.
4. **Pass.** The fade only changes the building node's `modulate.a`: no tint, no shader, the colours stay opaque (`test_fade_changes_only_the_whole_buildings_alpha`), and art under the node fades with it. The diff since the branch point changes no file under `game/art/` and no sprite or `.import` file. The only PNGs are the three pictures in `docs/level-design/`.
5. **Pass.** `docs/level-design.md`: Summary, Decisions, Open questions and References are byte-identical to master's (checked with a script). Only Content changed: the new "See-through buildings" subsection and one sentence in "MVP map". `game/README.md`, "MVP map", "See-through buildings", tells whoever adds the final building art (T-064) how to keep the fade: put a child sprite under the building node, set `draw_placeholder` false, and set `height_units` or `custom_silhouette`.
6. **Pass.** I ran both myself. Full GUT suite: 398/398, TESTS PASSED (`test_see_through_map.gd` 15/15). Python: `game/tools` ran 141 tests OK, `tools` ran 115 tests OK.

Also checked, as asked:
- **Drift marks:** `DriftMarks` sits in `map.view_root` right after the ground tiles at z 0, and every building is at z 2 or higher. The car's `View` is at z 1 or higher, so the order is still ground, marks, buildings, car. A test checks this.
- **The car's draw order:** `car_z_index()` puts the car just under the lowest building that covers it, and over every building otherwise. So the car is drawn over a block it is in front of (tested with IN_FRONT, and in the run).
- **Merging:** the branch merges into the current master without conflicts (`git merge-tree`).
- **Import noise:** Godot's line-ending-only `.import` changes are left uncommitted.

For the board (not fails):
- The 15-unit placeholder height for the buildings is the agent's own choice, not a board decision.
- Under a faded block the dark night colour shows, because the ground art has no tiles there.
- Enemies aren't drawn in the run yet. When they are, they will be at z 0 under every building unless they join the depth order. The fade is car-only by decision.

Board review files: [docs/level-design/see-through-behind.png, docs/level-design/see-through-open.png, game/scenes/run/run.tscn]
- 2026-10-13, in-qa → needs-playtest: QA round 1: all six criteria pass
- 2026-10-13, needs-playtest → done: board playtest: see-through buildings work amazing
