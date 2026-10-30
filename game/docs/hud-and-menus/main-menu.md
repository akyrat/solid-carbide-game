# Main menu

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Main menu

The main menu (task T-054, UI Agent): `scenes/menu/main_menu.tscn` with its script `scripts/menu/main_menu.gd` (`MainMenu`). What it shows: `docs/hud-and-menus.md`, Content. The game opens on it through the screen flow (see "Screen flow").

- **Open it:** in the editor, open the scene and press F6. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://scenes/menu/main_menu.tscn screenshots/main_menu.png 20`.
- **Signals:** `start_pressed`, `garage_pressed`, `exit_pressed`, one per button. The menu does nothing else when a button is pressed.
- **Title font (T-432):** Press Start 2P (`fonts/press_start_2p/`, OFL licence and `press_start_2p.json` record; fetched by `python game/tools/fetch_pixel_font.py`) for the title and the "(work in progress)" line, with a near-black outline and nearest filtering.
- **Splash cover slot (T-432):** if `art/menu/splash.png` exists, a `TextureRect` (`splash_rect`, keep-aspect-covered, nearest filtering) fills the screen behind the menu, under a 35% black scrim; otherwise `background` (plain dark navy) shows. `splash_path` can be set before the menu enters the tree to use another image. To preview: `python game/tools/menu_splash_shots.py make`, take the screenshot, then `... remove`.
- **Tests:** `tests/unit/test_main_menu.gd` (the texts and each signal), part of the GUT suite.

