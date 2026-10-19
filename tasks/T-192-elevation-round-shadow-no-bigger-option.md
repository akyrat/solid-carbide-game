---
id: T-192
title: Elevation test scene: a round shadow under the car, and the bigger-when-high option removed
status: in-progress
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: yes
depends_on: [T-191]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/level/elevation_platform_drawing.gd, game/scenes/elevation_test/elevation_test.tscn]
files_expected_to_change: [game/scripts/level/elevation_platform_drawing.gd, game/scenes/elevation_test/elevation_test.tscn, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-192/screenshots/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Two more changes from the board's playtest of the elevation test scene (goal G-003; board, 2026-10-19; written in `docs/drifting.md`, Decisions, "Elevation test scene, the board's playtest", on `master`; repeated here because this branch starts from the goal's build). Starts after T-191, which changes the same drawing code.

1. **Remove the "bigger when high" option** (T-187). The board tried it and didn't like it: remove the `draw_bigger_when_high` switch, its scaling code, its tests and its docs; the car is always drawn at its normal size.
2. **A round shadow.** Replace the rectangular shadow with a circle right under the centre of the car, in the same colour and feel as now (dark, opaque, hard pixel edges, no semi-transparent pixels, no Redgull red), so the player sees where the car is on the ground when it's in the air. In the isometric view a circle on the ground is drawn as an ellipse twice as wide as it is tall. It doesn't turn with the car. Size: a proposal for the board's playtest, about the car's width (1 unit across); the rest of the shadow's behaviour (where it sits, its depth order, T-191's see-through) stays as it is.

Screenshots as `tasks/README.md`, "Screenshots" says: the car on the street, on the platform and in the air with the round shadow, in `art-archive/T-192/screenshots/`.

The board's review: Play `game/scenes/elevation_test/elevation_test.tscn` (F6) in the goal's build: the shadow while jumping, and no size change with height.
Board review files: art-archive/T-192/screenshots/

## Acceptance criteria

- [ ] `draw_bigger_when_high` and its scaling are gone from the scene, the code and the tests; a GUT test checks the car's drawing scale is the same at every height (QA: pass / fail)
- [ ] The shadow is a filled ellipse centred under the car's map position, about 1 unit across on the ground (2:1 on screen), the same colour as before, opaque with no semi-transparent pixels, the same at every heading; GUT tests check its centre, its size and that it doesn't turn with the car (QA: pass / fail)
- [ ] The full GUT suite passes (`bash game/tools/run_tests.sh`) (QA: pass / fail)
- [ ] Screenshots in `art-archive/T-192/screenshots/` show the round shadow with the car on the street, on the platform and in the air, and are listed in the result notes (QA: pass / fail)
- [ ] `docs/drifting.md` and `game/README.md` no longer describe the bigger-when-high option, and describe the round shadow (QA: pass / fail)

## Updates

### 2026-10-19, Blocked → In progress

Started from your playtest: a round shadow under the car's centre, same colour and feel, and the bigger-when-high option removed. Built on the goal's build after T-191.

## Result notes

**What changed**
- Removed the bigger-when-high option: `draw_bigger_when_high` and `HEIGHT_SCALE_PER_UNIT` (`elevation_test.gd`), `height_scale_per_unit` and `scale_factor_for_height` (`car_sprite.gd`; `place()` now keeps the sheet's scale), the three `test_bigger_when_high_*` tests, and its README section and Drifting text.
- The shadow (`car_shadow.gd`) is now a filled 32-point circle of `DIAMETER_UNITS` = 1.0 on the ground, run through the view's transform (an ellipse 2:1 on screen), centred on the shadow's position (the car's map position, lifted by the ground height under it as before). It no longer takes a heading (`place(map_units, ground_height)`), so it does not turn. Same `COLOR`, opaque, no antialiasing. Placement, depth order and T-191's see-through are unchanged.
- Screenshot fixtures: `elevation_test_demo.gd` got `lift_units`; new `elevation_test_shadow_{street,platform,air,platform_air}.tscn`.
- Docs: `docs/drifting.md` and `game/README.md` (round shadow described, bigger-when-high gone). `docs/long-gdd.md` still carries the old text: regenerate it (Project Lead).

**Tests** (`game/tests/unit/test_elevation_drawing.gd`)
- Criterion 1: `test_the_cars_drawing_scale_is_the_same_at_every_height` (also checks the switch and per-unit property are gone).
- Criterion 2: `test_the_shadow_is_an_ellipse_centred_under_the_cars_map_position` (centre), `test_the_shadow_is_about_one_unit_across_and_twice_as_wide_as_tall` (size, 2:1, every point 0.5 unit from the centre on the ground), `test_the_shadow_does_not_turn_with_the_car` (same outline at 5 headings), `test_the_shadow_keeps_its_colour_and_is_opaque`, `test_the_placeholders_and_the_shadow_use_no_redgull_red`; position and surface-height tests kept.
- Criterion 3: `bash game/tools/run_tests.sh`: 1043 of 1043 passing.

**Screenshots** (`art-archive/T-192/screenshots/`)
- `shadow_street.png`: car on the street (shadow under the car body).
- `shadow_platform.png`: car on the platform.
- `shadow_air.png`: car in the air off the platform's south edge, shadow on the street below it.
- `shadow_platform_air.png`: car in the air over the platform, shadow on the platform's top.
