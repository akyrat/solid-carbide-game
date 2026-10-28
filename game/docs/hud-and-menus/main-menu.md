# Main menu

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Main menu

The main menu (task T-054, UI Agent): `scenes/menu/main_menu.tscn` with its script `scripts/menu/main_menu.gd` (`MainMenu`). What it shows: `docs/hud-and-menus.md`, Content. The game opens on it through the screen flow (see "Screen flow").

- **Open it:** in the editor, open the scene and press F6. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/menu/main_menu.tscn screenshots/main_menu.png 20`.
- **Signals:** `start_pressed`, `garage_pressed`, `exit_pressed`, one per button. The menu does nothing else when a button is pressed.
- **Tests:** `tests/unit/test_main_menu.gd` (the texts and each signal), part of the GUT suite.

