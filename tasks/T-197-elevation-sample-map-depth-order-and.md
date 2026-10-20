---
id: T-197
title: Elevation sample map: depth order and see-through across every raised area, ramp and building
status: in-progress
from: project-lead
to: level-challenge
lead: Goal-G-004
epic: level-challenges
milestone: mvp
goal: G-004
user_facing_text: no
changes_visuals: yes
depends_on: [T-196]
documents_affected: [docs/level-design.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/level-design.md, docs/visual-style.md, docs/extended-narrative.md, game/README.md, game/scripts/level/elevation_sample_map.gd, game/scripts/level/elevation_platform_drawing.gd, game/scripts/level/map_building.gd, game/scripts/level/mvp_map.gd, game/scripts/driving/elevation_test.gd, game/tests/unit/test_elevation_see_through.gd, game/tests/unit/test_see_through_map.gd]
files_expected_to_change: [game/scripts/level/elevation_sample_map.gd, game/scripts/level/elevation_platform_drawing.gd, game/tests/unit/test_elevation_sample_depth.gd, game/tests/unit/test_elevation_sample_see_through.gd, game/tests/fixtures/elevation_sample_*.tscn, game/README.md, docs/level-design.md]
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

Level design, Decisions, 'Raised areas turn see-through like buildings' and 'See-through buildings' (Content), and 'Elevation sample map' (board, 2026-10-19). The elevation test scene had one platform and one ramp; the sample map scene (D4) has several raised areas, stacked areas (a height-6 rooftop on a height-3 one), ramps between rooftops and the MVP map's buildings, all in one depth order.

Make the depth order work across all of them: the car and its shadow are drawn under any raised area, ramp or building they are behind and lower than its top, and over the ones they are on, above or in front of. Areas and buildings are drawn in a consistent back-to-front order with each other (a stacked height-6 area over the height-3 area it stands on).

See-through: every raised area and ramp that covers the car fades to mvp_map.gd's SEE_THROUGH_ALPHA over SEE_THROUGH_FADE_TIME with map_building.gd's faded_alpha (shared, not copied, as elevation_platform_drawing.gd already does); areas that don't cover it stay opaque; buildings keep fading as on the MVP map. Keep T-191's fix: when the car drives into the back sides (top-left and top-right on screen) of a height-3 and a height-6 area, it stays under the area through the hit, with no popping over it.

Don't change the elevation test scene's behaviour or the MVP map's: their tests pass unchanged. Screenshots: the car behind a see-through height-3 area and behind a see-through height-6 area, and the car behind a building next to a raised area; in art-archive/<task id>/screenshots/.

The board's review: Depth order and see-through rooftops on the elevation sample map, in the goal's final playtest.

## Acceptance criteria

- [ ] GUT tests in the sample map scene check the z order for: the car on height 3 behind a height-6 area (car and shadow under it); the car in the air above height 6 over a height-3 area (car over it); the car behind a building next to a raised area (car under the building); the car on top of a height-6 area (over it and over the height-3 area it stands on). They pass. (QA: pass / fail)
- [ ] GUT tests check that a raised area or ramp covering the car fades to mvp_map.gd's SEE_THROUGH_ALPHA over SEE_THROUGH_FADE_TIME, that areas not covering it stay at alpha 1, and that the fade comes from map_building.gd's faded_alpha (no copied fade code: grep shows no second fade formula). (QA: pass / fail)
- [ ] Tests like test_elevation_see_through.gd drive the car into the back sides (top-left and top-right on screen) of a height-3 and a height-6 area and check the car stays under the area every step through the hit; they pass. (QA: pass / fail)
- [ ] test_elevation_see_through.gd, test_elevation_drawing.gd, test_see_through_map.gd and test_see_through_buildings.gd pass unchanged. (QA: pass / fail)
- [ ] Screenshots in art-archive/<task id>/screenshots/ show the car behind a see-through height-3 area, behind a see-through height-6 area, and behind a building next to a raised area; listed in the result notes and on the Board review files line. (QA: pass / fail)
- [ ] game/README.md and docs/level-design.md describe the depth order and see-through on the sample map. (QA: pass / fail)
- [ ] All three test sets pass. (QA: pass / fail)

## Updates

The Project Lead's replies to the board on this ticket, newest last, one entry per lane change. Written only through `task_status.py --reply`; leave it empty here.

### 2026-10-20, Blocked → In progress

Goal runner (G-004): started, in C:\solid-carbide-worktrees\T-197.

## Result notes

Written by the agent when it finishes.
