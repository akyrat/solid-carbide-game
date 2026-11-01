Task T-464 (read tasks/T-464-art-the-mission-notebook-page-with.md, game/scripts/hud/mission_page.gd, game/scripts/hud/hud_style.gd, docs/visual-style.md Content "Rules" and the HUD style sheet).

Kind: **screen-space HUD art**, shown at **2x**, nearest filtering, on the cream notebook page of the mission list (paper about 245,240,217, ink about 31,33,51). Marks are drawn in dark ink with a hand-made pen feel. No Greenbull light green or yellow (rule 6). Transparent background, opaque/transparent pixels only, at most 30 colours (these use very few). Script-drawn only (0 PixelLab): game/tools/build_hud_mission_art.py, one function per piece, never overwrite a file; the file is shared with the page's brief, add your function to it.

The three pieces (this brief is used for one at a time; the loop's --size and --out say which):
- **checkbox**, 7 x 7 art px (shown 14 x 14): an empty square, 1 px ink outline slightly uneven/hand-drawn, paper-coloured inside (opaque), one lighter inner pixel.
- **tick**, 7 x 7 art px: a bold ink check mark (2 px thick stroke, a quick flick up on the right) that overlays the checkbox and may poke a little beyond the box top right. Transparent elsewhere.
- **cross-off mark**, 24 x 4 art px: a pen strike-through stroke, 2 px thick with a slight wobble, rounded ends; the game tiles it along a goal's text width (the left and right ends are the caps; keep the middle 8 px (x 8..15) a plain repeatable stretch so it can be repeated).

Write each version only to the path the loop gives you; free script fixes before anything paid (no PixelLab here).
