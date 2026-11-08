# Frame 19, style loop version 4 (v4-3.png), 2026-11-08

- No PixelLab call (the evaluator said none was needed). Frame-19 budget: 2 of 4 used; ticket 9 of 28.
- Free fixes on v3 (`fixes/frame19_v3_e_centred.png` = v3-3.png), new subcommand `reshadow` in
  `game/tools/car_frame_check.py` (strip_shadow, smooth_edge, cast_shadow; tests in `test_car_frame_check.py`, 15 OK):
  1. `reshadow --dx -1 --dy 4 --smooth-edge 1 --smooth-shadow 2` -> `fixes/frame19_v4_a_reshadow.png`:
     the old /rotate shadow (533 px after v3's extension, blobby) stripped; the car's silhouette tidied (3 spike
     pixels off the left flank and wheel, 2 notches filled in the outline colour); a new shadow cast from the
     car's own silhouette offset like frame 18's (1 px left, 4 px down; 400 px of (10,4,31)), edge rounded.
     The neighbours' shadows could not be pasted as such: frame 18's body is 17 px wider and its shadow would
     float beside this car. A straight-down 3 px variant (`frame19_v4_a2_reshadow_0_3.png`, 280 px) was made and
     left aside: `screenshots/frame19_v4_shadow_compare_dark.png` (18, v3, -1/+4, 0/+3, 20) shows the -1/+4 one
     closest to frame 18's.
  2. `fix` (no shadow) -> `fixes/frame19_v4_b_fix.png`: outline closed round 2 more mid-tone edge pixels; one
     island, no strays; non-dark edge share 0.4% (one bright highlight pixel, allowed).
  3. `centre` (1, 2) -> `fixes/frame19_v4_c_centred.png`, copied unchanged to `style-loop/v4-3.png`.
- Not fixed, by design: the body reads a little shorter than 18 and 20 because this heading (between a
  three-quarter and a near-rear view) foreshortens it; stretching pixels would invent art. The roof's darker
  green is the palette shade /rotate chose for this heading; the stripes and highlights match the neighbours.
- Verify on the result: 31 colours, all in the approved palette, centring (0, 0), angle 225.3 by the tool
  (unchanged since v2; see v2-4-notes.md). Stats: 4860 opaque px, bbox 94 x 78, shadow 401 px (frame 18: 441).
- Checked by eye: `screenshots/frame19_v4_strip.png` (17, 18, v4, 20, 21), `frame19_v4_zoom_light.png` (18, v4, 20),
  `frame19_v4_left_before_after.png` (v3, v4 silhouette).
