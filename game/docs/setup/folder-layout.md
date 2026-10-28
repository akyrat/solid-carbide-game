# Folder layout

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Folder layout

| Folder | What goes in it |
| --- | --- |
| `scenes/` | Scenes (`.tscn`). `game/game.tscn` is the main scene (the screen flow); `drift_prototype/` is the drift prototype; `driving/` the drift marks and drift smoke; `level/` is the MVP map; `run/` is the run |
| `scripts/` | Game GDScript (`.gd`). `game/` holds the screen flow; `driving/` holds the car's movement, the drift prototype and its tuning panel; `level/` the map and its challenges; `run/` the run and its state; `enemies/` the minions and their coins (see "Minions") and the kaiju (see "The kaiju"); `weapons/` the car's weapons (see "Weapons") |
| `data/` | Game data as JSON (see "Game data"). `level/mvp_map.json` is the MVP map's layout |
| `art/` | Sprites, tilesets and other images |
| `audio/` | Sound effects and music. `audio/music/` holds the board's two tracks (`demo_beat_1.mp3`, `demo_beat_2.mp3`, source in the `.json` next to each); `scripts/game/music_player.gd` plays them, alternating, on the "Music" bus (setting `GameSettings` `music_volume`, 0 to 100, default 40) |
| `tests/unit/` | GUT test scripts (`test_*.gd`), in subfolders if you like |
| `tests/fixtures/` | Scenes and files that exist only for tests |
| `tools/` | Test runner, screenshot tool, audio import checker, Freesound downloader, PixelLab client, sprite rule checker, placeholder car sheet generator, final car sheet builder, effect art builders (level-up particles, drift mark, drift smoke, gift pack placeholders) and shared shell helpers. Not game code |
| `addons/gut/` | The GUT test framework (9.6.1). Do not edit |

The `.godot/` folder is Godot's cache. It is git-ignored and rebuilt automatically. Keep the `.uid` files Godot creates next to scripts: they belong in git.

