# Brief: trick illustration `airtime` (T-383, script-drawn set)

A still 64 x 48 pixel art picture for the tutorial's trick list (game/docs/hud-and-menus/tutorial-slides.md), drawn at its final size, transparent background, showing the car's movement as a path. Style: docs/visual-style.md, Content, "Rules": night palette with pink and cyan neon, dark selective outline, hard edges, at most 30 colours, no Greenbull light green or yellow.

This set is drawn by script, not PixelLab: do NOT call PixelLab (0 generations). The script is `game/tools/build_trick_illustrations.py`. To make this version run:

    python game/tools/build_trick_illustrations.py build --only airtime --file <the exact PNG path the loop asks for>

It writes the PNG straight to that path (no copying needed). To refine, edit the `airtime` function (or the shared helpers, keeping the other six pictures readable) in that script and rebuild; never retouch the PNG by hand.

Consistency: all seven pictures must keep one look (same car, road strip, tire marks, glow). Put improvements in the shared helpers (draw_car, draw_road, draw_tire_marks, draw_dashed, draw_ring) so every picture gains; do not give one picture its own car. Keep the other six readable, and keep the pytest passing (`python -m unittest discover game/tools -p test_build_trick_illustrations.py`). The car's design is fixed by Visual style rule 10: dark green 12,76,44 body, two centred white stripes with a gap.

Trick: **airtime** (game/docs/driving/tricks.md): a long time in the air. Show one high dashed arc off a ramp and the car landing, no turn marks; a height mark under the top.
