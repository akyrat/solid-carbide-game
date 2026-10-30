# Sound effects in the game

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Sound effects are OFF for the MVP (T-388, board 2026-10-29)

**The switch: `"sfx_enabled": false` at the top of `data/sfx.json`** (read by `GameSettings.sfx_enabled()`). While it is false every sound effect is off whatever the saved SFX volume: `GameSettings.apply_sfx_volume` keeps the "SFX" bus muted and `RunSounds.play` / its loops start no player. The music is unaffected (own "Music" bus, `MusicPlayer`). Nothing was deleted: the scripts, `data/sfx.json`'s sounds and the saved SFX volume setting stay. **To turn the sound effects back on, set `"sfx_enabled": true` in `data/sfx.json`**; everything below then applies as written (the SFX volume slider default is still 0, so turn it up). Hiding the pause screen's SFX slider is a separate UI ticket. Tests: `tests/unit/run/test_sfx_off.gd`; the older sound tests set `GameSettings.sfx_enabled_override = 1` (a test hook; -1 = read the data file).

## Sound effects in the game (T-077)

`scripts/run/run_sounds.gd` (child "Sounds" of the run scene) plays the approved sounds. **Files, per-sound volumes and limits are in `data/sfx.json`: tune the sound by ear there** (`volume_db` per sound, 0 = as the file is, more negative = quieter; the engine's pitch and volume range follow the car's speed; `min_interval` and `max_players` keep bursts from turning into noise). All sounds follow the pause (a level-up or the pause screen silences them) and stop when the run ends.

| Sound | File (under `audio/sfx/`) | Plays |
|---|---|---|
| Engine | `engine/748027_sedan-engine-loop.ogg` | Looping all run long; higher pitch and louder with the car's speed |
| Drift | `drift/271337_car-peels-off.wav` | Looping while the car drifts; stops when the drift stops |
| Gun | `gun/854345_machine-gun-5-shot-burst.wav` | Once per volley of the starting gun |
| Flames | `flames/831929_flamethrower.wav` | Looping while the exhaust flamethrower's flames are on (drifting, plus the linger); stops when they go out |
| Hit | `hit/789388_bullet-impact-ground-subsonic-sfx.wav` | A bullet or the flames hurt an enemy |
| Coin | `coin/347174_coin-pickup-sound-v-0.wav` | The coin count goes up (a coin picked up) |
| Meteor warning | `meteor-warning/210205_falling.wav` | When the kaiju's warning circles appear; starts part way in so the whistle ends as the meteor lands |
| Meteor impact | `meteor-impact/869460_experimental-explosion-19.wav` | Each time a meteor lands |

**SFX volume (T-077, board 2026-10-16).** Every sound plays on the audio bus "SFX" (`GameSettings.ensure_sfx_bus()`), whose volume is the pause screen's "SFX volume" slider, 0 to 100, **default 0 = silent**. At 100 the sounds play at `data/sfx.json`'s volumes; in between the bus gain is the slider divided by 100. It is saved in `user://settings.cfg`, section `audio`, key `sfx_volume` (`GameSettings.load_sfx_volume` / `save_sfx_volume` / `apply_sfx_volume`) and applied when a run starts and on every change. **To hear anything in a playtest, turn the slider up (Escape).**

**Music volume slider (T-210).** The pause screen has a "Music volume" slider (`MusicRow`, `music_slider`, `music_label` in `scripts/ui/pause_screen.gd`) on its own row directly under the SFX row, laid out like it (label of `LABEL_WIDTH`, slider of the same width, value as a number at the right end), 0 to 100. It starts from `GameSettings.load_music_volume()` (default 40), and on every move saves with `save_music_volume` and applies at once with `apply_music_volume` to the "Music" bus only, never the SFX bus; the music keeps playing under the pause. The strip grew by one row, so its test limits were raised (the strip ends below half the screen, and below y 340 with the dynamic-camera buttons). Tests: `tests/unit/test_music_volume_slider.gd`. Screenshot: `art-archive/T-210/screenshots/pause_music_slider.png`.

Tests: `tests/unit/run/test_run_sounds.gd`, `tests/unit/test_sfx_volume.gd`.

**Credits (CC BY).** Every sound in the game is CC0 except one:

- "Falling.wav" by Augdog, https://freesound.org/people/Augdog/sounds/210205/, licensed CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/). Used for the meteor warning.

The other sounds are CC0 and need no credit. If a CC BY alternative from T-076 is swapped in, add its credit line here (`python game/tools/check_sfx_licenses.py game/audio --credits` prints it).

