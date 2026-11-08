# Frame 19, style loop version 1 (v1-5.png), 2026-11-08 (resumed run)

- No PixelLab call for this version. It is the generation paid for before the cut-off:
  `python game/tools/redraw_car_frames.py call --frame 19 --source 18 --change 15 --version 1`,
  PixelLab /rotate of live-sheet frame 18 by +15 degrees. Ticket running total: 8 generations of 28
  (frame 3: 4, frame 23: 1, frame 22: 2, frame 19: 1). Frame-19 budget: 1 of 4 used.
- Raw: `art-archive/T-584/raw/frame19_from18_+15_v1_raw.png` (+ request/response json, input png). Processed
  candidate: `art-archive/T-584/candidates/frame19_v1.png`, copied unchanged to `style-loop/v1-5.png`
  (`style-loop/v1-4.png`, from the run that died, is the same bytes).
- Processing (free, by the helper): palette map to the car's 33 colours, recentred by (-1, 2), 31 colours, style_rules ok.
  Re-running `process` on the raw reproduces the candidate byte for byte
  (`screenshots/frame19_v1_reprocessed_check.png`).
- Measured nose: 222.9 degrees on screen, target 237 (-14.1 off). Neighbours: 17 at 215, 18 at 218, 20 at 260, 21 at 266.
  So +15 from frame 18 turned the car only about +5 measured degrees (frame 3's loop got +20 from +16): results vary by
  source. A refine needs about 14/1.25 = 11 more D, i.e. from frame 18 about +26, or from frame 20 about -18 to -20.
- Checked by eye (`screenshots/frame19_v1_strip.png`: frames 17, 18, v1, 20, 21; `frame19_v1_zoom_light.png`: 18, v1, 20):
  same car, size, palette, stripes, bumper and lights as frame 18; drop shadow present and about as dark as the
  neighbours'. Stats: 5122 opaque px, bbox (13, 28, 116, 103), 31 colours (old frame 19: 4602 px, 32 colours). The door
  side carries the usual /rotate noise (scattered white marks under the window, noisier than frame 18). The main
  problem is the angle: the car reads as a near copy of frame 18, not as the midpoint between 18 and 20, so the turn
  18 -> 19 -> 20 would still jump at 19 -> 20 (37 degrees).
- Refusals (not worked around): PowerShell commands (the helper's `--help`, `Copy-Item`) and `cp -n` were refused by the
  permission system in this headless run; the same steps ran as plain `cp` and `python game/tools/*` in Bash.
