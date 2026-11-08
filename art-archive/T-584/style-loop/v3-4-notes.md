# Frame 20, style loop version 3 (v3-4.png), 2026-11-08: one paid call from the original frame 20, then free fixes

- Evaluator on v2: 6/10 (soft windscreen, noisy outline, smaller body and fainter shadow than frame 21, pose like
  frame 21's; the helper had it at 270.4 against 254). The angle cannot be fixed free, and v2's softness is that of a
  /rotate of an already-rotated frame (frame 19 is itself a rotate of the old frame 20), the same lesson as frame 22's
  loop. So this version's one call went back to an original source: the old frame 20 on the live sheet, a
  generate-8-rotations original ("north", seen 260), the only crisp source near the target:
  `python game/tools/redraw_car_frames.py call --frame 20 --source 20 --change -10 --version 3`
  (D = -10 is the smallest the brief allows; a change under 10 is not to be spent). Usage reported: 1.0 generation.
  Frame-20 budget: 3 of 4 used. Ticket running total: 12 generations.
- Raw: `art-archive/T-584/raw/frame20_from20_-10_v3_raw.png` (+ request/response json, input png). Processed candidate:
  `art-archive/T-584/candidates/frame20_v3.png` (palette map, recentred (0, 2), 31 colours, style_rules ok).
- Measured nose: 237.1 degrees on screen, target 254 (-16.9 off). -10 from the original turned the car about -23
  measured degrees (2.3 per D; the same source gave -35 for -20 when frame 19 was made). Yields so far for this
  frame: frame 19 +14 -> +7, frame 19 +30 -> +45, old 20 -10 -> -23: nothing near the 1.25 per D of frame 3's loop.
- Free fixes (all `game/tools/car_frame_check.py`, every step a new file in `fixes/`):
  `fix` (46 near-black outline pixels added, 0 islands, no shadow change: 40 -> 4 non-dark edge pixels, frame 19 has 28,
  the old frame 20 26, frame 21 113), `polish --contrast 1000 --smooth-shadow 2` (0 specks, 1 shadow spike removed,
  11 notches filled), `centre` (1, 0). Result `fixes/frame20_v3_fix_polish_centred.png` = `style-loop/v3-4.png`:
  31 approved colours, style_rules all ok, 4577 opaque px, bbox (22, 24, 105, 106), angle unchanged at 236.9.
- Checked by eye (`screenshots/frame20_v3_strip.png`: frames 18, 19, old 20, v3, 21, 22 on dark and light;
  `frame20_v3_zoom_light.png`: 19, v3, 21 at x5; `frame20_v3_raw_vs_fixed_zoom.png`: before and after the free fixes):
  crisp like the original it came from: clean windscreen and rear window, two straight stripes with a clear gap,
  sharp bumper, lights and plate; same size as the old frame 20 (4521 vs 4496 px) and the same drop shadow colour and
  depth as frame 19 (403 shadow px of (10, 4, 31); frame 19: 369). By eye the body tilt sits between frame 19 and
  frame 21, nearer 19 than the helper's 237 suggests is even; the helper's number is the brief's criterion.
- If a 4th version is needed (1 call left): the old frame 20 responds strongly (-10 gave -23), so a smaller D from it
  would be the natural fix but is under the brief's 10 floor; from frame 19 the yield jumps between +7 (D 14) and
  +45 (D 30), so D about 20 is a guess; from the old frame 21 (266, soft, needs -12) D about -14. Best guess under the
  brief's rules: frame 19 with +20, then the same free pass.
