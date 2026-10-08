---
id: T-012
title: Godot drift prototype: copy the Unity car, with tuning sliders and a flat/isometric view switch
status: in-progress
from: project-lead
to: driving-drift
epic: driving
milestone: mvp
user_facing_text: no
changes_visuals: yes
depends_on: [T-013, T-018]
documents_affected: [docs/drifting.md, game/README.md]
files_to_read_first: [tasks/README.md, docs/README.md, docs/drifting.md, tasks/T-013-placeholder-car-sprites.md, docs/drifting/unity-prototype-report.md, game/README.md, .claude/agents/driving-drift.md, docs/extended-narrative.md, docs/visual-style.md]
files_expected_to_change: [the drift prototype scene, the car's script and settings, the tuning panel, their tests, project.godot (physics rate, input map), docs/drifting.md, game/README.md]
qa_rounds: 0
---

<!--
status: open | in-progress | in-qa | needs-playtest | blocked | flagged-for-review | done
qa_rounds: how many times QA has checked this task. The maximum is 2.
A task is not done until every document listed in documents_affected has been updated.
-->

## Description

The car is drawn with simple placeholder sprites (T-013 made the script and layout, T-018 redrew them at 3:1 with 80 by 80 frames, and both are done; the sheets and their layout are documented in `game/README.md`, "Placeholder car sprite sheets").

The first playable piece of Solid Carbide: the car, driving and drifting exactly like the board's Unity prototype, so the board can playtest it. The decisions are in Drifting, Decisions; how the Unity car works, with every value, is in the Unity prototype report (`docs/drifting/unity-prototype-report.md`), especially sections 4 (step by step), 5 (values) and 8 (porting to Godot). Copy it faithfully: do not improve or redesign the handling. Where the report and a decision disagree, the decision wins; where something is unclear, ask through the result notes rather than guess. The Unity project itself is not needed; if consulted, it is read-only.

**What to build: a drift prototype scene**

- **The car:** drawn with the simple placeholder sprites from T-018 (plain 3:1 rectangles, made with T-013's script; 16 directions, one sheet for the flat view and one for the isometric view). Show the frame closest to the car's heading, reading the layout from the JSON file next to each sheet, so the full pixel-art sheets (T-014) drop in later with no code change. The car's physics body stays a 1 by 1 unit square, as the report describes; the drawn car is 1 unit wide and 3 long, centred on it, so it sticks out at the front and back (Drifting, Decisions).
- **The ground:** flat and empty, like the Unity Grass stage (no off-road slowdown, no obstacles), with a simple grid or markers so movement and speed are visible.
- **Controls:** W forward, S brake and reverse, A and D steer, exactly as the report's section 2 describes for the keyboard. Tab opens and closes the tuning panel. Escape is not used here: it pauses the game, built separately in T-015. Not in this task: the jump on Space, the arrow keys, the gamepad. They stay open questions for the board.
- **Movement:** the report's section 4, step by step, at **50 physics steps per second** (Drifting, Decisions). Include the coded drift amount, the one-step lag between rotation and velocity, the instant jump to cruise, braking, the snap into reverse, and coasting. Expose a clear signal when W makes the car jump to cruise speed, for the boost effect in T-008 (do not build the effect here).
- **Tuning panel:** sliders for every setting in the report's section 8 list ("Proposed settings for the Godot prototype"), except off-road damping and the physics rate. Each slider has the plain-language label from that list, starts at the Unity value, applies live, and there is one button to reset all to the Unity values. Explain each slider in a short tooltip.
- **Camera:** like the Unity camera (report section 7): sits exactly on the car, never rotates, no smoothing, no look-ahead. A **zoom slider** from 6 to 20, starting at 14.4 (the Unity default, until the board decides in T-010). Physics interpolation off by default, matching Unity's stepped motion; give the board an on/off toggle for it in the panel, since the report notes it is a visible difference.
- **View switch (flat / isometric):** the physics always runs in a flat top-down world (Drifting, Decisions). One key and one panel toggle switch only how it is drawn: **flat top-down**, as in Unity, or **isometric**, with a standard 2:1 isometric projection of the same world. Switching never changes the car's position, speed or rotation, and can be done mid-drive. Use the pixel scale that matches T-013's sprites, and document it; the board judges the look in playtest.

**Tests (GUT):** check the movement against the numbers in the report, which `python tools/unity_drift_charts.py --summary` also prints. Use those as the reference values.

**Documentation:**
- `game/README.md`: how to open and run the drift prototype, and its keys.
- `docs/drifting.md`: a `### Godot drift prototype` subsection in Content: where it is, how to run it, the view switch and the panel. Facts only; follow `docs/README.md`. Do not change Summary, Decisions or Open questions.

## Acceptance criteria

- [ ] `game/project.godot` sets 50 physics ticks per second, and the input map binds W, S, A and D to the car's actions (QA: pass / fail)
- [ ] GUT tests show the speed profile matches the report: W from standstill gives 11 on the first step, top speed 27.5 is reached 69 steps after cruise, coasting from 27.5 reaches 0 in 3.3 s (±1 step), S from 27.5 reaches 0 in 2.3 s (±1 step) and then snaps to -11, and W while reversing snaps to +11 (QA: pass / fail)
- [ ] GUT tests show the rotation rate is 191.9 degrees per second both at standstill and at top speed (QA: pass / fail)
- [ ] GUT tests of W + A held from top speed show the drift angle passing 45 degrees at 0.28 s (±0.04 s), and settling at a total speed of 33.9 (±0.5) and a drift angle of 75 degrees (±2), matching `tools/unity_drift_charts.py --summary` (QA: pass / fail)
- [ ] The car's default values equal the "Value in project files (used)" column of the report's section 5, checked for every slider setting (QA: pass / fail)
- [ ] Every setting in the report's section 8 list, except off-road damping and the physics rate, has a slider; a test shows changing a slider changes the movement, and the reset button restores every Unity value (QA: pass / fail)
- [ ] A test shows switching between flat and isometric view, mid-drive, leaves the car's position, velocity and rotation identical to a run without switching (QA: pass / fail)
- [ ] Screenshots (with the T-001 screenshot tool) of the prototype in flat view and in isometric view each show the ground grid and the car drawn with the matching T-013 sheet, facing its heading (QA: pass / fail)
- [ ] The camera stays centred on the car and never rotates while the car turns, shown by a test or by two screenshots at different car rotations; the zoom slider covers 6 to 20 and starts at 14.4 (QA: pass / fail)
- [ ] The full GUT suite and all Python tool tests pass (QA: pass / fail)
- [ ] `game/README.md` explains how to run the prototype and its keys; `docs/drifting.md` has a `### Godot drift prototype` subsection in Content, still follows the five-section structure, and its Summary, Decisions and Open questions are unchanged (QA: pass / fail)

**The board's playtest:** drive it in flat view and compare the feel with the Unity prototype on Grass, then switch to isometric and judge whether it feels the same (Drifting, Open questions).

## Result notes

Written by the agent when it finishes.
