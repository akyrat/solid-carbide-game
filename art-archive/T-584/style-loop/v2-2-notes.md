# T-584, frame 23, style loop: notes for the evaluator

Versions of frame 23 are `v1-2.png`, `v2-2.png`, ... (the `-2` is the loop's suffix; `v1.png`..`v4.png` are frame 3's).

## How to read the heading

Frames 21 to 25 show the car from behind: the rear bumper with the lit rear lights is the NEAR end (low on screen),
the nose is the FAR end (high on screen). So the nose angle is the direction from the rear bumper to the roof's far end.
Frame 22 (270): nose straight up. Frame 24 (320): nose up and to the right. The new frame 23 must sit between them.

Measured by the helper (`game/tools/redraw_car_frames.py`, calibrated body axis, degrees clockwise from screen right):

| version | made by | nose angle (target 305) | colours | style rules |
|---|---|---|---|---|
| v1-2 | 1 paid /rotate of live frame 24 by -14, processed | 305.2 | 32 | ok |
| v2-2 | free script fix of v1-2 (no PixelLab call) | 305.9 | 32 | ok |

The helper's angle takes the end of the body axis nearer the target, so look at the strips below to confirm which
end is the rear (the lit bumper): in both versions the bumper is lower-left and the nose upper-right.

## Enlarged strips (frames 21, 22, old 23, NEW 23, 24, 25; dark and light rows)

- v1-2: `art-archive/T-584/screenshots/frame23_v1_strip.png`
- v2-2: `art-archive/T-584/screenshots/frame23_v2-2_strip.png`
- v2-2 zoomed x6 beside frames 22 and 24: `art-archive/T-584/screenshots/frame23_fix_a_zoom_light.png`, `..._dark.png`

## What v2-2 fixed (free, `game/tools/car_frame_check.py fix` then `centre`)

- Outline (rule 2): v1-2's edge was 51% non-dark pixels (frame 22: 17%, frame 24: 15%); every mid-tone edge pixel
  now has a near-black (6, 2, 27) outline pixel outside it, bright highlights (2 pixels) still break it.
  139 outline pixels added. No stray islands were found (one connected sprite).
- Drop shadow: the body's silhouette shifted down 4 px in frame 22's shadow colour (10, 4, 31), only where the
  frame was transparent (372 pixels); frame 22's shadow reaches 8 px below its body, frame 24 has almost none, so 4 is
  between them.
- Recentred by the helper's rule (bbox centre to the reference's): shift (0, -2) after the shadow.
- Not changed: every car pixel of v1-2 (body, stripes, windows, wheels), the palette (32 approved colours).
