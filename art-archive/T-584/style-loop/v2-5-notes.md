# Frame 20, style loop version 2 (v2-5.png), 2026-11-08

- Evaluator on v1: 4/10, the angle (232 measured, target 254). No free fix can change the car's world heading (a 2D
  rotation of the PNG is not an isometric turn), so this version is the paid refine the reason asks for:
  `python game/tools/redraw_car_frames.py call --frame 20 --source 19 --change 30 --version 2`,
  PixelLab /rotate of live-sheet frame 19 by +30 degrees. Usage reported: 1.0 generation. Frame-20 budget: 2 of 4 used.
  Ticket running total: 11 generations.
- Raw: `art-archive/T-584/raw/frame20_from19_+30_v2_raw.png` (+ request/response json). Processed candidate:
  `art-archive/T-584/candidates/frame20_v2.png`, copied unchanged to `style-loop/v2-5.png`.
- Processing (free, by the helper): palette map to the car's 33 colours, recentred by (3, 2), 30 colours, style_rules ok.
- Measured nose: 270.4 degrees on screen, target 254 (+16.4 off). Overshoot: +30 from frame 19 (225) turned the car
  about +45 measured degrees, where +14 turned it only +7. /rotate's yield per D is not linear and not 1.25 here:
  under about 15 it barely turns, around 30 it snaps to the next "clean" view (straight up, like frame 22 at 270).
- Checked by eye (Read of `v2-5.png` and the raw): same car, size, palette, stripes, lights, windows; drop shadow present.
  But the car points straight up, i.e. it is a near copy of frame 22's heading, not the midpoint between 19 and 21, so
  19 -> 20 would jump 45 degrees and 20 -> 21 -> 22 would stall.
- Options for a refine (one call, at most 2 left): from frame 19 with D about 22-24 (between the two yields seen, so a
  guess); from frame 21 (266) with D about -14 (12 measured degrees needed, D at the lower edge of what turns the car);
  from frame 22 (270) with D about -20. The old frame 20 (260) would need -6, under 10, so no call from it.
