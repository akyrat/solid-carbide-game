# T-555 brief, the full set: the car's mid-air tilt, 32 directions x 3 frames

What: the tilt of Drifting, Decisions, "The grind overhaul". While the player holds Space in the air, the car tilts: its
own **front left wheel goes down and its back right wheel goes up**, about the diagonal through its front right and
back left wheels. A tilt, not a turn: in every direction the car keeps facing the same way. Step 1, 2 and 3 grow to
the held pose (10, 20, 30 degrees; eased to as little as 16.5 in the rear views, where the full angle turns the roof
edge-on: `tilt_deg_for` in the tool). Same car (1967 Mustang GT fastback, Greenbull's dark green, two centred white
stripes with a gap), outline, palette and size as the normal frames (`game/art/car/car_iso_noshadow.png`, 32 frames
of 128 x 128, frame i = heading i x 11.25 degrees, frame 0 nose down-right, frame 8 nose down-left), no drop shadow,
transparent background. In the game the frames are drawn at half size and each shows for 0.06 s.

**The version is one row of all 96 frames** (12288 x 128): direction 0 steps 1, 2, 3, then direction 1 steps 1, 2,
3, and so on. It is that wide only for the script checks. **To look at it, open its contact sheet**:
`art-archive/T-555/full-set/v<N>_contact.png` (one row per direction: the normal frame, then steps 1, 2, 3; dark
background left, light right, 2x), made with each version as below.

The sample (direction 8, two loop runs, the earlier `### Run` parts of the Style review) scored 5 at best: the
evaluator read the bigger tilts as a turn or a change of size, and PixelLab's `/rotate` refines smeared the stripes'
gap without fixing that. The guides were then rebuilt (`art-archive/T-555/guides3/`: a 45-degree camera that matches
PixelLab's view better, the volume fitted to each frame's silhouette, the rear views eased so no frame collapses).

## How to make each version (run every command on its own: no `for` loops, pipes, `&&` chains or `;`)

Tool: `game/tools/build_car_tilt.py` (read its docstring). Commands under `python game/tools/` are pre-approved;
other shell commands, ad-hoc scripts and test runs are refused (the Project Lead's session runs the tests).
Frames go in `art-archive/T-555/full-v<N>/` (a new folder per version; never overwrite or delete earlier ones).

- **Version 1 (free, no PixelLab):** the guides as they are.
  1. `python game/tools/build_car_tilt.py copy-guides --dirs all --steps 1,2,3 --guides art-archive/T-555/guides3 --frames-dir art-archive/T-555/full-v1`
  2. the three "every version" commands below.
- **Refines:** start from the previous version's frames, then change only the directions the reason names.
  1. `python game/tools/build_car_tilt.py copy-guides --dirs all --steps 1,2,3 --guides art-archive/T-555/full-v<N-1> --frames-dir art-archive/T-555/full-v<N>`
  2. Free fixes first: a different guide build (you may change `build_car_tilt.py`'s settings, for example
     `AWAY_EASE`, `TILT_STEPS_DEG` or the volume, then `guides --dirs <list> --out art-archive/T-555/guides-v<N>`
     and `copy-guides` from there).
  3. Paid, for the named directions only: `python game/tools/build_car_tilt.py generate-set --dirs <comma list> --steps 2,3 --strength <S> --seed0 558<N>000 --guides art-archive/T-555/guides3 --frames-dir art-archive/T-555/full-v<N> --tag fv<N> --max-calls <M>`
     (PixelLab `/rotate`: the real frame as from_image and color_image, the guide as init_image; one call per frame,
     logged in `art-archive/T-555/pixellab-calls.md`; then the free clean). In the sample, strength 600 to 650
     followed the guide's pose; 400 to 450 lost the tilt.
- **Every version:**
  1. `python game/tools/build_car_tilt.py sheet --frames-dir art-archive/T-555/full-v<N> --out art-archive/T-555/full-set/v<N>_sheet`
  2. `python game/tools/build_car_tilt.py preview art-archive/T-555/full-set/v<N>_sheet.png art-archive/T-555/full-set/v<N>_contact.png`
  3. `python game/tools/build_car_tilt.py strip --dir all --frames-dir art-archive/T-555/full-v<N> --out <the version's path>`
  In `changed`, name the frames folder (`art-archive/T-555/full-v<N>`) and the calls made.
- **Spend:** at most 50 PixelLab calls per refine (`--max-calls`), 150 in this run. 8 were used by the sample.

## What a good version looks like

- In every direction the car reads at a glance as the same car tilting onto its front left corner, the steps growing
  smoothly; the nose keeps pointing the same way.
- No tears, holes, slivers, smears or double edges; outlines closed; stripes continuous with their gap; wheels round.
- The car's own colours only (33 in all), alpha 0 or 255.
