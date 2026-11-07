# Brief: jump effect spring (T-556)

Script-drawn, no PixelLab (0 generations; do not call it). A jump effect played around a car in a 3/4 isometric top-down drift game, at night, retro pixel style. This is: a steel coil standing up from a base plate under the car, stretching up then collapsing and dissolving; a spring pushing the car up.

The sheet is made by `python game/tools/build_jump_effects.py build`, which writes `game/art/effects/jump/spring.png`: one row of 8 frames, 96 x 96 each, transparent. The ground point the car left from is at (48, 68) in every frame. Drawn at 0.5 in the game (48 px, about 3 units wide). Quick (about 0.4 s) and readable at game size.

Rules: Visual style, Content, "Rules" (opaque or empty pixels only, at most 30 colours, glow drawn as stepped dithered halos, dark almost-black outline broken by highlights, never Greenbull's light green or yellow). To refine, edit the shapes and colours of this effect in `game/tools/build_jump_effects.py` and run it again (free); the other effects' sheets it rewrites are the same unless you changed them. Copy the result to the version path you were given. Keep 8 frames of 96 x 96 and the anchor.
