# Brief: Bricks' impact wave (T-325)

What: the impact wave Bricks sends out when the car lands after a jump (docs/weapons.md, Decisions, "Bricks", and Content, "Bricks"): a ring on the ground that grows from the car's size out to the damage radius, with dust and brick chips thrown up, in the City's colours (cool blue-grey, pale white and pale blue; docs/visual-style.md, Decisions, "City colours"), never Greenbull's. It replaces T-324's code-drawn placeholder (`game/scripts/weapons/bricks.gd`, `BricksWave`), with the same timing.

It is drawn by a free script, no PixelLab: `game/tools/build_bricks_wave.py` (read its docstring). The version scored here is the sheet for the first tier's radius, 4 units: one row of 12 stepped frames (0.05 s each; the ring reaches the radius at frame 7, then thins and crumbles away), each frame 384 x 246 art pixels at 32 art pixels per unit, shown at 0.5 in the run, the ground circle drawn as the run's isometric ellipse. The same script then makes the sheets for the other tiers' radii (4.8, 6 and 7.8 units), so the ring is never scaled.

Make the version:

```
python game/tools/build_bricks_wave.py build --radius 4 --out <the version's path>
python game/tools/build_bricks_wave.py preview --png <the version's path> --out art-archive/T-325/wave/preview_v<N>.png
python game/tools/style_rules.py art <the version's path> --frames 12 --size 384x246
```

On a refine: change the script's constants or drawing (colours, band widths, puff and chip sizes, the outline) to fix what the reason names, keep it deterministic, and rebuild. No PixelLab for the wave.

For the evaluator: the frames are an effect, not an object, so "3/4 isometric view" means the ring lies flat on the ground as the isometric ellipse; the ring's glow is drawn as bright pixels with a checker-dithered halo (rule 5); dust is cool grey, chips are brick brown with a navy outline; the background is transparent.

## Run 3 (after a cut-off)

Run 2 of this task's style loop was cut off by a usage limit while version 4 (`art-archive/T-325/style-loop/v4.png`, made by the script as it stands now, after three refines) was waiting to be scored. This run scores it: **version 1 of this run is that version, unchanged**: rebuild it with the script as it is (`build --radius 4 --out <the version's path>`, which gives the same bytes as v4.png) and make its close-ups with `preview --frames 4-5` and `preview --frames 9-11` into `art-archive/T-325/wave/`. Run 2 already used its three refines, so refine in this run only on a reason that names a real rule break, with free script changes.

For the evaluator: the whole sheet is 4608 px wide and is shrunk a lot when viewed whole, so judge the pixel detail from the close-ups at 2x: `art-archive/T-325/wave/preview_v4_closeup_f4-5.png` (the ring at full speed, dust and chips) and `art-archive/T-325/wave/preview_v4_closeup_f9-11.png` (the crumble), or from the newest close-ups the agent names. In the run each art pixel is shown at half a screen pixel, so a chip of 6 to 8 art px is 3 to 4 screen px.
