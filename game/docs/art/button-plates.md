# The shared button's plates (T-447)

Five 9-slice plates in `game/art/ui/`, one per state of the shared button (`HudStyle.style_button`, `game/scripts/hud/hud_style.gd`): `button_plate_normal.png`, `_hover`, `_focus`, `_pressed`, `_disabled`. 72 x 22 art pixels, shown at 2x, slice margins 3 art pixels on every side (outline and two bevel rows), so the flat middle stretches. The record is `game/art/ui/button_plates.json`.

- Drawn by `python game/tools/build_button_plates.py build` (deterministic, 0 PixelLab generations; `--state NAME --out FILE` draws one). Tests: `game/tools/test_build_button_plates.py`. Each state's colours are one entry of `PALETTE` in the script.
- Style: the HUD style sheet (Visual style, Content, rules 1 to 4 and 7): near-black (8, 8, 15) outline, stepped corner of radius 2, steel bezel lit from the top left, flat fills, alpha 0 or 255, no Greenbull colour.
- The focus plate is a ring with a transparent middle, drawn over the state's plate; every other state is opaque.
- Every plate went through the style loop (T-447's Style review; versions in `art-archive/T-447/style-loop/`, screenshots in `art-archive/T-447/screenshots/`).
