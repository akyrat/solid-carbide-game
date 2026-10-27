Piece: button_plate.png (72 x 22), the level-up card's "Take it" button plate, normal state (the game letters "Take it" on it in black and stretches it as a 9-slice). Part of the level-up screen, one of Greenbull's own things (Visual style, Decisions, "Greenbull's look"; dark green leading, light green and a little yellow).

How to make it (free script, no PixelLab: task T-303 says free script work first, and this piece is fully script-drawn):
  python game/tools/build_level_up_art.py piece button_plate <the version's PNG path>
To refine, edit `button()` (pressed=False) and the palette constants in game/tools/build_level_up_art.py, keeping 72 x 22 and no red. Never call PixelLab for this piece; keep it matching button_plate_pressed.png (same shape).

What it must be: a raised plate: a light green face (black text must read on it) with a pale top highlight row and a mid-green shade at the bottom, a dark green edge (Greenbull's dark green) and a dark outline, stepped corners. No Redgull red. Flat UI art at 2 screen pixels per art pixel; hard pixel edges, at most 30 colours, alpha 0 or 255 only, transparent corners. A screen UI piece, so the isometric view and the 32 px per unit scale don't apply.
