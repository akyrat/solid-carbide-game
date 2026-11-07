# Brief: jump effect stunt_sparks (T-556)

Script-drawn, no PixelLab (0 generations; do not call it). A jump effect played around a car in a 3/4 isometric top-down drift game, at night, retro pixel style. This is: a burst of orange and white sparks flying out from under the car and dropping, with a small flash at the start.

The sheet is made by `python game/tools/build_jump_effects.py build`, which writes `game/art/effects/jump/stunt_sparks.png`: one row of 8 frames, 96 x 96 each, transparent. The ground point the car left from is at (48, 68) in every frame. Drawn at 0.5 in the game (48 px, about 3 units wide). Quick (about 0.4 s) and readable at game size.

Rules: Visual style, Content, "Rules" (opaque or empty pixels only, at most 30 colours, glow drawn as stepped dithered halos, dark almost-black outline broken by highlights, never Greenbull's light green or yellow). To refine, edit the shapes and colours of this effect in `game/tools/build_jump_effects.py` and run it again (free); the other effects' sheets it rewrites are the same unless you changed them. Copy the result to the version path you were given. Keep 8 frames of 96 x 96 and the anchor.
