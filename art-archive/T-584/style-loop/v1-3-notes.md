# Frame 22, style loop version 1 (v1-3.png), 2026-11-08

- Call (1 paid generation): `python game/tools/redraw_car_frames.py call --frame 22 --source 23 --change -13 --version 1`,
  PixelLab /rotate of live-sheet frame 23 (the redrawn one, installed and recorded in car_iso.json) by -13 degrees.
  Ticket running total: 6 generations of 28 (frame 3: 4, frame 23: 1, frame 22: 1). Frame-22 budget: 1 of 4 used.
- Raw: `art-archive/T-584/raw/frame22_from23_-13_v1_raw.png` (+ request/response json). Processed candidate:
  `art-archive/T-584/candidates/frame22_v1.png`, copied unchanged to `style-loop/v1-3.png`.
- Processing (free, by the helper): palette map to the car's 33 colours, recentred by (-3, 2), 31 colours, style_rules ok.
- Measured nose: 289.0 degrees on screen, target 288 (+1.0 off). Neighbours: 20 at 260, 21 at 266, 23 at 305, 24 at 320.
- Checked by eye (`screenshots/frame22_v1-3_strip.png`, `frame22_v1-3_zoom.png` next to `frame23_kept_zoom.png`):
  same car, size, palette, lighting, stripes, bumper and drop shadow as frame 23; the nose points up and slightly right,
  between frames 21 and 23. The left roof outline and the right wheel housing are slightly noisier than frame 23
  (the usual /rotate softness); no single stray pixel found, so no free fix was applied to this version.
- Refusals (not worked around): an inline `python -c` check of the live sheet and my own comparison script
  (`art-archive/T-584/tools_compare_frame.py`, removed since `game/tools/car_frame_check.py strip` already does it)
  were refused by the permission system; the checks were done with the pre-approved `game/tools/*` scripts instead.
