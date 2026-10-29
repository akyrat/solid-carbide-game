# Garage icons

The pixel art icons beside the garage's upgrade rows (Garage design, Decisions, "Pixel art icons for the upgrades"; the garage loads `game/art/garage/<upgrade key>.png`, else a grey placeholder, T-365). Script-drawn 16 x 16 icons, a 1 pixel dark outline, flat fills, one highlight, one dominant colour each plus white and the outline, no Greenbull colours, 0 PixelLab generations.

## Acceleration (T-366)

- `game/art/garage/acceleration.png` and `.json`: a blue speedometer dial, white ticks, a white needle and hub pointing up to the right.
- Rebuild: `python game/tools/build_garage_icon_acceleration.py build --force` (byte-identical every run).
- Tests: `game/tools/test_build_garage_icon_acceleration.py`.
- Screenshots (the icon on dark and light, the garage screen) and the style loop versions: `art-archive/T-366/`.
