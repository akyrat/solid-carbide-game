Brief for T-295: Greenbull's wordmark, the emblem with the name GREENBULL.

The board's words (2026-10-26): the sponsor is renamed "Greenbull", one word; "we're gonna make the logo something cool … don't make it look like the real, like the Red Bull logo"; colours "dark green, light green, and yellow … but don't use yellow too much. Let's lean into the dark green to make it the main theme color for the company." The board asked for the emblem plus a wordmark.

The emblem (T-294, the Project Lead's pick, run 2: an angular bull's head with a lightning blaze, heavy brow and narrow yellow eyes) is copied here: art-archive/T-295/greenbull_emblem_128.png, _64.png and _32.png. Reuse it as it is; don't redraw it.

What to make:
- One wordmark image, transparent background: the emblem on the left and the word **GREENBULL** to its right on one line, exactly that spelling, all capitals. About 256 x 64 pixels (the 64 px emblem plus the letters); you may propose another size that suits the letters, and say why.
- The letters: bold, chunky, readable pixel letters with the emblem's confident, angular, sporty look (slanted or sharp-cornered is fine), all the same height, evenly spaced, never a copy of a real brand's lettering. Mostly dark green RGB 12, 76, 44 with light green RGB 104, 220, 96 (for example a light green face with a dark green drop shade, or the other way round), and yellow RGB 247, 208, 52 only as a tiny accent or not at all. The emblem's near-black outline (RGB 14, 22, 18) around the letters so the word reads on dark and light backgrounds. Use only the emblem's 5 colours.
- Rule 1 applies (hard edges, every pixel fully opaque or transparent, transparent background); it is flat brand art, so rule 2's shading doesn't apply (Visual style, Content, "Rules", last line). Rule 9: no real brand's look.

Style guide: docs/visual-style.md, Content, "Rules", and Decisions, "Greenbull's look".

How to make it (Asset Generation Agent):
- PixelLab is weak at lettering. Drawing the letters by script (a pixel font you define in the script, so every letter is exact) and pasting the emblem in is the expected first version, and it is free. Use PixelLab only where it clearly helps (for example to suggest a lettering style you then trace by script); the board's go is up to 12 generations for this asset, this loop run at most 4.
- Save each version as the loop asks (art-archive/T-295/style-loop/vN.png) with the script that drew it (and any PixelLab record) next to it. Never write into game/art/ (except the PixelLab log the client writes).
