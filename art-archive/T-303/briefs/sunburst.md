Piece: sunburst.png (256 x 256), the level-up screen's backdrop: a disc of rays that sits behind the cards over the dimmed run, scaled up 4x, drawn at 75 percent opacity and slowly spun by the game. Part of the level-up screen, one of Greenbull's own things (Visual style, Decisions, "Greenbull's look"; dark green leading, light green and a little yellow).

How to make it (free script, no PixelLab: task T-303 says free script work first, and this piece is fully script-drawn):
  python game/tools/build_level_up_art.py piece sunburst <the version's PNG path>
To refine, edit `sunburst()` (and the palette constants) in game/tools/build_level_up_art.py, keeping 256 x 256 and no red. Never call PixelLab for this piece.

What it must be: 24 rays from the centre in Greenbull's dark greens (dark green RGB 12, 76, 44 leading, with a darker and a slightly lighter green), inside a circle with a dark rim and a transparent outside. It is a quiet backdrop behind busy cards, so it stays dark and low in contrast. No Redgull red. Hard pixel edges, at most 30 colours, alpha 0 or 255 only. A screen UI piece, so the isometric view and the 32 px per unit scale don't apply.
