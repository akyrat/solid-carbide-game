---
id: T-034
title: Buildings turn see-through when the car is behind them
status: in-qa
from: project-lead
to: level-challenge
epic: level-challenges
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-019, T-020]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/visual-style.md, docs/extended-narrative.md, docs/level-design.md, tasks/T-020-see-through-buildings-research.md, tasks/T-019-build-mvp-map.md, game/README.md]
files_expected_to_change: [the map's building code or scene, their tests, docs/level-design.md, game/README.md]
model: sonnet
qa_rounds: 0
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

- [ ] A test places the car behind a building (covered by it on screen) and shows that building becomes see-through, while a building not covering the car stays fully opaque (QA: pass / fail)
- [ ] A test moves the car out from behind the building and shows it becomes fully opaque again (QA: pass / fail)
- [ ] Two screenshots, the car behind a building and the car in the open, show the fade (QA: pass / fail)
- [ ] The fade changes only the building's whole-object transparency: no sprite file was changed (QA: pass / fail)
- [ ] `docs/level-design.md` describes the see-through behaviour in Content without changing Summary, Decisions or Open questions, and `game/README.md` says how it works for whoever adds the final building art (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

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

Board review files: [docs/level-design/see-through-behind.png, docs/level-design/see-through-open.png, game/scenes/run/run.tscn]
