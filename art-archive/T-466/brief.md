# Brief: Rev Charge's charging and boost frames (T-466)

Script-drawn, no PixelLab (0 generations; do not call it). The sheet is made by `game/tools/build_rev_charge.py base`, which writes `game/art/driving/rev_charge/rev_charge_base.png`: one row of 11 frames, 64 x 64 each, drawn pointing right (the car is at the right, the effect trails to the left).

- Frames 0-3: charging. A heat glow (yellows and oranges, stepped dithered halos, small flame trailing back) at the car's rear, growing 25 / 50 / 75 / 100 %.
- Frames 4-5: fully charged, two frames alternated for a pulse (hot white core).
- Frames 6-10: the boost. Five pale blue-grey speed lines streaming back from the car, shorter and thinner as the boost runs down.

Rules: Visual style, Content, "Rules" (opaque or empty pixels, at most 30 colours, glow drawn as stepped halos, selective dark outline, never Greenbull's light green or yellow). To refine, edit the colours and shapes in `game/tools/build_rev_charge.py` and run it again (free), then copy the output to the kept file. Do not change the frame count or order, the game reads them by column.
