Piece: header_ribbon.png (380 x 44), the level-up screen's banner, one of Greenbull's own things (Visual style, Decisions, "Greenbull's look"; the level-up screen in Greenbull's dark green leading, light green and a little yellow).

How to make it (free script, no PixelLab: task T-303 says free script work first, and this piece is fully script-drawn):
  python game/tools/build_level_up_art.py piece header_ribbon <the version's PNG path>
The script draws it; to refine, edit the `header_ribbon()` function (and the palette constants it uses) in game/tools/build_level_up_art.py, keeping 380 x 44 and no red. Never call PixelLab for this piece.

What it must be: a light green ribbon field (the game letters the title in black between x 76 and 304, so that field stays light and plain), dark green trim with one thin yellow line on top, dark green folded tails with a V notch, and at each end a pale round medallion carrying Greenbull's approved emblem (game/art/logo/greenbull_emblem_32.png, the bull's head, unchanged). No Redgull red, no gull. Flat UI art drawn at 2 screen pixels per art pixel; hard pixel edges, dark selective outline, at most 30 colours, alpha 0 or 255 only, transparent background. It is a screen UI piece, not a world object, so the 3/4 isometric view and the 32 px per unit scale don't apply.
