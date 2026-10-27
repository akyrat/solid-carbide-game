Piece: button_plate_pressed.png (72 x 22), the level-up card's "Take it" button plate while pressed (the game letters "Take it" on it in black). Part of the level-up screen, one of Greenbull's own things (Visual style, Decisions, "Greenbull's look"; dark green leading, light green and a little yellow).

How to make it (free script, no PixelLab: task T-303 says free script work first, and this piece is fully script-drawn):
  python game/tools/build_level_up_art.py piece button_plate_pressed <the version's PNG path>
To refine, edit `button()` (pressed=True) and the palette constants in game/tools/build_level_up_art.py, keeping 72 x 22, the same shape as button_plate.png, and no red. Never call PixelLab for this piece.

What it must be: the same plate pushed in: a flat mid-green face, darker than the normal plate's light green, with no top highlight, the darkest Greenbull green as its edge and a dark outline, stepped corners; black text must still read on it. No Redgull red. Flat UI art at 2 screen pixels per art pixel; hard pixel edges, at most 30 colours, alpha 0 or 255 only, transparent corners. A screen UI piece, so the isometric view and the 32 px per unit scale don't apply.
