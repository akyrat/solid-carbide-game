# Frame 22, style loop version 3 (v3-2.png), 2026-11-08: free polish of v2-3, no PixelLab call

Ticket running total stays 6 generations of 28; frame-22 budget 1 of 4 used. The evaluator asked for a call only if
the angle were off; v2-3 measured 289.5 against 288, so no call.

## New free tool (code, with tests)

`game/tools/car_frame_check.py polish CANDIDATE --out PNG [--contrast 60] [--drop-rows N --band y0,y1]
[--smooth-shadow PASSES]`, three functions, each tested in `game/tools/test_car_frame_check.py` (8 tests, all pass,
run in the foreground: `python -m unittest discover -s game/tools -p test_car_frame_check.py`):

- `despeckle`: an interior opaque pixel (6+ opaque 8-neighbours) with no neighbour of its own colour, whose
  brightness differs from the neighbours' majority colour by more than the contrast, takes that colour. Runs of two
  or more same-coloured pixels (stripe edges, panel lines, highlights) are never touched.
- `drop_rows`: removes the N rows in the band most like the row above them (flat shading), rows above the cut move
  down; the bottom and the shadow stay put.
- `smooth_shadow`: a shadow-colour pixel with at most one opaque 4-neighbour goes transparent (spike); a transparent
  pixel with three or more opaque 4-neighbours, all shadow-coloured or near-black, takes the shadow colour (notch).

## What v3-2 changed (from v2-3; `polish --drop-rows 3 --band 30,100 --smooth-shadow 2`, then `centre`)

- Specks: 215 lone pixels replaced by their surrounding colour (the bright and dark specks in the dark-green door,
  flank and wheel area the reason names). A stricter run (contrast 100, 140 specks, `fixes/frame22_v2_polish_b_c100.png`)
  looks the same, so no shading was lost; the kept one is contrast 60 (`fixes/frame22_v2_polish_a.png`).
- Size: 3 rows dropped (y 37, 53, 48 of v2-3), so the body is 82 rows tall (y 22-103), the same as frame 23 (82) and
  frame 20 (82); width unchanged (76, between old 22's 62 and frame 23's 85).
- Shadow: 5 notches filled, 0 spikes; the shadow stays 4 px below the body in the sheet's shadow colour (10, 4, 31).
- Recentred by the helper's rule: shift (0, -1); `process` would now apply (0, 0).
- Outline: still closed (1% of edge pixels non-dark, 3 bright highlights break it as rule 2 allows).

## Verified

- `verify --frame 22`: 31 colours, all approved; nose 291.7 degrees on screen, target 288 (+3.7 off; v2-3 read 289.5,
  dropping rows squashes the body a little). Between frame 21 (266) and frame 23 (305), nearer 288 than either.
- `screenshots/frame22_polish_a_strip.png`: frames 20, 21, NEW 22, 23, 24 (dark and light).
- `screenshots/frame22_polish_a_zoom_light.png`: v2-3, NEW, kept 23 at x5.
- `screenshots/frame22_polish_a_vs_b_zoom.png`: contrast 60 vs 100 at x6.

## Not changed

The windscreen (flat pink with a black diagonal) is the same on frame 23 and old 22: the sheet's look. The wheels keep
v1's shapes; only lone pixels around them were replaced.
