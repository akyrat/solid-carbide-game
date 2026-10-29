# Garage icons

Tasks T-366 to T-370 (Garage design, Decisions, "Pixel art icons for the upgrades"): one 16 x 16 icon per upgrade in `game/art/garage/<upgrade key>.png` with a `.json` record, shown beside the garage row at 3x (T-365). Script-drawn, 0 PixelLab generations.

## Pickup magnet (T-369)

`game/art/garage/pickup_magnet.png`: a horseshoe magnet, blue body (highlight left, shade right), white pole tips, the HUD's 1 pixel dark outline, no Greenbull colours. Rebuild: `python game/tools/build_garage_icon_pickup_magnet.py build --out-dir game/art/garage --force`. Test: `game/tools/test_build_garage_icon_pickup_magnet.py`. Style score 8 (one round). Screenshots: `art-archive/T-369/screenshots/`.
