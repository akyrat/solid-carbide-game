# Garage icons

The pixel art icons beside the garage's upgrade rows (Garage design, Decisions, "Pixel art icons for the upgrades", 2026-10-29; tasks T-366 to T-370). One 16 x 16 icon per upgrade in `game/art/garage/<upgrade key>.png`, each with a `.json` record; the garage loads them on its own and shows them at 3x, with a grey placeholder for any that is missing (T-365). Script-drawn like the HUD reaction icons (`reaction-icons.md`, T-352): a hand-placed grid, the HUD's 1 pixel dark outline, flat fills, one highlight, one dominant colour plus white, no Greenbull colours, 0 PixelLab generations.

## Acceleration (T-366)

- `game/art/garage/acceleration.png` and `.json`: a blue speedometer dial, white ticks, a white needle and hub pointing up to the right.
- Rebuild: `python game/tools/build_garage_icon_acceleration.py build --force` (byte-identical every run).
- Tests: `game/tools/test_build_garage_icon_acceleration.py`.
- Screenshots (the icon on dark and light, the garage screen) and the style loop versions: `art-archive/T-366/`.

## Car health (T-367)

- `game/art/garage/car_health.png` and `.json`: a red heart with a bold white plus (each level adds a heart), close to the HUD heart.
- Rebuild: `python game/tools/build_garage_icon_car_health.py build --force`.
- Tests: `game/tools/test_build_garage_icon_car_health.py`.
- Screenshots: `art-archive/T-367/screenshots/` (`icon_enlarged.png` on dark and light, `garage.png`).

## Damage bonus (T-368)

- `game/art/garage/damage_bonus.png`: a red comic burst with a white up arrow, shade on the lower right, one highlight pixel on the left.
- Rebuild: `python game/tools/build_garage_icon_damage_bonus.py build --out-dir game/art/garage --force` (hand-placed grid, byte-identical every run; reuses the helpers of `build_hud_livestream_art.py`).
- Tests: `game/tools/test_build_garage_icon_damage_bonus.py`.
- Screenshots and the style-loop versions: `art-archive/T-368/screenshots/` (`icon_enlarged.png`, `garage.png`, `v1.png`, `v2.png`).

## Pickup magnet (T-369)

- `game/art/garage/pickup_magnet.png`: a horseshoe magnet, blue body (highlight left, shade right), white pole tips. Style score 8 (one round).
- Rebuild: `python game/tools/build_garage_icon_pickup_magnet.py build --out-dir game/art/garage --force`.
- Tests: `game/tools/test_build_garage_icon_pickup_magnet.py`.
- Screenshots: `art-archive/T-369/screenshots/`.

## Air turn (T-370)

- `game/art/garage/air_turn.png`: a blue car under a thin white curved spin arrow (the car spins in the air). Kept at 7 after 3 refines, noted for the board.
- Build: `python game/tools/build_garage_icon_air_turn.py build --out-dir game/art/garage --force` (deterministic). Test: `game/tools/test_build_garage_icon_air_turn.py`.
- Versions and the enlarged dark and light sheets, plus the garage screenshot: `art-archive/T-370/` (`v1`, `v2`, ..., `screenshots/`). Every style loop round is in T-370's Style review.
