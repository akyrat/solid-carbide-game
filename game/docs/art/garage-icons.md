# Garage icons

Tasks T-366 to T-370 (Garage design, Decisions, "Pixel art icons for the upgrades"): one 16 x 16 icon per upgrade in `game/art/garage/<upgrade key>.png`, each with a `.json` record, script-drawn (0 PixelLab generations) in the reaction icons' comic look (1 pixel dark outline, flat fills, one highlight; no Greenbull colours). The garage loads them on its own (T-365).

## Damage bonus (T-368)

- `game/art/garage/damage_bonus.png`: a red comic burst with a white up arrow, shade on the lower right, one highlight pixel on the left.
- Rebuild: `python game/tools/build_garage_icon_damage_bonus.py build --out-dir game/art/garage --force` (hand-placed grid, byte-identical every run; reuses the helpers of `build_hud_livestream_art.py`).
- Tests: `game/tools/test_build_garage_icon_damage_bonus.py`.
- Screenshots and the style-loop versions: `art-archive/T-368/screenshots/` (`icon_enlarged.png`, `garage.png`, `v1.png`, `v2.png`).
