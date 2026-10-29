# Garage icons

The five upgrade icons in `game/art/garage/<upgrade key>.png` (Garage design, Decisions, "Pixel art icons for the upgrades"; the garage loads them, T-365). All 16 x 16, script-drawn, 0 PixelLab generations, comic look of the reaction icons (T-352): 1 pixel dark outline, flat fills, one highlight, one dominant colour plus white; no Greenbull colours.

## car_health (T-367)

A red heart with a bold white plus (each level adds a heart), close to the HUD heart. `game/art/garage/car_health.png` plus `car_health.json`.

- Rebuild: `python game/tools/build_garage_icon_car_health.py build --force`.
- Tests: `game/tools/test_build_garage_icon_car_health.py`.
- Screenshots: `art-archive/T-367/screenshots/` (`icon_enlarged.png` on dark and light, `garage.png`).
