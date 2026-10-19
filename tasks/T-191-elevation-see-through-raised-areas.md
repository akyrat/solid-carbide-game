---
id: T-191
title: Elevation test scene: raised areas turn see-through like buildings, and no car popping over them at a wall hit
status: open
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
qa_rounds: 0
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

- [ ] With the car behind the platform and covered by it on screen, the platform (and the ramp, when it covers the car) is drawn see-through, fading in and out like the buildings; a GUT test checks it fades when covering the car and comes back when it doesn't, and that the fade uses the buildings' numbers (15%, 0.15 s) (QA: pass / fail)
- [ ] A GUT test drives the car into each of the platform's two back sides (the ones hidden from the viewer) from behind and checks the car is drawn under the platform on every step of the hit, never over it (QA: pass / fail)
- [ ] The existing elevation tests and the full GUT suite pass (`bash game/tools/run_tests.sh`) (QA: pass / fail)
- [ ] Screenshots in `art-archive/T-191/screenshots/` show the car behind a see-through platform and the car at a back-side wall hit, and are listed in the result notes (QA: pass / fail)
- [ ] `docs/drifting.md` (Content, the elevation test scene) and `game/README.md` describe the see-through and where its code lives (QA: pass / fail)

## Updates

## Result notes
