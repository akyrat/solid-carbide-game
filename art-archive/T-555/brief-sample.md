# T-555 brief: the car's mid-air tilt, sample direction 8 (3 frames)

What: the tilt of Drifting, Decisions, "The grind overhaul". While the player holds Space in the air, the car tilts: its
own **front left wheel goes down and its back right wheel goes up**, a tilt about the car's diagonal (the line through
its front right and back left wheels). It is a tilt, not a turn: the car keeps facing exactly the same way. 3 frames go
from the normal car to the held pose: step 1 (a little, 7 degrees), step 2 (14), step 3 (the held pose, 20 degrees).

The sample is direction frame 8 of the car (`game/art/car/car_iso_noshadow.png`, frame 8, x 1024 to 1151; the
board's first approved car frame, `car_sw_front`): the nose points down-left on screen, we see the car's **left**
side. So the front left wheel is the front wheel nearest the viewer (bottom left of the sprite): that corner goes
**down** the screen. The back right wheel is the hidden far rear wheel (top right): that corner goes **up**. The
roof leans a little towards the lowered corner. Same car (1967 Mustang GT fastback, Greenbull's dark green, two
centred white stripes with a gap), same outline, palette and size as the normal frame, no drop shadow (it is drawn
in the air), on a transparent background.

The version is a one-row sheet of the 3 frames, 384 x 128 (each 128 x 128, steps 1, 2, 3 left to right), the car's
centre where the normal frame has it.

## How to make each version (tools are written and tested; run them from the repo root)

`game/tools/build_car_tilt.py` (read its docstring). The pose guides for every direction and step are already built
(free): `art-archive/T-555/guides/dir08_step1.png` to `step3.png`, the real car warped in 3D by the tilt.

- **Version 1 (free, no PixelLab):** the guides themselves:
  `python game/tools/build_car_tilt.py strip --dir 8 --frames-dir art-archive/T-555/guides --out <the version's path>`
- **Refines (paid, PixelLab `/rotate`, T-157's method):** `from_image` and `color_image` = the real frame, `init_image`
  = the guide (the pose), same direction, no turn. For each step:
  1. `python game/tools/build_car_tilt.py request --dir 8 --step S --strength N --seed 5550SS --out art-archive/T-555/requests/<name>.json`
  2. `python game/tools/pixellab_client.py generate --endpoint rotate --params-file art-archive/T-555/requests/<name>.json --out-dir art-archive/T-555/raw --name <name> --consulted docs/visual-style.md --consulted docs/extended-narrative.md --consulted docs/drifting.md --consulted art-archive/T-555/guides --task T-555`
  3. `python game/tools/build_car_tilt.py clean art-archive/T-555/raw/<name>.png art-archive/T-555/frames-v<N>/dir08_step<S>.png --dir 8 --step S`
     (free: alpha cut, the car's palette, specks removed, centred like the guide)
  Then `strip --dir 8 --frames-dir art-archive/T-555/frames-v<N> --out <the version's path>`. A step whose guide is
  already good can be copied from the guides instead of generated (a free fix comes first).
  `init_image_strength`: T-157 found 300 ignores the pose and 600 copies the guide; the guide here is the real car, so
  start at 450 for step 3, and use the reason to move it. Names: `d08_s<S>_st<N>_v<version>` (the client refuses to
  overwrite, so every name is new). Seeds 555001 upwards, a new one per call.
- **Free fixes first:** if the reason names something a script can fix (colours, specks, centring, a seam in a guide),
  fix it with the script (you may change `build_car_tilt.py`, keeping its tests passing:
  `python -m unittest game/tools/test_build_car_tilt.py`) before paying.
- **Spend:** at most 6 PixelLab calls per version (the ticket's go is 200 for all 32 directions; this sample should use
  15 at most in all). Before each call, append one line to `art-archive/T-555/pixellab-calls.md`:
  `| <name> | dir 8 | step S | strength N | seed | version N | why |`; after it, add the result in a word. Never delete
  or overwrite generated art. HTTP timeout is the client's 600 s; no retries of a failed call.

## What a good version looks like

- Reads at a glance as the same car tilted onto its front left corner, steps growing smoothly, no turn.
- No tears, holes, smears or double edges; the outline closed; the stripes continuous; the wheels round.
- The car's own colours only (it has 33 in all; the approved frame 8 has 33), alpha 0 or 255.
