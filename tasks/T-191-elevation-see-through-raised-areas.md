---
id: T-191
title: Elevation test scene: raised areas turn see-through like buildings, and no car popping over them at a wall hit
status: needs-playtest
from: project-lead
to: driving-drift
lead: Coursework
epic: driving
milestone: mvp
goal: G-003
user_facing_text: no
changes_visuals: yes
depends_on: []
documents_affected: [docs/drifting.md, docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/level/see_through_building.gd, game/scripts/level/elevation_platform_drawing.gd, game/scenes/elevation_test/elevation_test.tscn]
files_expected_to_change: [game/scripts/level/elevation_platform_drawing.gd, game/scenes/elevation_test/elevation_test.tscn, game/tests/unit/, game/tests/fixtures/, game/README.md, docs/drifting.md, art-archive/T-191/screenshots/]
model: opus
qa_rounds: 1
---

<!--
status: open | planning | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done | cancelled
-->

## Description

The board played the elevation test scene (goal G-003) and likes it. Two problems before it merges (board, 2026-10-19; written in `docs/drifting.md`, Decisions, "Elevation test scene, the board's playtest", and `docs/level-design.md`, Decisions, "Raised areas turn see-through like buildings", on `master`; the text is repeated here because this branch starts from the goal's build):

1. **The car vanishes behind the platform.** When the car is behind a raised area (the platform and its ramp) and the raised area covers it on screen, the raised area must turn see-through the way the map's buildings do: reuse the buildings' logic (`game/scripts/level/see_through_building.gd`; Level design, Content, "When a building fades": the whole object fades to 15% visible over 0.15 seconds while it covers the car, and back over 0.15 seconds when it no longer does). Share the code rather than copying it where that's reasonable.
2. **The car pops over the platform at a wall hit.** Driving into the platform's side from behind (its top-right or top-left side on screen, where the car is hidden behind it), the car is drawn over the platform for a moment when it touches the wall. The depth order must stay right through a wall hit: a car behind the platform stays drawn under it (and, with 1, seen through it).

Work in this ticket's folder, branched from the goal's build `playtest/G-003`. Screenshots as `tasks/README.md`, "Screenshots" says: the car behind the platform with the platform see-through, and the car at the moment it hits the platform's side from behind, in `art-archive/T-191/screenshots/`.

The board's review: Play `game/scenes/elevation_test/elevation_test.tscn` (F6) in the goal's build, drive behind the platform and into its back sides, and look at the screenshots.
Board review files: art-archive/T-191/screenshots/

## Acceptance criteria

- [ ] With the car behind the platform and covered by it on screen, the platform (and the ramp, when it covers the car) is drawn see-through, fading in and out like the buildings; a GUT test checks it fades when covering the car and comes back when it doesn't, and that the fade uses the buildings' numbers (15%, 0.15 s) (QA: pass)
- [ ] A GUT test drives the car into each of the platform's two back sides (the ones hidden from the viewer) from behind and checks the car is drawn under the platform on every step of the hit, never over it (QA: pass)
- [ ] The existing elevation tests and the full GUT suite pass (`bash game/tools/run_tests.sh`) (QA: pass)
- [ ] Screenshots in `art-archive/T-191/screenshots/` show the car behind a see-through platform and the car at a back-side wall hit, and are listed in the result notes (QA: pass)
- [ ] `docs/drifting.md` (Content, the elevation test scene) and `game/README.md` describe the see-through and where its code lives (QA: pass)

## Updates

### 2026-10-19, Open → In progress

Started from your playtest: the platform turns see-through like the buildings when the car is behind it, and the car won't pop over it at a back-side wall hit. Built on the goal's build.

### 2026-10-19, In progress → In QA

Built: the platform and ramp turn see-through like the buildings (shared code), and the wall-hit pop is fixed (the depth rule now uses the car's centre). 18 new tests, GUT 1042/1042. QA checks it now.

### 2026-10-19, In QA → Needs playtest

QA passed all 5 criteria. In the goal's build for your playtest: the platform and ramp turn see-through like the buildings, and no car pop at a back-side wall hit. T-192 (round shadow, bigger option removed) starts now.

## Result notes

**Driving & Drift Agent, 2026-10-19.** Both problems fixed on `task/T-191-elevation-see-through` (from `playtest/G-003`).

**1. See-through raised areas.** The platform and the ramp each fade as a whole (only `modulate.a`, so the PixelLab art sprite, a child, fades with it) to 15% over 0.15 s while they cover the car, and back over 0.15 s. "Covers" is the buildings' rule: the car is behind the area (the scene's depth rule, `is_behind`) and the car's on-screen shape overlaps the area's silhouette. The car's shape is lifted by its height, so a car above the platform never makes it fade.

The code is shared with the map's buildings, not copied. `game/scripts/level/map_building.gd` (`faded_alpha`, the fade step, now also used by the buildings' own `step_fade`) and `game/scripts/level/mvp_map.gd` (the `SEE_THROUGH_ALPHA` and `SEE_THROUGH_FADE_TIME` numbers, and `car_screen_shape_at`, the car's on-screen shape) are the real map's code, not `see_through_building.gd`. That file is the T-020 research demo, set to 35%. The ticket's 15% and 0.15 s are the map's numbers. The two shared functions are small refactors: the buildings' behaviour is unchanged, and their tests pass.

**2. Car popping over the platform at a back-side wall hit.** The cause: `is_behind` counted the car as behind only when its whole 1 x 1 footprint (radius 0.5) was west or north of the platform. The platform's sides stop the car's centre point (`car_height.gd`, `_walk`), not its body. So from about 0.5 units before the wall until the hit, the footprint reached into the platform's rectangle. The car was then neither behind nor in front, and was drawn over everything. The fix is to judge "behind" by the centre (the "in front" test is unchanged). With the old rule the new tests fail at the first step within 0.5 units of the wall, at x or y = -8.399, with the car at z 5 over the platform at z 3. With the fix they pass.

One side effect to look at in the playtest: a car falling off the platform's north or west edge is drawn under it as soon as its centre is past the edge and it is below the top. Before, that happened only once it was 0.5 units clear. This is physically right, but the change shows.

**Files changed:** `game/scripts/level/elevation_platform_drawing.gd`, `game/scripts/driving/elevation_test.gd` (`update_see_through`, `car_shape`, `covering_areas`; it was not in files_expected_to_change, but it is where the scene's per-step logic lives), `game/scripts/level/map_building.gd`, `game/scripts/level/mvp_map.gd`, `game/tests/fixtures/elevation_test_demo.gd` (a `see_through` switch for the screenshots), 5 new fixtures, `game/tests/unit/test_elevation_see_through.gd`, `docs/drifting.md` (Content, "Elevation test scene": the Depth order bullet, a new See-through bullet, and the old "For the board's playtest" line rewritten), and `game/README.md` (the depth rule, plus a new section, "See-through raised areas (T-191)"). `elevation_test.tscn` did not need to change.

**Not done here:** `docs/level-design.md` is listed as affected, but its T-191 decision is on `master` and this branch does not have it. Its Content needs no change for this work. The Project Lead can check it at merge.

**Tests per criterion** (all in `game/tests/unit/test_elevation_see_through.gd`):
- Criterion 1: `test_the_fade_uses_the_buildings_numbers`, `test_the_fade_step_is_the_buildings_one`, `test_the_platform_fades_while_it_covers_the_car_and_comes_back` (half way after 0.075 s, 15% after 0.15 s, back to solid after 0.15 s), `test_the_platform_fades_with_the_car_north_of_it_too`, `test_the_ramp_fades_when_it_covers_the_car`, `test_nothing_fades_when_the_car_is_on_or_in_front_of_the_areas`, `test_the_platform_does_not_fade_when_the_car_is_behind_but_far_from_it_on_screen`, `test_the_car_above_the_platform_does_not_make_it_fade`, `test_only_modulate_alpha_changes_so_the_art_fades_with_the_area`, `test_the_scene_fades_by_itself_while_driving`.
- Criterion 2: `test_driving_into_the_west_side_straight_stays_under_the_platform`, `..._west_side_at_an_angle_...`, `..._west_side_while_steering_...`, `test_driving_into_the_north_side_straight_stays_under_the_platform`, `..._north_side_at_an_angle_...`, `..._north_side_while_steering_...`. Each drives with W held for 150 steps and checks the car (and its shadow) is under the platform on every step. Each also checks that a wall hit happened and that the footprint reached into the side. Also `test_at_the_back_side_hit_the_platform_is_see_through` and `test_a_car_straddling_a_back_side_is_behind_by_its_centre`.
- Criterion 3: `bash game/tools/run_tests.sh`: 1042/1042 passed, including the existing `test_elevation_drawing.gd`, `test_elevation_edges.gd` and `test_elevation_art.gd`. The 1 orphan in the full run is not from the new file, which runs with none.

**Screenshots** (`art-archive/T-191/screenshots/`, taken with `game/tools/screenshot.sh` at zoom 10):
- `behind_see_through.png`: the car on the street west of the platform, behind it, with the platform see-through. Fixture: `elevation_test_see_through.tscn`.
- `wall_hit_west_side.png` and `wall_hit_north_side.png`: the step the car meets the west side (top-left on screen) and the north side (top-right), at x or y = -8.003, with the platform see-through and the car drawn under it. Fixtures: `elevation_test_wall_west.tscn` and `elevation_test_wall_north.tscn`.
- `wall_hit_west_side_solid.png` and `wall_hit_north_side_solid.png`: the same moments with the fade off, so only the depth order shows. The car is hidden under the platform and not drawn over it. Fixtures: `elevation_test_wall_{west,north}_solid.tscn`.
- In the see-through shots a pink oval shows through the platform at its centre. It is the street grid's origin marker (`ground_grid.gd`, `origin_color`, a circle at (0, 0)), seen through the platform, not something this task added.
