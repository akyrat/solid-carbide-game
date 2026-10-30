# Brief: trick illustration `three_sixty` (T-383, script-drawn set)

A still 64 x 48 pixel art picture for the tutorial's trick list (game/docs/hud-and-menus/tutorial-slides.md), drawn at its final size, transparent background, showing the car's movement as a path. Style: docs/visual-style.md, Content, "Rules": night palette with pink and cyan neon, dark selective outline, hard edges, at most 30 colours, no Greenbull light green or yellow.

This set is drawn by script, not PixelLab: do NOT call PixelLab (0 generations). The script is `game/tools/build_trick_illustrations.py`. To make this version run:

    python game/tools/build_trick_illustrations.py build --only three_sixty --file <the exact PNG path the loop asks for>

It writes the PNG straight to that path (no copying needed). To refine, edit the `three_sixty` function (or the shared helpers, keeping the other six pictures readable) in that script and rebuild; never retouch the PNG by hand.

Trick: **360** (game/docs/driving/tricks.md): a full 360 degree turn in one drift. Show it as a path with one clear loop in it, the car at the end.
