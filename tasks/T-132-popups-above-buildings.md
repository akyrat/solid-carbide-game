---
id: T-132
title: Trick popups are always drawn above the buildings
status: in-qa
from: project-lead
to: ui
epic: hud-menus
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/hud-and-menus.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/hud-and-menus.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/hud/trick_popups.gd, tasks/T-130-kaiju-alert-banners-art.md, tasks/T-125-popups-follow-the-car.md]
files_expected_to_change: [game/scripts/hud/trick_popups.gd, its tests, game/README.md, docs/hud-and-menus.md]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
model: sonnet or opus, the model the agent runs on for this task; set by the Project Lead (tasks/README.md, "Models").
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The trick popups (and the challenge popup that reuses them) are drawn at `z_index` 100 in the world view. Since T-064 the building slots reach z 146 (and T-130's pavement sign sits at 144), so a nearby skyscraper or short building can be drawn over a popup and hide it (found by QA in T-130, result notes). The board wants the popups always readable (board, 2026-10-14).

Make every popup draw above every building, sign, boulder and the car in the run, whatever the map's depth scheme gives them, without hard-coding a number that breaks the next time the map's top z grows (for example base it on `map.top_z_index()`, or use the top of Godot's z range, or another approach you justify in the result notes). Nothing else changes: the popups' look, size, stacking, following the car and the quarter-screen limit stay as in T-125. The drift prototype keeps working.

The board's review: drive along the skyscrapers in a run in this task's folder doing tricks, and check the popups never disappear behind a building.
Board review files: the screenshot listed in the result notes

## Acceptance criteria

- [x] In a run, a popup's effective z (its `z_index`, counting any `z_as_relative` parents) is above the highest z of anything in the map and of the car's drawing: a GUT test checks it against `map.top_z_index()` and the highest building slot, sign and boulder z in the MVP map. (QA: pass)
- [x] The rule does not depend on today's numbers: the test also raises the map's top z (or checks the code path that reads it) and finds the popup still above. (QA: pass)
- [x] A screenshot fixture (or an existing one with the car placed next to a skyscraper that covers the car's area) shows a popup drawn over the building; its path and command are in the result notes. (QA: pass)
- [x] The popups still draw under the HUD (CanvasLayer) and the pause and level-up screens. (QA: pass)
- [x] T-125's popup tests and the whole GUT suite pass, and the drift prototype's popups still show. (QA: pass)
- [x] `game/README.md` ("Trick popups") and `docs/hud-and-menus.md` (Content, "Trick popups") say how the popups stay above the buildings. (QA: pass)

## Result notes

- Change: in `game/scripts/hud/trick_popups.gd`, `show_popup` now sets `z_as_relative = false` and `z_index = POPUP_Z` (`RenderingServer.CANVAS_ITEM_Z_MAX`, 4096) instead of a relative 100. Cause: the popups are under `run.view_root`, whose z is the car's depth (under any covering building), so 100 + e.g. 109 could fall below slots at up to 146.
- Why this approach: an absolute z at the engine's maximum does not read any of the map's numbers, so it cannot break when `map.top_z_index()` grows (it would need 4000+ building slots). Basing it on `map.top_z_index()` would have tied the popups to the map and the absolute flag anyway. HUD and screens are CanvasLayers (10, 20) and still draw over the world.
- Tests: `game/tests/unit/test_popups_above_buildings.gd` (6 tests: above `top_z_index()`, every slot, sign, boulder and the car; car under a building; still above after raising every slot and the view by 2000; challenge popup; HUD/screen layers over the world and popups in the world canvas; drift prototype). Whole GUT suite: 529/529 pass (`bash game/tools/run_tests.sh`).
- Screenshot: `screenshots/T-132_popups_over_building.png` (not tracked by git; in this folder), command `bash game/tools/screenshot.sh res://tests/fixtures/popup_over_building_demo.tscn screenshots/T-132_popups_over_building.png 24` (fixture `game/tests/fixtures/popup_over_building_demo.gd`: car among the skyscrapers, drawn under them at z 109 of 146, popup over the building). Looked at it: the popup is drawn over the building. Only one popup shows because the second one's stack would exceed the quarter-screen limit and the oldest leaves (T-125 behaviour, unchanged).
- Documents updated: `game/README.md` ("Trick popups"), `docs/hud-and-menus.md` (Content, "Trick popups"). No `.import` noise committed.

## QA notes (round 1, QA/Integration Agent, 2026-10-14)

- Criterion 1: pass. `test_popups_above_buildings.gd` works out the effective z through `z_as_relative` parents and checks the popup (4096, absolute) over `map.top_z_index()` (146), every fade item, kaiju sign, boulder sprite and the car's drawing; a second test drops the view's z to 5 (car under a building) and it holds.
- Criterion 2: pass. The popup is absolute (`z_as_relative = false`, asserted) at `RenderingServer.CANVAS_ITEM_Z_MAX`; the test raises every slot and the view by 2000 and the popup is still above. The code reads no map numbers.
- Criterion 3: pass. Re-ran `bash game/tools/screenshot.sh res://tests/fixtures/popup_over_building_demo.tscn screenshots/T-132_qa.png 24` (prints car_z=109 top_z=146) and looked at it: "FULL 360! +0.25" is crisp white over the faded skyscraper covering the car. Control run (temporary fixture, deleted, not committed) with the popup forced to an absolute z of 100: the same popup comes out greyed under the building's see-through layer, so the screenshot really shows the popup over a building. Note: in this spot the old code would also have drawn the popup on top (relative 100 + view 109 = 209 > 146); the old bug only shows where the car's z is under about 47. The GUT test with the view at 5 covers that case.
- Criterion 4: pass. HUD (layer 10), pause screen (layer 20), level-up screen and tuning panel are CanvasLayers; z only orders items within one canvas, so the world's z 4096 cannot reach them. The test checks the popup is in the world canvas and every CanvasLayer in the game is above layer 0.
- Criterion 5: pass. Whole GUT suite 529/529 (`bash game/tools/run_tests.sh`), including T-125's `test_trick_popups_follow.gd`, `test_trick_popups.gd` (drive in the prototype) and the new prototype test. Python tests: `game/tools` 235 OK (1 skipped), `tools` 130 OK.
- Criterion 6: pass. Both say it (absolute z at the top of Godot's range, HUD and screens are CanvasLayers above). Doc nit for the Project Lead (not a fail): in `docs/hud-and-menus.md` the new sentence replaced the blank line under "### Trick popups", starts with a stray leading space and sits before "Task T-091. When the car...", so it renders as one paragraph opening with "They are always drawn..." before the popups are introduced. Moving it to the end of the section (or after the first paragraph) would read better.
- Narrow change: `git diff master...HEAD` touches only `trick_popups.gd` (new `POPUP_Z` constant; `show_popup` sets `z_as_relative = false` and `z_index = POPUP_Z` instead of `z_index = 100`), the new test and fixture, `game/README.md`, `docs/hud-and-menus.md` and this file. Look, size, stacking, follow and the quarter-screen limit are untouched.
- Anything in the world that relied on being over the popups: none found. Every other world item (ground, buildings, kaiju signs, challenge and meteor arrows, boulders, drift marks, drift smoke, level-up burst, car sprite) is at a relative z of 0 or the map's depth scheme (at most `top_z_index()`, 146; signs at front + 1); the scenes set no z. Before this change the popups were already 100 above the view (and the level-up burst and drift smoke, which share the view's z), so the only things that changed order are buildings and signs that used to cover a popup, which is the fix. No world item uses a z near 4096. Note for later: anything added to the world later that should cover a popup would need to be a CanvasLayer.
- Godot's line-ending-only `.import` noise from the runs was reverted; nothing else left in the working tree.

