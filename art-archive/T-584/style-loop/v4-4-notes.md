# Frame 20, style loop version 4 (v4-4.png), 2026-11-08: the last call, from frame 19 by +23, then the free pass

- Evaluator on v3: 7/10, style fine, only the angle (237 against 254). No script changes a heading, so the frame's
  last call went where the data pointed: a straight line through frame 19's two earlier results (+14 -> +7 measured,
  +30 -> +45) puts the +29 needed at D = 23:
  `python game/tools/redraw_car_frames.py call --frame 20 --source 19 --change 23 --version 4`.
  Usage reported: 1.0 generation. Frame-20 budget: 4 of 4 used (no calls left for this frame). Ticket running total:
  13 generations.
- Raw: `art-archive/T-584/raw/frame20_from19_+23_v4_raw.png` (+ request/response json, input png). Processed candidate:
  `art-archive/T-584/candidates/frame20_v4.png` (palette map, recentred (2, 2), 30 colours, style_rules ok).
- Measured nose: 254.2 degrees on screen, target 254 (+0.2 off); 254.0 after the free pass. Neighbours: 19 at 225,
  21 at 266, so this frame sits 29 from 19 and 12 from 21 by the helper, and by eye evenly between them (see below).
- Free fixes (`game/tools/car_frame_check.py`, each step a new file in `fixes/`): `fix` (118 near-black outline pixels
  added, 0 islands, no shadow change: 113 -> 3 non-dark edge pixels; the raw rotate's outline was as broken as the
  old frame 21's), `polish --contrast 1000 --smooth-shadow 2` (0 specks, 0 spikes, 3 notches filled), `centre` (0, 0).
  Result `fixes/frame20_v4_fix_polish_centred.png` = `style-loop/v4-4.png`: 31 approved colours, style_rules 6/6 ok,
  4796 opaque px, bbox (27, 23, 101, 107) (frame 19: 4767 px), drop shadow 376 px of (10, 4, 31) (frame 19: 369).
- Checked by eye (`screenshots/frame20_v4_strip.png`: 18, 19, old 20, v4, 21, 22 on dark and light;
  `frame20_v4_zoom_light.png`: 19, v4, 21 at x5): same car, size, palette and lighting; two straight stripes with a
  clear gap, a clean windscreen and rear window, crisp bumper, lights and plate; near-black closed outline; shadow as
  dark and deep as frame 19's. In the strip the body tilt steps evenly 19 -> v4 -> 21 -> 22, one smooth turn. The
  body sides keep a little of /rotate's soft shading (it is a rotate of frame 19, itself a rotate), less than v2 had.
