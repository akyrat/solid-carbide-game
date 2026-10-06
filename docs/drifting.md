---
title: Drifting
gdd_order: 2
scope: How the car drives, drifts and reverses, the prototypes built so far, and the research and decisions behind them.
agents_work_on: [driving-drift]
agents_read: []
---

# Drifting

## Summary

Drifting is the one core skill of Solid Carbide. The car's driving and drifting copy the board's older Unity prototype, including its drift curve and its camera, and the car can also reverse. The player drives with W to go forward, S to reverse, and A and D to steer and drift.

## Decisions

- The car's driving and drifting copy the board's Unity prototype (see Content, "Prototypes so far"). (2026-10-04)
- The car can reverse with the S key, as in the Unity prototype. Controls: W to go forward, S to reverse, A and D to steer and drift. (2026-10-04)
- The drift curve is the one the Unity prototype uses. This replaces the earlier plan to choose between three candidate curves (square root, linear or exponential) by playtesting. Drift is not meant to be realistic. (2026-10-04)
- The camera behaves like the Unity prototype's camera by default (how it follows the car, its zoom and any look-ahead), unless the board decides otherwise later. (2026-10-04)
- Settling the movement mechanics is one of the project's top priorities and the first thing to work on. (2026-10-03)
- When W makes the car jump instantly to cruise speed, a short "boost" effect plays to emphasise the jump. (2026-10-06)
- The reference feel is the Unity prototype on its Grass stage, the only stage the board played. Grass has no off-road slowdown, so the Isometric stage's off-road damping is not part of the reference. (2026-10-06)
- The camera zoom is a player setting with a slider in the settings menu. The board picks its default by playtesting the Godot car (task T-010). (2026-10-06)
- The Godot car runs its physics at 50 steps per second, like the Unity prototype, so the per-step values carry over exactly. If 50 turns out not to be possible, the values are converted for 60. (2026-10-06)
- The car's physics stays flat top-down, as in the Unity prototype, and the Godot version draws it isometrically. The board will playtest whether it feels the same; if not, the game may go back to a flat top-down view. (2026-10-06)

## Content

### Prototypes so far

The board built two drift prototypes before this project:

- **The older prototype, in Unity: the board is very happy with it.** It is at `C:\Users\andre\drift-to-survive` on the board's machine (Unity 6000.3, project name DriftSurvivors). The reference is its current state. Its driving values come from the project files (the vehicle data asset); the board's earlier pause-menu tuning is no longer read by the current code, and only the camera zoom is still a saved pause-menu setting (in the Windows registry). Its driving and drifting are the reference for Solid Carbide. It also has reverse on the S key.
- **The newer prototype: the board is not happy with how it turned out.** It is not used as a reference and will not be analysed.

A report on how driving, drifting and reverse behave in the Unity prototype, with the preparations needed to reproduce them in Godot, is done (task T-006). See References.

### Unity prototype summary

Facts from the report (Unity prototype report, sections 1 to 7). No new decisions.

- The car is a top-down 2D physics body. Every physics step (50 per second) the code sets its velocity directly, split into speed along the nose and speed across it. No forces.
- The handling values come from the car's data asset in the project files. The current code reads no driving value from the registry; the only saved setting that still matters is the camera zoom.
- W snaps the car to a cruise speed of 11 units per second (the car is 1 unit long), then speed climbs in a straight line to a top speed of 27.5. Letting go coasts down in a straight line.
- S brakes in a straight line while moving forward, snaps to 11 backwards at zero, then climbs to 27.5 backwards. W always wins over S.
- A and D rotate the car at a fixed 191.9 degrees per second at every speed, including standing still.
- The drift comes from sideways speed being kept at 98% per physics step: held W + A or W + D builds a wide slide that levels off near a 75 degree drift angle at about 34 units per second.
- A coded "drift amount" ramps from 0 to 1 in 0.08 seconds and back in 0.33 seconds. With the current car values it does not change the handling; it drives the drift effects.
- The camera is orthographic, sits exactly on the car every frame, never rotates, and has no smoothing or look-ahead. Its zoom (default 14.4, half the visible height in world units) is a saved pause-menu setting.

## Open questions

- What does the boost effect look like?
- What is the default camera zoom? (Task T-010.)
- Does the isometric drawing feel the same as the flat top-down prototype? (Board playtest.)
- Should the Unity prototype's test jump on Space carry over? (Unity prototype report, section 9.)
- Should the arrow keys also steer? The Unity prototype's README says they do, but its code doesn't read them.
- Should gamepad support carry over (triggers as on/off, analog stick steering)?
- Should collisions with walls and enemies feel like the Unity prototype's (Box2D), and if so, in the movement prototype or later?
- Does the board remember a version of the Unity prototype whose camera rotated with the car? An old saved setting suggests one existed; the current version's camera never rotates.
- Far-future idea: a trick system for the car (front flips, back flips, in the style of Olli Olli World). Long-term only.

## References

- Unity prototype report: [drifting/unity-prototype-report.md](drifting/unity-prototype-report.md).
