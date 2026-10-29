# Garage icons

Garage design, Decisions, "Pixel art icons for the upgrades" (2026-10-29). One 16 x 16 icon per upgrade in `game/art/garage/<upgrade key>.png`, each with a `.json` record, shown by the garage at 3x (T-365). Script-drawn like the HUD reaction icons (`reaction-icons.md`): hand-placed grid, 1 pixel dark HUD outline, flat fills, one highlight, one dominant colour plus white, no Greenbull colours, 0 PixelLab generations.

## Air turn (T-370)

- `game/art/garage/air_turn.png`: a blue car under a thin white curved spin arrow (the car spins in the air).
- Build: `python game/tools/build_garage_icon_air_turn.py build --out-dir game/art/garage --force` (deterministic). Test: `game/tools/test_build_garage_icon_air_turn.py`.
- Versions and the enlarged dark and light sheets, plus the garage screenshot: `art-archive/T-370/` (`v1`, `v2`, ..., `screenshots/`). Every style loop round is in T-370's Style review.
