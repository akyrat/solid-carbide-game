Piece: highlight_frame.png (192 x 162), the hollow frame around the highlighted card on the level-up screen (a 9-slice, margin 10; the card sits 6 art pixels inside it). Part of the level-up screen, one of Greenbull's own things (Visual style, Decisions, "Greenbull's look"; dark green leading, light green and a little yellow).

How to make it (free script, no PixelLab: task T-303 says free script work first, and this piece is fully script-drawn):
  python game/tools/build_level_up_art.py piece highlight_frame <the version's PNG path>
To refine, edit `highlight_frame()` (and the palette constants) in game/tools/build_level_up_art.py, keeping 192 x 162, hollow (transparent middle) and no red. Never call PixelLab for this piece.

What it must be: a bright frame that makes the chosen card stand out against the dark green card borders: pale and light green lines with one yellow line, a stepped mid-green glow ring outside (glow drawn in pixels, no blur), dark outline lines, stepped corners, transparent middle. No Redgull red. Flat UI art at 2 screen pixels per art pixel; hard pixel edges, at most 30 colours, alpha 0 or 255 only. A screen UI piece, not a world object, so the isometric view and the 32 px per unit scale don't apply.
