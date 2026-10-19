---
id: T-192
title: Elevation test scene: a round shadow under the car, and the bigger-when-high option removed
status: open
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

## Result notes
