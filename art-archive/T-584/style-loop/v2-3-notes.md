# Frame 22, style loop version 2 (v2-3.png), 2026-11-08: free fix of v1-3, no PixelLab call

Ticket running total stays 6 generations of 28; frame-22 budget 1 of 4 used.

## What the numbers said about the v1 reason (checked before fixing)

| frame | body bbox height | edge non-dark share | shadow rows below body |
|---|---|---|---|
| old 21 (live) | 74 | 46% | 0 |
| old 22 (live, 270) | 75 | - | 8 |
| v1-3 | 84 | 15% | 3 |
| kept 23 (redrawn, 305) | 82 | 0.7% (closed by the same fix) | 4 |

So v1-3 is 2 px taller than its redrawn neighbour, not 20%; one connected sprite, no stray islands. The real gaps were
the broken outline and the thin drop shadow.

## What v2-3 changed (free, `game/tools/car_frame_check.py fix` then `centre`, frame 23's recipe)

- Outline (rule 2): every mid-tone edge pixel now has a near-black (6, 2, 27) outline pixel outside it; bright
  highlights (3 pixels) still break it as the rule allows. 51 outline pixels added. Edge non-dark share 15% -> 1%.
- Drop shadow: the body's silhouette shifted down 4 px in the sheet's shadow colour (10, 4, 31), only where the frame
  was transparent (353 pixels). Old 22 reaches 8 px below the body, kept 23 reaches 4, so 4 matches the redrawn
  neighbour. Shadow now reaches 7 rows below the body (104 -> 111).
- Recentred by the helper's rule: shift (0, -2); `process` would now apply (0, 0).
- Not changed: every car pixel of v1-3 (body, stripes, windows, wheels), the palette (31 approved colours).

## Verified

- `verify --frame 22`: 31 colours, all approved; nose 289.5 degrees on screen, target 288 (+1.5 off), between
  frame 21 (266) and frame 23 (305).
- `screenshots/frame22_v2-3_strip.png`: frames 20, 21, old 22, NEW 22, 23, 24 (dark and light).
- `screenshots/frame22_v2-3_zoom_light.png`: old 22, NEW 22, kept 23 at x5.

## Not fixed (would need a paid call, which the loop decides)

The hood stripes below the windscreen are slightly smeared (the usual /rotate softness). The flat pink windscreen
with its black diagonal is the same on frame 23 and the old 22, so it is the sheet's look, not a defect.
