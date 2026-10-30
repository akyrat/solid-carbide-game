# Brief: the HUD's weapon icons, 24 x 24, shown at 2x (T-429, goal G-008)

**What it is.** The HUD's weapon column (`game/scripts/hud/weapon_icons.gd`) shows one small icon per weapon the car has, in a 48 x 48 screen-pixel slot at the left of the screen, beside the hearts. Today it shows each weapon's level-up card picture (`game/art/level_up/weapon_<id>.png`, 64 x 64) squeezed into 48 px, a 0.75x scale, which breaks the HUD style sheet's rule 1 (Visual style, Decisions, "The HUD style sheet": HUD art drawn at 1x and shown at an integer scale, 2x; nothing at 0.75x). The fix (T-430's result notes) is new 24 x 24 icons shown at 2x in the same 48 px slot, so nothing moves or resizes.

**The file.** One row sheet of **6 frames of 24 x 24** (144 x 24 in all), RGBA, transparent background, in this order:

1. `gun`
2. `flamethrower`
3. `molotov`
4. `bricks`
5. `wiper`
6. `underglow`

**How to make it.** Script-drawn, **no PixelLab** (0 generations): a small redraw of each weapon's level-up card picture (`game/art/level_up/weapon_<id>.png`) at 24 x 24, keeping its subject, silhouette and main colours so the player recognises the weapon from the card. Write the script under `game/tools/` (with its test), so it can redraw the sheet. If a frame truly can't be made readable by script, say so in the round's notes rather than calling PixelLab.

**The sheet's rules it must follow** (Visual style, Decisions, "The HUD style sheet"):
- 1x pixels: hard edges, alpha only 0 or 255, no smoothing.
- A **1 pixel outline in (8, 8, 15)** round each icon (a few lighter highlight pixels may break it, at most 15% of the edge).
- Two or three shading steps lit from the top left, a white glint on round things, no gradients.
- Palette: the subjects' own colours from the card pictures; **no Greenbull light green or yellow** (rule 6), except where the card picture itself is one of Greenbull's things (none of these six is).
- Each icon centred in its 24 x 24 frame, filling most of it (about 20 to 22 pixels on its long side) so it reads at 48 px on screen.

**Where it goes.** `game/art/hud/weapon_icons.png` with a json record beside it (`weapon_icons.json`: task, what, size, frames, frame order, shown_at_scale 2, made_by, style_loop, pixellab_generations 0, references), like the other files in `game/art/hud/`.

**References.** `docs/visual-style.md` (Content, Rules; Decisions, "The HUD style sheet"), `docs/extended-narrative.md`, `game/art/level_up/weapon_*.png`, `game/art/hud/heart_full.png` (a 2x HUD sprite with the same outline), `game/tools/hud_sheet_check.py` (checks art against the sheet).
