---
id: T-205
title: The car is drawn without its sprite shadow while in the air
status: in-qa
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: yes
depends_on: [T-204]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/driving/car_sprite.gd, game/art/car/car_iso_noshadow.json]
files_expected_to_change: [game/scripts/driving/car_sprite.gd, game/tests/unit/, game/README.md, docs/drifting.md, art-archive/T-205/screenshots/]
model: sonnet
qa_rounds: 0
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

Uses T-204's shadowless car sheet (Drifting, Decisions, "No sprite shadow in the air"; board, 2026-10-20): while the car is in the air (its height above the ground under it is more than zero, in the elevation scenes), it is drawn from `game/art/car/car_iso_noshadow.png` instead of `car_iso.png`, same frame for its heading; on the ground it uses `car_iso.png` as now. Only the drawing changes. The round shadow, the depth order and the see-through stay as they are. Everywhere the car never leaves the ground (the run, the drift prototype) nothing changes.

This branch starts from T-204's branch (it needs its art) and is merged into the elevation sample map's build (`playtest/G-004`) with it, before the board's playtest.

Screenshots (`tasks/README.md`, "Screenshots"), in `art-archive/T-205/screenshots/`: the car in the air off a rooftop in the elevation sample map (one shadow only, the round one), and the car on the street (its sprite shadow as before); a short GIF of a jump if a still doesn't show the switch at takeoff and landing.

The board's review: Jump off a rooftop in the elevation sample map: one shadow in the air, the sprite's own on the ground.
Board review files: art-archive/T-205/screenshots/

## Acceptance criteria

- [ ] A GUT test shows the car's drawing uses the shadowless sheet whenever its height is above the ground under it and the normal sheet on the ground, with the same frame for the same heading, and that the switch happens on the step it takes off and the step it lands (QA: pass)
- [ ] A GUT test shows the run's car and the drift prototype's car always use the normal sheet (QA: pass)
- [ ] The full GUT suite passes (`bash game/tools/run_tests.sh`) (QA: pass, 1080/1080)
- [ ] Screenshots in `art-archive/T-205/screenshots/` show the car in the air with only the round shadow and on the street with its sprite shadow, listed in the result notes (QA: pass)
- [ ] `docs/drifting.md` (Content, elevation) and `game/README.md` describe the switch (QA: pass)

## Updates

### 2026-10-20, Blocked → In progress

Started: the car uses the shadowless frames while in the air and its normal sprite on the ground. Built on the sample map's build with T-204's frames.

### 2026-10-20, In progress → In QA

Built: the car uses the shadowless frames while in the air and its normal sprite on the ground or a rooftop; switches on the takeoff and landing steps; the run and drift prototype are unchanged. GUT passes; screenshots on the ticket. QA checks it now.

## Result notes

What changed: `game/scripts/driving/car_sprite.gd` gets `set_in_air(bool)` (swaps only the texture to `car_iso_noshadow.png`; same layout, so the same frame) and `is_in_air(height, ground_under)`. `sync_view()` of `elevation_sample_map.gd` and `elevation_test.gd` calls it after each physics step. The run and the drift prototype never call it. Docs: `docs/drifting.md` (Content, elevation) and `game/README.md`.

Tests (all in `game/tests/unit/test_car_noshadow_in_air.gd`):
- Criterion 1: `test_above_the_ground_the_shadowless_sheet`, `test_on_the_ground_the_normal_sheet`, `test_on_a_rooftop_the_normal_sheet`, `test_the_frame_is_the_same_on_both_sheets`, `test_both_sheets_have_one_layout`, `test_is_in_air_compares_the_height_to_the_ground_under_it`, `test_the_switch_is_on_the_takeoff_step_and_the_landing_step` (checks every step of a jump).
- Criterion 2: `test_the_run_car_always_uses_the_normal_sheet`, `test_the_drift_prototype_car_always_uses_the_normal_sheet`.
- Criterion 3: `bash game/tools/run_tests.sh` passes (TESTS PASSED).

Screenshots: `art-archive/T-205/screenshots/air.png` (car in the air, only the round shadow) and `street.png` (car on the street, its sprite shadow). No GIF: the tests check the switch step by step.
