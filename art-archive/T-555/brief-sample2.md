# T-555 brief, round 2: the car's mid-air tilt, sample direction 8 (3 frames)

What: the tilt of Drifting, Decisions, "The grind overhaul". While the player holds Space in the air, the car tilts: its
own **front left wheel goes down and its back right wheel goes up**, a tilt about the car's diagonal (the line through
its front right and back left wheels). It is a tilt, not a turn: the car keeps facing the same way. 3 frames go from
the normal car to the held pose: step 1 (10 degrees), step 2 (20), step 3 (the held pose, 30 degrees). The tilt must
read clearly at a glance (round 1's 20-degree hold was too subtle).

The sample is direction frame 8 (`game/art/car/car_iso_noshadow.png`, x 1024 to 1151; the board's first approved car
frame): the nose points down-left on screen and we see the car's **left** side. The front left wheel is the front
wheel nearest the viewer (bottom left of the sprite): that corner goes **down** the screen. The back right wheel is the
hidden far rear wheel (top right): that corner goes **up**, so more of the roof and boot show and the car's top tips
towards the viewer's lower left. Same car (1967 Mustang GT fastback, Greenbull's dark green, two centred white stripes
with a gap), same outline, palette and size as the normal frame, no drop shadow, transparent background.

The version is a one-row sheet of the 3 frames, 384 x 128 (steps 1, 2, 3 left to right), centred like the guides.

Round 1 (the earlier `### Run 1` in the Style review) failed because its pose guides tore at the raised corner. The
guides are rebuilt (free): `art-archive/T-555/guides2/dir08_step1.png` to `step3.png`. Each is the real frame warped
in 3D with the car-shaped volume fitted to the frame's own silhouette, moved forward pixel by pixel with depth, so the
raised part covers what is behind it: no tears, only the car's own pixels.

## How to make each version (run every command on its own: no `for` loops, pipes, `&&` chains or `;`)

The tool is `game/tools/build_car_tilt.py` (read its docstring and `generate-set`). Commands under `python game/tools/`
are pre-approved; other shell commands and ad-hoc scripts are refused, and so are test runs (the Project Lead's
session runs them; don't try).

- **Version 1 (free):** `python game/tools/build_car_tilt.py strip --dir 8 --frames-dir art-archive/T-555/guides2 --out <the version's path>`
- **Refines (paid, PixelLab `/rotate`):** `from_image` and `color_image` = the real frame, `init_image` = the guide.
  1. Free first, if it fits: `python game/tools/build_car_tilt.py copy-guides --dirs 8 --steps 1 --frames-dir art-archive/T-555/frames2-v<N>`
     (a step whose guide is already clean needs no paid call).
  2. `python game/tools/build_car_tilt.py generate-set --dirs 8 --steps 2,3 --strength <S> --seed0 557<N>00 --frames-dir art-archive/T-555/frames2-v<N> --tag r2v<N> --max-calls 3`
     It writes each request, makes one `pixellab_client.py generate` call per missing frame (raw in
     `art-archive/T-555/raw/`), logs every call in `art-archive/T-555/pixellab-calls.md`, and cleans the frames for
     free (the car's palette, alpha cut, specks removed, centred like the guide). A different `--strength` or `--tag`
     gives new names; the client never overwrites.
  3. `python game/tools/build_car_tilt.py strip --dir 8 --frames-dir art-archive/T-555/frames2-v<N> --out <the version's path>`
- `init_image_strength`: the guide is now clean and is the real car, so follow it more than in round 1: start around
  550; lower it (450) if PixelLab copies the guide's warp artefacts, raise it (650) if the tilt comes out weaker than the
  guide. Round 1 at 400 lost much of the tilt.
- To look at a frame enlarged: `python game/tools/art_preview.py <png> <out png> --scale 4`.
- **Spend:** at most 3 PixelLab calls per version. Never delete or overwrite generated art.

## What a good version looks like

- Reads at a glance as the same car tilted onto its front left corner, steps growing smoothly, no turn: the nose still
  points down-left, the same side shows.
- No tears, holes, smears or double edges; the outline closed; the stripes continuous; the wheels round.
- The car's own colours only (it has 33 in all; the approved frame 8 has 33), alpha 0 or 255.
