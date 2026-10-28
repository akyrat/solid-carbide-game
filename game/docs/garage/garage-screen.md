# Garage screen

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Garage screen

Task T-058 (UI Agent). `scenes/menu/garage_screen.tscn` with `scripts/menu/garage_screen.gd` (`GarageScreen`). What it shows: `docs/garage-design.md`, Content. Reached from the main menu's Garage button (wired in T-089, `GameFlow.show_garage()`).

- **Use it:** set `progress` (a `PlayerProgress`, normally `GameFlow.progress`) before adding it to the tree; if left null it reads the save file itself. It redraws on the progress object's `changed` signal. Signal: `back_pressed`. Standalone: open the scene in the editor and press F6.
- **Screenshot** (a save with 120 coins and one upgrade at its last level), from the repo root: `bash game/tools/screenshot.sh res://tests/fixtures/garage_screen_demo.tscn screenshots/garage.png 20`.
- **Tests:** `tests/unit/test_garage_screen.gd` (the approved text, buying, unaffordable, maxed, back signal).

