T-397, the sidewalk sample: one isometric sidewalk ground tile with a curb edge against the road, for the level creator (Level design, Decisions, "Sidewalks and parked cars in the level creator").

What it must be
- One ground tile of 128 x 64 art px: the same 2 x 2 unit diamond, isometric angle (2:1) and pixel scale (32 art px per unit, drawn at 0.5) as the road tiles in `game/art/ground/ground_atlas.png` (for example `y_plain_a0`).
- Pavement in the city's palette B (Visual style, Decisions, "City brief" and "City colours"): a lighter, cooler grey than the asphalt, matching the pavement already drawn round the creator buildings (`game/art/buildings/creator_final/small_0.png`; its colours are `PAV*` in `game/tools/build_creator_buildings_art.py`). Slabs, light cracks. No Greenbull colours, no boulder navy, purple or magenta.
- A raised curb along the tile's south-east edge (world +x, the screen's lower-right edge): the side that meets the road. The curb is low: under 0.1 unit (about 3 art px), because the car drives up over it. It must read clearly as a curb stone next to the dark asphalt: a stone top, a lit edge, a small front face and a dark gutter line where it meets the road.
- The slabs repeat every 2 units so tiles join without seams (the other edges carry no outline).
- Rules 1, 2, 3, 4, 7 and 10 of Visual style, Content, "Rules" apply. It is a ground tile, so rule 2's outline means the gutter line on the curb side; the other edges join other tiles and stay without an outline.

How it is made (free, no PixelLab for this piece; never call PixelLab for the sidewalk)
- `python game/tools/build_sidewalk_car_sample.py sidewalk --out <the version's PNG>` draws it. Refines change that script (its colours, curb width and height, joints, cracks) and run it again; keep the tests in `game/tools/test_build_sidewalk_car_sample.py` passing (`python -m unittest game/tools/test_build_sidewalk_car_sample.py`).
- After each version, also write the composed preview, so the fit can be judged: `python game/tools/build_sidewalk_car_sample.py preview --sidewalk <the version's PNG> --out-dir art-archive/T-397/style-loop/sidewalk_v<N>_preview` (a road along y with the curb tiles against it, plain sidewalk tiles behind, a creator building and a boulder; dark and light background, 3x nearest neighbour). Say the preview's path in `changed`, so the evaluator can open it.
