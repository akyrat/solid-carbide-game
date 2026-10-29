# Garage screen

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Garage screen

Task T-058 (UI Agent). `scenes/menu/garage_screen.tscn` with `scripts/menu/garage_screen.gd` (`GarageScreen`). What it shows: `docs/garage-design.md`, Content. Reached from the main menu's Garage button (wired in T-089, `GameFlow.show_garage()`).

- **Use it:** set `progress` (a `PlayerProgress`, normally `GameFlow.progress`) before adding it to the tree; if left null it reads the save file itself. It redraws on the progress object's `changed` signal. Signal: `back_pressed`. Standalone: open the scene in the editor and press F6.
- **Screenshot** (a save with 120 coins and one upgrade at its last level), from the repo root: `bash game/tools/screenshot.sh res://tests/fixtures/garage_screen_demo.tscn screenshots/garage.png 20`.
- **Tests:** `tests/unit/test_garage_screen.gd` (the approved text, buying, unaffordable, maxed, back signal).

- **Upgrade icons (T-365):** each row starts with a 48 x 48 `Icon` (a `TextureRect`, nearest filter) showing `game/art/garage/<upgrade key>.png` (16 x 16 art, drawn at 3x; keys are those of `game/data/garage.json`: `acceleration`, `car_health`, `damage_bonus`, `pickup_magnet`, `air_turn`), or, when the file is missing, a grey pixel-square placeholder drawn in code (`GarageScreen.placeholder_texture()`, no text, no Greenbull colours). The PNG is read with `Image.load_from_file`, so no `.import` file is needed. The art tickets (T-366 to T-370) only add their PNG: no code change. Tests: `tests/unit/test_garage_icons.gd`.
