# Frame 20, style loop version 1 (v1-6.png), 2026-11-08

- One PixelLab call, the one the brief prescribes:
  `python game/tools/redraw_car_frames.py call --frame 20 --source 19 --change 14 --version 1`,
  PixelLab /rotate of live-sheet frame 19 (the redrawn one, `redrawn_by: T-584` in car_iso.json) by +14 degrees.
  Usage reported: 1.0 generation. Frame-20 budget: 1 of 4 used. Ticket running total: 10 generations
  (frame 3: 4, frame 23: 1, frame 22: 2, frame 19: 2, frame 20: 1), counted from the candidates folder.
- Raw: `art-archive/T-584/raw/frame20_from19_+14_v1_raw.png` (+ request/response json). Processed candidate:
  `art-archive/T-584/candidates/frame20_v1.png`, copied unchanged to `style-loop/v1-6.png`.
- Processing (free, by the helper): palette map to the car's 33 colours, recentred by (0, 5), 30 colours, style_rules ok.
- Measured nose: 232.3 degrees on screen, target 254 (-21.7 off). Neighbours: 18 at 218, 19 at about 225 (seen),
  21 at 266, 22 at 270. So +14 from frame 19 turned the car only about +7 measured degrees: the same lesson as
  frame 19's v1 (+15 from frame 18 gave +5) and frame 3's loop (D under about 10 barely turns the car, and the yield
  per D varies by source). A refine needs about 21.7/1.25 = 17 more D: from frame 19 about +30, or from the old
  frame 20 (260 measured) about -6, which is under 10 and so not worth a call; from frame 21 (266) about -10 to -12,
  also marginal. Best bet: frame 19 with +30.
- Checked by eye (Read of `v1-6.png`, `frames/frame19.png`, `frames/frame22.png`, the raw): same car, size, palette,
  stripes, lights and windows as frame 19; drop shadow present but fainter than frame 19's, outline slightly noisier
  (the usual /rotate noise). The main problem is the angle: the car reads as a near copy of frame 19 pointing up-left,
  not as a car pointing almost straight up (254), so the turn 19 -> 20 -> 21 would still jump at 20 -> 21.
- Refusals (not worked around): the permission system refused running
  `python art-archive/T-584/tools_compare_frame20.py ...` (a free comparison-strip script, written for this frame
  on the pattern of `tools_compare_frame03.py`); no comparison strip was made for v1, the frames were viewed one by one.
