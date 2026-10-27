Piece: header_ribbon.png (380 x 44), the level-up screen's banner, one of Greenbull's own things (Visual style, Decisions, "Greenbull's look": dark green leads, light green supports it, yellow is a small accent; Content, Rules, rule 6). Task T-311.

How to make it (free script, no PixelLab: the task says this is free script work, and the piece is fully script-drawn):
  python game/tools/build_level_up_art.py piece header_ribbon <the version's PNG path>
The script already draws the T-311 version; run it as is for the first version. To refine, edit the `header_ribbon()` function (and the palette constants it uses) in game/tools/build_level_up_art.py, keeping 380 x 44, the title area (art x 76 to 304) plain, the emblem medallions, and no red. Never call PixelLab for this piece.

What it must be: Greenbull's dark green RGB 12, 76, 44 centre field (the game letters the title in cream, RGB 246, 250, 232, with a 4-pixel dark outline RGB 14, 22, 18, between art x 76 and 304, so that field stays plain dark green), light green RGB 104, 220, 96 kept to the trim above and below the field, one thin yellow RGB 247, 208, 52 line on top, dark green folded tails with a V notch, and at each end a pale round medallion carrying Greenbull's approved emblem (game/art/logo/greenbull_emblem_32.png, the bull's head, unchanged). Dark green must be the ribbon's most common colour. No Redgull red, no gull. Flat UI art drawn at 2 screen pixels per art pixel; hard pixel edges, dark selective outline, at most 30 colours, alpha 0 or 255 only, transparent background. It is a screen UI piece, not a world object, so the 3/4 isometric view and the 32 px per unit scale don't apply.

Run 2: the script now draws one bevel row (instead of two) between the trim's outline and the dark green field, top and bottom, so dark green leads on the in-game screenshot by a clearer margin (run 1's version led the outline colour by only 854 screen pixels). Run the script as is for the first version.

The earlier version (T-303, light green field, black title) is kept in art-archive/T-311/t303/header_ribbon.png for comparison.
