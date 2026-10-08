---
id: T-029
title: Set the drift prototype's defaults from the board's playtest
status: open
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: no
depends_on: [T-012]
documents_affected: [game/README.md]
files_to_read_first: [tasks/README.md, docs/drifting.md, docs/drifting/unity-prototype-report.md, tasks/T-012-godot-drift-prototype.md, game/README.md]
files_expected_to_change: [game/scripts/driving/car_tuning.gd, game/scripts/driving/tuning_panel.gd, game/scripts/driving/drift_prototype.gd, game/project.godot, their tests, game/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
epic and milestone: one of the ids listed in tasks/README.md.
user_facing_text and changes_visuals: yes or no; see "User-facing text and visuals" in tasks/README.md.
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The board playtested the drift prototype (T-012) and is very happy with it. A few values change from the Unity prototype's (Drifting, Decisions, 2026-10-08). Make them the defaults:

1. **Top speed:** `top_speed_multiplier` defaults to **3.0** (Unity: 2.5). The jump to cruise speed stays at **11**. Every other driving value keeps the Unity value.
2. **Physics interpolation is on** in `game/project.godot`.
3. **The prototype starts in the isometric view.** V still switches to the flat view.
4. **The tuning panel's reset button** goes back to the game's values: these defaults, interpolation on, zoom 14.4. Each slider's tooltip may still show the Unity value for reference.

The tests from T-012 that prove the car matches the Unity prototype keep doing so: they use the Unity values explicitly instead of the defaults. Don't change the driving code's logic, only the defaults.

The camera zoom slider for players is T-015's job, not this task's.

Work on your own branch and folder, as `tasks/README.md` ("Git branches") describes.

## Acceptance criteria

- [ ] In `car_tuning.gd`, `top_speed_multiplier` defaults to 3.0 and `forward_speed` to 11. Every other default equals the Unity value in the Unity prototype report, section 5 (QA compares by hand) (QA: pass / fail)
- [ ] `game/project.godot` has physics interpolation on (QA: pass / fail)
- [ ] A test shows that with the default tuning, holding W from standstill reaches a top speed of 33 (3.0 × 11), within one step's rounding (QA: pass / fail)
- [ ] The T-012 tests that check the Unity behaviour (cruise, coasting, braking, rotation, drift angle) still pass, using the Unity values explicitly (QA: pass / fail)
- [ ] A screenshot taken right after the prototype starts shows the isometric view (QA: pass / fail)
- [ ] A test shows that the panel's reset button restores top speed 3.0, physics interpolation on and zoom 14.4 (QA: pass / fail)
- [ ] `game/README.md` describes the new defaults (or points to Drifting, Decisions) (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)

## Result notes

Written by the agent when it finishes.
