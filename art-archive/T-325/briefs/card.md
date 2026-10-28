# Brief: the Bricks level-up card image (T-325)

What: the card image for the weapon Bricks on the level-up screen, 64 x 64 pixels, drawn at the card slot's final size (shown 1:1 in a 64 x 64 slot). It sits beside T-174's five card images in `game/art/level_up/` (look at `weapon_molotov.png` and `weapon_wiper.png` and their `.json` records first: same size, same outline, same kind of prompt).

The weapon (docs/weapons.md, Decisions, "Bricks"): the car carries a load of bricks; landing after a jump sends out an impact wave. The card text makes it sound useless ("A bunch of bricks. No real use, other than making the car heavier."), so the picture is plain and a little funny: **a small neat stack of old clay bricks**, three or four rows, staggered like a wall, maybe one loose brick leaning on the stack or a chip broken off one corner. No car in the picture (a car's boot would need the car's dark green, and it would not read at 64 px). Seen from a 3/4 view from above, the top and one side showing, like a game item icon.

Colours: real brick colours, a warm terracotta brown with darker shaded faces and lighter lit edges, grey-white mortar lines. Not bright red, not orange. None of Greenbull's colours (rule 6: no light green RGB 104, 220, 96, no yellow RGB 247, 208, 52, no dark green RGB 12, 76, 44). A black outline, a transparent background, at most 30 colours, hard pixel edges.

How (paid, within the task's go; 1 generation per version):

```
python game/tools/pixellab_client.py generate --endpoint create-image-pixflux --params-file <params.json> --out-dir art-archive/T-325/card --name card_v<N> --task T-325 --consulted docs/visual-style.md --consulted docs/weapons.md --consulted game/art/level_up/weapon_molotov.json
```

with a params file (write it in `art-archive/T-325/card/`) like T-174's: `description` (the prompt you write, ending "retro pixel art, game icon"), `image_size` 64 x 64, `no_background` true, `outline` "single color black outline", `shading` "medium shading", `detail` "highly detailed", `text_guidance_scale` 8.

Then free fixes before saving the version: make every pixel fully opaque or fully transparent, remove loose specks, and cut it to at most 30 colours if needed (`python game/tools/reduce_palette.py`, see its `--help`). Check it with `python game/tools/style_rules.py art <png> --size 64x64`.

On a refine: fix what the reason names with a free script fix first (palette, specks, recolour toward the brick browns); regenerate (1 more generation) only when the drawing itself is wrong. At most 4 generations in all for this image.
