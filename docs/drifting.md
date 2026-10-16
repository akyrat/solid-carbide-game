---
title: Drifting
gdd_order: 2
scope: How the car drives, drifts and reverses, the prototypes built so far, and the research and decisions behind them.
agents_work_on: [driving-drift]
agents_read: []
---

# Drifting

## Summary

Drifting is the one core skill of Solid Carbide. The car's driving and drifting copy the board's older Unity prototype, including its drift curve and its camera, with a higher top speed chosen after the board's playtest of the Godot version, and the car can also reverse. The player sets the camera zoom in the pause menu. The player drives with W to go forward, S to reverse, and A and D to steer and drift.

## Decisions

- The car's driving and drifting copy the board's Unity prototype (see Content, "Prototypes so far"). (2026-10-04)
- The car can reverse with the S key, as in the Unity prototype. Controls: W to go forward, S to reverse, A and D to steer and drift. (2026-10-04)
- The drift curve is the one the Unity prototype uses. This replaces the earlier plan to choose between three candidate curves (square root, linear or exponential) by playtesting. Drift is not meant to be realistic. (2026-10-04)
- The camera behaves like the Unity prototype's camera by default (how it follows the car, its zoom and any look-ahead), unless the board decides otherwise later. (2026-10-04)
- The car is drawn 3 times as long as it is wide: 1 unit wide and 3 units long. This is the drawing only: the car's physics body stays a 1 by 1 unit square, as in the Unity prototype, so collisions behave the same. The drawing sticks out past the body at the front and back. (2026-10-07)
- The car bounces off walls slightly (buildings and the map's edges), and off boulders the same way. (2026-10-08)
- The car does not bounce off enemies: they only damage it. (2026-10-09)
- The bounce off walls and boulders sends the car back at a quarter of the speed it hit with (bounce strength 0.25). While W is held the car stays pressed against the wall, and a knockback against the car's nose is cancelled, because W keeps snapping the car back to cruise speed; the board is fine with both. (2026-10-10)
- The MVP has three **tricks**, all done with the car's existing driving (what tricks are worth: Game loop architecture, Decisions): (2026-10-10)
  - **Extended drift:** every second of drifting counts as one low-value trick.
  - **360:** the car's heading turns a full 360 degrees in one direction during one unbroken drift; a mid-value trick. 720 degrees counts as two.
  - **Alternate drift:** drift forwards, release W while still steering, switch to S and drift backwards, then back to W, so the car draws semicircles. Each switch between a forward and a backward drift while keeping the same steering direction counts as one high-value trick. The Driving & Drift Agent proposes the timing limits; the board tunes them.
- Settling the movement mechanics is one of the project's top priorities and the first thing to work on. (2026-10-03)
- When W makes the car jump instantly to cruise speed, a short "boost" effect plays to emphasise the jump. This comes after the MVP (tasks T-008 and T-009, final release). Its look: Visual style, Decisions. (2026-10-06; after the MVP, 2026-10-09)
- The reference feel is the Unity prototype on its Grass stage, the only stage the board played. Grass has no off-road slowdown, so the Isometric stage's off-road damping is not part of the reference. (2026-10-06)
- The camera zoom is a player setting: a slider in the pause menu (HUD and menus, Decisions), with the Unity prototype's range, 6 to 20, and its default, 14.4. As in the Unity prototype, the player's choice is saved between sessions. (2026-10-08; replaces the 2026-10-07 decision that the zoom is fixed)
- Two camera options to try, each a pause-screen checkbox, off by default and saved like the zoom (board, 2026-10-13): **camera smoothing** (the camera follows the car with a short smooth lag instead of sitting exactly on it), and the **dynamic camera** (the zoom follows the car's speed, from a min zoom at very low speed to a max zoom at the car's top forward speed, easing there with a short delay instead of jumping; while it is on it replaces the slider's fixed zoom). The board tunes the min and max in playtests with temporary pause-screen buttons. These are a change from the Unity prototype's camera, which stays the default.
- The car's top forward speed is **half** what it was: 16.5 units a second instead of 33 (the top-speed multiplier on the cruise speed goes from 3 to 1.5; the cruise speed of 11 is unchanged). Tried in the board's quick tuning on T-124 and kept. (board, 2026-10-14)
- The Godot car runs its physics at 50 steps per second, like the Unity prototype, so the per-step values carry over exactly. If 50 turns out not to be possible, the values are converted for 60. (2026-10-06)
- The car's physics stays flat top-down, as in the Unity prototype, and the Godot version draws it isometrically. (2026-10-06)
- The board playtested the Godot drift prototype in the isometric view and is very happy with it. The game uses the isometric view and the Unity values, with two changes: the top speed is **3.0 times** cruise speed (Unity: 2.5), and **physics interpolation is on**, for smoother motion between physics steps. The jump to cruise speed stays at 11. (2026-10-08)

- **Arrow-key tricks, prototype** (board, 2026-10-16): a standalone trick prototype to playtest the idea of tricks done by chaining arrow keys while driving with W/A/S/D. One trick for now: Up, Right, Down, Left in a row makes the car do a **side flip to the right** (a full roll around its long axis) with the illusion of a small jump; the car's physics stays on the ground. A live HUD in the bottom-right corner shows the four arrow keys as they are pressed, and completing the sequence plays a comic-style confirmation animation. The roll is generated with PixelLab for one car direction first. Not part of the MVP; it tries out the far-future trick idea (Open questions). Tasks T-150 to T-153.

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
- W snaps the car to a cruise speed of 11 units per second (the Unity car is 1 unit long), then speed climbs in a straight line to a top speed of 27.5. Letting go coasts down in a straight line.
- S brakes in a straight line while moving forward, snaps to 11 backwards at zero, then climbs to 27.5 backwards. W always wins over S.
- A and D rotate the car at a fixed 191.9 degrees per second at every speed, including standing still.
- The drift comes from sideways speed being kept at 98% per physics step: held W + A or W + D builds a wide slide that levels off near a 75 degree drift angle at about 34 units per second.
- A coded "drift amount" ramps from 0 to 1 in 0.08 seconds and back in 0.33 seconds. With the current car values it does not change the handling; it drives the drift effects.
- The camera is orthographic, sits exactly on the car every frame, never rotates, and has no smoothing or look-ahead. Its zoom (default 14.4, half the visible height in world units) is a saved pause-menu setting.

### Godot drift prototype

The Godot copy of the Unity car (task T-012), for the board's playtest.

- **Where:** the scene `game/scenes/drift_prototype/drift_prototype.tscn`, the project's main scene, with its code in `game/scripts/driving/`. How it is built, its keys and how to run it: `game/README.md`, "Drift prototype".
- **How to run it:** open `game/` in Godot 4.6 and press F5, or run `"$GODOT_BIN" --path game` from the repo root.
- **Controls:** W, S, A and D as in the Unity prototype (Unity prototype report, section 2). Tab opens the tuning panel, V switches the view. No jump, arrow keys or gamepad.
- **Ground:** flat and empty, like the Unity Grass stage, with a grid (a thin line every unit, a stronger one every 5 units) and a marker at the start point.
- **Movement:** the Unity prototype report's section 4, step by step, at 50 physics steps per second, with the Unity values (report, section 5). The GUT tests check it against the report's numbers. One difference: the comparison that decides whether W snaps to cruise speed (and S to reverse cruise speed) ignores rounding errors below 0.000000001 units per second. Without it, at some headings the forward speed reads back a hair under cruise speed and W would snap to cruise speed on every step instead of climbing to top speed.
- **Boost signal:** the car signals each time W makes it jump up to cruise speed, with the speed before the jump and whether W was just pressed. During a held W + A or W + D drift the slide pulls the forward speed under cruise speed, so the jump happens on most steps of the drift too (with W not just pressed).
- **Scale and camera:** 16 pixels per unit, the scale of the placeholder car sheets. The camera sits exactly on the drawn car, never rotates and has no smoothing or look-ahead. Its zoom is Unity's orthographic size, half the visible height in units.
- **View switch:** the physics always runs in the flat top-down world. V, or the panel's "Isometric view" toggle, switches only the drawing: flat top-down with the flat placeholder sheet, or a standard 2:1 isometric projection (screen = (x - y, (x + y) / 2)) of the same world with the isometric sheet. It can be switched mid-drive; the car's position, speed and rotation do not change.
- **Collisions (task T-033):** the car's 1 by 1 unit body bounces off walls, buildings, the map's edge and boulders, and drives through enemies without bouncing. How hard it bounces is a tuning panel slider, "Wall bounce", in a "Collisions" group at the bottom of the panel: the share of its speed into the wall the car keeps, bouncing back (0 = no bounce, 1 = full bounce). The proposed default is 0.25, for the board to judge in a playtest; the Unity prototype has no bounce. The prototype has a test room for trying it: a few walls and a boulder 3 units across. The car also signals each hit (for the combo) and can be knocked back by other code (minions, meteors). Details, the collision layers and the knockback function: `game/README.md`, "Car collisions".
- **Tricks (task T-079):** the car finds the three tricks (Decisions) in its own driving without changing how it drives, and signals each one with its id for the combo and the popups. "Drifting" is the Unity definition (W or S held together with A or D); any step without it is a break. An extended drift is each full second of one unbroken drift. A 360 is each full turn of the heading in one direction during one unbroken drift; turning back the other way or a break starts the count again. An alternate drift is each switch between a forward drift (W) and a backward drift (S) with the same steering side, within limits the board tunes in the tuning panel's "Tricks" group: the switch from one drift to the other may take at most 0.5 seconds, both drifts must last at least 0.3 seconds (the trick counts when the new one reaches it), and A or D must stay held on the same side during the switch. These three values are proposals. The tuning panel's readout shows the last trick. The signal, the trick ids and the details: `game/README.md`, "Tricks".
- **Camera options (task T-123):** the two camera options (Decisions, 2026-10-13), both off by default; with both off the camera is exactly as above. They work the same in the drift prototype and in the run (also a run started from the main menu), and are saved with the zoom in the player's settings. **Camera smoothing:** each physics step the camera closes 1 - e^(-8 x step time) of its gap to the drawn car (rate 8 per second), so it trails a moving car by about its speed / 8 (about 4 units at the top speed of 33 units per second, under a third of the default half-height of 14.4) and catches up within about half a second once the car stops. **Dynamic camera:** the zoom's target is the min zoom at a standstill and the max zoom at the car's top forward speed, in a straight line in between (half speed: halfway), using the car's speed in any direction as a share of its top forward speed (capped at 1), so a fast slide or a fast reverse also zooms out. The zoom eases toward the target at a rate of 3 per second (about 63% of the way in a third of a second, 95% in one second), so it never jumps. While it is on it replaces the slider's zoom; moving the slider while it is on shows that zoom at once (so the board can see the value it is about to set as min or max), and the camera eases back to the speed's zoom once the car moves. Turning it off goes straight back to the slider's zoom. **Min and max:** proposed 11 (zoomed in at a standstill) and 17 (zoomed out at top speed), around the default 14.4 and within the slider's 6 to 20; the board sets them in playtests with the pause screen's buttons (task T-124), which take the slider's current zoom. The two rates are proposals in one place in the code. Settings keys, the API for the pause screen and where the saved min and max can be read: `game/README.md`, "Camera options".
- **Tuning panel (Tab):** one slider per setting in the report's section 8 list except off-road damping and the physics rate (cruise speed, top speed multiplier, time to top speed, coast slowdown, turn speed, steering sensitivity, base sideways grip, drift grip at low and high speed, drift speed reference, drift enter and exit rates), plus the camera zoom (6 to 20, starting at 14.4). Each slider applies live and has a tooltip showing the Unity value. The sliders start at the game's values (Decisions, 2026-10-08 and 2026-10-10), and one button resets everything to them. A "Physics interpolation" toggle (on, the game's value; Unity has it off) smooths the motion between physics steps. A readout shows speed, drift angle and drift amount. Nothing is saved between runs.

## Open questions

- (After MVP) Should the Unity prototype's test jump on Space carry over? (Unity prototype report, section 9.)
- (After MVP) Should the arrow keys also steer? The Unity prototype's README says they do, but its code doesn't read them.
- (After MVP) Should gamepad support carry over (triggers as on/off, analog stick steering)?
- (After MVP) Does the board remember a version of the Unity prototype whose camera rotated with the car? An old saved setting suggests one existed; the current version's camera never rotates.
- (After MVP) Far-future idea: a trick system for the car (front flips, back flips, in the style of Olli Olli World). Long-term only.

## References

- Unity prototype report: [drifting/unity-prototype-report.md](drifting/unity-prototype-report.md).
- Godot drift prototype: [../game/README.md](../game/README.md), section "Drift prototype".

- **Garage acceleration upgrade (T-060):** at the start of a run (not in the drift prototype) the car's time to top speed is the acceleration upgrade's value at the player's saved level (Garage design). Level 0 is the base 2.3 s, so the car is unchanged until the player buys it. How it is applied: `game/README.md`, "Saving and buying".
