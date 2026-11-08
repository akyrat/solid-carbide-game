# Frame 19, style loop version 2 (v2-4.png), 2026-11-08

- Why a call: v1 measured 222.9 (target 237), under the evaluator's 230 line, and a free fix cannot turn a car.
  From frame 18, +15 had turned it only about +5, so this refine turned from the other neighbour instead.
- Call (1 paid generation): `python game/tools/redraw_car_frames.py call --frame 19 --source 20 --change -20 --version 2`,
  PixelLab /rotate of live-sheet frame 20 (at 260) by -20 degrees. Ticket running total: 9 generations of 28
  (frame 3: 4, frame 23: 1, frame 22: 2, frame 19: 2). Frame-19 budget: 2 of 4 used.
- Raw: `art-archive/T-584/raw/frame19_from20_-20_v2_raw.png` (+ request/response json, input png). Processed by the
  helper (palette map, recentred by (1, 4), 31 colours, style_rules ok): `candidates/frame19_v2.png`.
- Measured nose of the candidate: 225.3 degrees on screen, target 237 (-11.7 off). Note that the same measure reads
  the live frames low in this range (`measure_car_facing.py --frames 17-21`: 18 recorded 218 measured 210.6,
  20 recorded 260 measured 240.2), so by the tool v2 sits about a quarter of the way from 18 to 20.
  By eye it sits about halfway: bbox 92 x 79 against frame 18's 109 x 74 and frame 20's 80 x 82, nose up-left, tail
  lower right, the rear window a trapezoid between 18's sliver and 20's full pane
  (`screenshots/frame19_v2_fix_b_strip.png`: 17, 18, v2, 20, 21; `frame19_v2_fix_b_zoom_light.png`: 18, v2, 20).
- Free fixes (new subcommands in `game/tools/car_frame_check.py`, tests in `test_car_frame_check.py`, 12 OK):
  - `specks --colour 246,221,248 --colour 210,202,246`: 24 lone rear-window pink and lilac pixels on the roof and
    stripes took their neighbours' majority colour; the window itself and the 2-pixel-plus chrome runs are untouched
    (`fixes/frame19_v2_fix_a_specks.png`).
  - `recolour --from 12,10,33 --to 10,4,31`: /rotate had snapped the whole outline and drop shadow to the lightest
    near-black of the palette (1304 px of (12,10,33) where frame 18 uses (10,4,31) for 1312 px); 1311 px recoloured,
    so outline and shadow are now frame 18's shade. Shadow: 369 px of (10,4,31) (frame 18: 441, frame 20: 216)
    (`fixes/frame19_v2_fix_b_dark.png`, copied unchanged to `style-loop/v2-4.png`).
  - `verify --frame 19` on the result: 30 colours, all in the approved palette, centring (0, 0), angle unchanged 225.3.
    Edge report: 255 edge px, 11% not dark, the same share as frame 20; one island (no strays).
- Before/after: `screenshots/frame19_v2_raw_vs_fix_b_zoom.png`.
- Refusals (not worked around): `cd game/tools && python -m unittest ...` was refused; the tests ran as
  `python game/tools/test_car_frame_check.py` from the repo root, which is the pre-approved form.
- If the evaluator still finds the angle short: version 3 would be one call from frame 20 by about -28 to -30
  (the tool's -11.7 miss at about 1.25 measured degrees per D), then the same two free fixes.
