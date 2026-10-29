# Screen flow

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Screen flow

Task T-055 (Game Loop Agent). `scenes/game/game.tscn` (script `scripts/game/game_flow.gd`, class `GameFlow`) is the project's main scene: pressing F5 in the editor, or `"$GODOT_BIN" --path game`, starts the game on the main menu. The flow is Game loop architecture, Content, "Screen flow".

- **Start** removes the menu and starts a fresh run (`scenes/run/run.tscn`), with the pause screen (Escape) added to the run and the camera zoom read from the saved setting.
- **When the run ends,** win or loss (`RunState.run_ended`, which on a health loss comes after the wreck, T-360), `_on_run_ended` reads `run.state.recap()` at once and, deferred, `show_recap(summary)` removes the run and shows the recap screen (T-320, `game.recap`, a `RecapScreen` from `scenes/menu/recap_screen.tscn`; [../hud-and-menus/recap-screen.md](../hud-and-menus/recap-screen.md)). Its `closed` signal (Continue, the X or Enter) calls `show_menu()`. `show_recap()` takes any summary, so another screen (the time's up screen, T-317, or the runs list, T-364) can call it.
- **Garage** (T-089) replaces the menu with the garage screen (`game.garage`, given `game.progress`); its back button (`back_pressed`) brings the main menu back.
- **Exit** closes the game (`get_tree().quit()`, through `quit_game`, which tests replace).
- Only one screen is on show at a time, as the only child of `Game`: `game.menu`, `game.garage`, `game.run` or `game.recap` (the others are null). `game.pause_screen` is the run's pause screen. The signals `menu_shown`, `run_shown` and `recap_shown` fire after each switch.
- **Tests:** `tests/unit/game/test_screen_flow.gd`, part of the GUT suite: the first screen, Start, a win and both kinds of loss to the recap and from its Continue and its X back to the menu (T-320), the recap waiting for the wreck, the recap showing what the run counted, a second run, Garage and its back button, Exit, Escape during a run, and the zoom.
- **Pause screen Restart and Exit** (T-327): `GameFlow` connects the run's `pause_screen.restart_pressed` and `exit_pressed`. Restart banks `run.state.coins` into `progress` (`bank_run("loss", coins)`, so the coins are kept) and calls `start_run()`; Exit banks them and calls `show_menu()`. Neither goes through `run_ended`, so a screen listening for it (the recap) never sees them. The level creator's `play_level` connects the same signals: Restart replays the same level, Exit returns to its list. Tests: `tests/unit/game/test_pause_restart_exit.gd`, `tests/unit/level_creator/test_play_level.gd`.

