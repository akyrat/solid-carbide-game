# Frame 19, style loop version 3 (v3-3.png), 2026-11-08

- No PixelLab call: the evaluator accepted v2's angle and named only pixel flaws, all fixed by free scripts on
  `fixes/frame19_v2_fix_b_dark.png` (= v2-4.png). Frame-19 budget still 2 of 4 used; ticket 9 of 28.
- Chain (every step a new file in `art-archive/T-584/fixes/`, `game/tools/car_frame_check.py`, tests 13 OK):
  1. `fix --shadow-dy 2 --shadow-dx 1` -> `frame19_v3_b_fix.png`: closed the outline round 32 mid-tone edge pixels
     (left flank, front wheel arch: non-dark edge share 11% -> 0.4%, frame 20's is 11%), no stray islands, and
     deepened the drop shadow by 2 rows down and 1 column right (369 -> 560 px of (10,4,31); frame 18 has 441 with
     a bigger body). A 1-row version (`frame19_v3_b2_fix_dy1.png`) was made for comparison and left aside:
     `screenshots/frame19_v3_shadow_dy_compare_dark.png` (18, 2 px, 1 px, 20) shows the 2 px one matching frame 18's depth.
  2. Window glare, two `recolour --diag` bands on the pink pane (x 69-77, y 56-68) so it fades along the iso
     diagonal like a reflection instead of a flat triangle: x+y 134-136 -> lilac (210,202,246), 22 px
     (`frame19_v3_c1_glare.png`); x+y 137-141 -> (158,154,204), 18 px (`frame19_v3_c2_glare.png`). 39 px of pink
     stay at the top-left of the pane (frame 20's pane is all pink, frame 18's window has no pink). Frame 20 itself
     is not touched here: it gets its own redraw in this ticket.
  3. `recolour --from 54,180,139 --to 83,242,187 --next-to 54,180,139` -> `frame19_v3_d_highlights.png`: the
     mid-cyan ridge runs (27 px, pixels with a same-coloured neighbour; 12 lone ones kept) took the bright cyan
     the neighbours use for their lit ridges (bright cyan 9 -> 36 px; frame 18: 54, frame 20: 60).
  4. `centre` -> `frame19_v3_e_centred.png`: the deeper shadow had moved the bbox, so the helper's whole-pixel
     centring (0, -1) was applied; copied unchanged to `style-loop/v3-3.png`.
- `polish` (despeckle) was tried first (`frame19_v3_a_polish.png`) and NOT used: it would have replaced 206 lone
  pixels, most of them the highlights the evaluator wants more of.
- Verify on the result: 31 colours, all in the approved palette, centring (0, 0), one island, angle unchanged 225.3
  by the tool (see v2-4-notes.md on why the tool reads this range low; by eye the car sits midway between 18 and 20).
- Checked by eye: `screenshots/frame19_v3_strip.png` (17, 18, v3, 20, 21), `frame19_v3_zoom_light.png` (18, v3, 20),
  `frame19_v3_window_compare.png` (18, v2, v3, 20), `frame19_v3_left_before_after.png` (v2, after step 1).
- Tool additions this version (`car_frame_check.py`): `colours`, `specks`, `recolour` (`--shadow-only`, `--box`,
  `--next-to`, `--diag`), `find`; tests in `test_car_frame_check.py`.
