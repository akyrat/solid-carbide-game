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
Tasks T-366 to T-370 (Garage design, Decisions, "Pixel art icons for the upgrades"): one 16 x 16 icon per upgrade in `game/art/garage/<upgrade key>.png`, each with a `.json` record, script-drawn (0 PixelLab generations) in the reaction icons' comic look (1 pixel dark outline, flat fills, one highlight; no Greenbull colours). The garage loads them on its own (T-365).

## Damage bonus (T-368)

- `game/art/garage/damage_bonus.png`: a red comic burst with a white up arrow, shade on the lower right, one highlight pixel on the left.
- Rebuild: `python game/tools/build_garage_icon_damage_bonus.py build --out-dir game/art/garage --force` (hand-placed grid, byte-identical every run; reuses the helpers of `build_hud_livestream_art.py`).
- Tests: `game/tools/test_build_garage_icon_damage_bonus.py`.
- Screenshots and the style-loop versions: `art-archive/T-368/screenshots/` (`icon_enlarged.png`, `garage.png`, `v1.png`, `v2.png`).
Tasks T-366 to T-370 (Garage design, Decisions, "Pixel art icons for the upgrades"): one 16 x 16 icon per upgrade in `game/art/garage/<upgrade key>.png` with a `.json` record, shown beside the garage row at 3x (T-365). Script-drawn, 0 PixelLab generations.

## Pickup magnet (T-369)

`game/art/garage/pickup_magnet.png`: a horseshoe magnet, blue body (highlight left, shade right), white pole tips, the HUD's 1 pixel dark outline, no Greenbull colours. Rebuild: `python game/tools/build_garage_icon_pickup_magnet.py build --out-dir game/art/garage --force`. Test: `game/tools/test_build_garage_icon_pickup_magnet.py`. Style score 8 (one round). Screenshots: `art-archive/T-369/screenshots/`.
