# Frame 22, style loop version 4 (v4-2.png), 2026-11-08: one paid call from frame 24, then the free outline and shadow

Ticket running total: 7 generations of 28 (frame 3: 4, frame 23: 1, frame 22: 2). Frame-22 budget: 2 of 4 used.
This is the loop's last version (3 refines).

## Why a call

The angle of v3-2 was confirmed (291.7 against 288, between frame 21 at 266 and frame 23 at 305; the evaluator's
"frames 23 (273) and 24 (320)" are the wrong neighbours: frame 22 sits between 21 and 23). The free passes were all in
(closed outline, 4 px shadow like frame 23, despeckle, height matched). What the reason still named (stripes breaking
up near the rear window, muddy shading, soft bumper details) is the softness of a /rotate of an already-rotated frame
(v1 came from frame 23, itself a rotate of 24), which no script repairs. So the last refine went back to an original
source: `call --frame 22 --source 24 --change -27 --version 2` (frame 24 is a generate-8-rotations original, the
source of the kept frame 23; the expected 1.07-1.25 measured degrees per D put -27 at 286-291).

Raw: `raw/frame22_from24_-27_v2_raw.png`; processed candidate `candidates/frame22_v2.png` (30 colours, shift (-6, 2),
style_rules ok). Measured 280.0: this call turned 40 degrees for D = -27 (1.48 per D), more than the earlier calls.

## What v4-2 is

`candidates/frame22_v2.png` with the free `fix --shadow-dy 4` (148 near-black outline pixels, 310 shadow pixels in
(10, 4, 31)), then `polish --contrast 1000 --smooth-shadow 2` (no despeckle: a despeckle pass, tried as
`fixes/frame22_v2cand_polish_a_centred.png`, blunted this crisp candidate, so it was not used; 2 shadow spikes
removed, 2 notches filled), then `centre` (0, -2). 31 approved colours, outline closed (0 non-dark edge pixels),
shadow 4 px below the body, body 82 rows tall (frame 23: 82), 66 wide (old 22: 62, frame 23: 85).

## The trade-off, for the Project Lead and the board

| version | heading (target 288) | from 21 (266) / to 23 (305) | finish |
|---|---|---|---|
| v3-2 (from 23 by -13, free fixes) | 291.7 (+3.7) | 26 / 13 | soft: stripes break near the rear window, muddy shading |
| v4-2 (from 24 by -27, free fixes) | 280.1 (-7.9) | 14 / 25 | crisp: clean stripes and gap, sharp bumper, lights, plate |

Both are equally uneven between the current neighbours, mirrored; v3-2 is nearer the target, v4-2 is the better
drawing of the car and the one most likely to meet the style guide. Neither is on target. In the strip
(`screenshots/frame22_v4-2_strip.png`) v4-2 reads nearly end-on, like the old frame 22 (270) but turned 10 degrees
toward frame 23; v3-2 (`screenshots/frame22_polish_a_strip.png`) reads more clearly between 21 and 23.

Recommended next step, outside this loop (2 calls of the frame's 4 remain): one call `--source 24 --change -22`
(this call's own ratio, 1.48 per D, puts -22 at about 287) and the same free outline and shadow pass, which should give
v4-2's finish at the target heading. Then install that, not v4-2 or v3-2, unless the board prefers one of them.

## Pictures

- `screenshots/frame22_v4-2_zoom_light.png`: candidate as processed, v4-2, v3-2 at x5.
- `screenshots/frame22_v4-2_strip.png`: frames 20, 21, NEW 22 (v4-2), 23, 24.
- `screenshots/frame22_cand2_raw_vs_polished_zoom.png`: why the despeckle pass was left out for this candidate.
