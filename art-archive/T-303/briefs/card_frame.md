Piece: card_frame.png (180 x 150), the level-up screen's card, a 9-slice frame (margin 10 art pixels) that the game stretches to the card's size; part of the level-up screen, one of Greenbull's own things (Visual style, Decisions, "Greenbull's look"; the level-up screen in Greenbull's dark green leading, light green and a little yellow).

How to make it (free script, no PixelLab: task T-303 says free script work first, and this piece is fully script-drawn):
  python game/tools/build_level_up_art.py piece card_frame <the version's PNG path>
To refine, edit `card_frame()` (and the palette constants) in game/tools/build_level_up_art.py, keeping 180 x 150, the 10-pixel border (the 9-slice margin) and no red. Never call PixelLab for this piece.

What it must be: a dark green outer border band (Greenbull's dark green RGB 12, 76, 44 leading) with a light green inner band, stepped pixel corners, a plain pale fill where the game writes the weapon's image, title and description in black, and four small yellow corner studs as the little yellow accent. No Redgull red. Flat UI art at 2 screen pixels per art pixel; hard pixel edges, dark selective outline, at most 30 colours, alpha 0 or 255 only, transparent outside the corners. A screen UI piece, not a world object, so the isometric view and the 32 px per unit scale don't apply; its middle must stay plain so it stretches as a 9-slice.
