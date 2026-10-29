# Garage icons

The pixel art icons beside the garage's upgrade rows (Garage design, Decisions, "Pixel art icons for the upgrades"; the garage loads `game/art/garage/<upgrade key>.png`, else a grey placeholder, T-365). Script-drawn 16 x 16 icons, a 1 pixel dark outline, flat fills, one highlight, one dominant colour each plus white and the outline, no Greenbull colours, 0 PixelLab generations.

## Acceleration (T-366)

- `game/art/garage/acceleration.png` and `.json`: a blue speedometer dial, white ticks, a white needle and hub pointing up to the right.
- Rebuild: `python game/tools/build_garage_icon_acceleration.py build --force` (byte-identical every run).
- Tests: `game/tools/test_build_garage_icon_acceleration.py`.
- Screenshots (the icon on dark and light, the garage screen) and the style loop versions: `art-archive/T-366/`.
The five upgrade icons in `game/art/garage/<upgrade key>.png` (Garage design, Decisions, "Pixel art icons for the upgrades"; the garage loads them, T-365). All 16 x 16, script-drawn, 0 PixelLab generations, comic look of the reaction icons (T-352): 1 pixel dark outline, flat fills, one highlight, one dominant colour plus white; no Greenbull colours.

## car_health (T-367)

A red heart with a bold white plus (each level adds a heart), close to the HUD heart. `game/art/garage/car_health.png` plus `car_health.json`.

- Rebuild: `python game/tools/build_garage_icon_car_health.py build --force`.
- Tests: `game/tools/test_build_garage_icon_car_health.py`.
- Screenshots: `art-archive/T-367/screenshots/` (`icon_enlarged.png` on dark and light, `garage.png`).
