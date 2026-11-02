# Rain over the map

Task T-507 (Level design, Decisions, "Rain over the map"; Content, "Rain"). The art swap is T-509, the settings toggle T-508.

## Files

- `scripts/level/rain.gd`: the rain, a `CanvasLayer` named `Rain`.
- `data/rain.json`: its numbers (read by `load_config()`; a missing key keeps the default in `rain.gd`'s `DEFAULTS`).
- `scripts/ui/game_settings.gd`: `load_rain_enabled()` and `save_rain_enabled(on)`, section `graphics`, key `rain_enabled`, default false (T-510); `GameSettings.notifier.rain_enabled_changed(on)` fires on every save.
- `scripts/run/run.gd`: adds the rain (`run.rain`) just before the HUD.
- `tests/unit/test_rain.gd`: the tests.
- `tools/bench_rain.sh` (`bench_rain.gd`): the headless cost check.
- `tests/fixtures/rain_demo_street.tscn`, `rain_demo_rooftop.tscn`: screenshot fixtures on the game's map.

## How it draws

- **Layer 5:** over the world (the map, the car, the enemies, all on the default canvas, layer 0), under the HUD (10), the gift arrows (11), the level-up and power-up screens (15), the time-up screen (16) and the pause screen (20).
- **Screen space, anchored to the map:** drops live in a field the size of the screen plus a margin that wraps round. Each frame the field is shifted by the main canvas transform's origin (the camera), so the rain moves with the map while the camera follows the car, and never runs out at the edges.
- **Pixel size:** one art pixel is `round(zoom * 16 / 32)` screen pixels, at least 1 (the map art's own scale), so the rain sits on the art's pixel grid.
- **Drops:** each falls along the slant (`angle_deg` from straight down, leaning left at the bottom) at `fall_speed` art pixels a second for a random life (`drop_life_min` to `drop_life_max`). When its life ends it leaves a splash where it is with `splash_chance` (up to `max_splashes` at once) and starts again at a random place. A splash lands on whatever is drawn there, a street or a rooftop.
- **Counts:** `drops_per_screen` and `max_splashes` are for a 1920 x 1080 screen and scale with the screen's area.
- **Drawing:** one texture per drop and per splash frame (`draw_texture`, `draw_texture_rect_region`), which the renderer batches; no shaders or particles, so the web export (Compatibility renderer) draws it the same.
- **Pause:** the default process mode, so the pause screen freezes it with the run.

## Placeholder look and T-509's swap

The placeholder is made in code once, at load: `make_drop_image()` (a 1-pixel streak `drop_length` long, leaning by `angle_deg`, in `drop_colour` with its lowest pixel in `drop_highlight_colour`) and `make_splash_image()` (three 7 x 4 frames side by side in `splash_colour`). Opaque pixels only (Visual style, "See-through rule"); none of Greenbull's colours.

To swap in art, set in `data/rain.json`:

- `drop_texture`: a `res://` path to the drop sprite (drawn with its top-left at the drop's place).
- `splash_texture`: a `res://` path to a horizontal strip of `splash_frames` equal frames, drawn centred on the splash's place, bottom row on it, one frame per equal slice of `splash_life`.

Nothing else changes; an empty path keeps the placeholder.

## The setting

`rain.gd` reads `GameSettings.load_rain_enabled()` when it starts and connects to `GameSettings.notifier.rain_enabled_changed`, so `GameSettings.save_rain_enabled(on)` shows or hides it in the same frame. `set_enabled(on)` does the same without saving. While off it is hidden, its processing is off, and it holds no drops, so it costs nothing.

## Cost

`bash game/tools/bench_rain.sh [--blocks=6] [--frames=300]` plays the game's run headless (car parked, weapons off, minions seeded), switches the rain on and off in alternating blocks through the saved setting, gives the rain a 1920 x 1080 screen's load, and prints the frame times with and without rain and the rain's own time per frame (`last_process_usec + last_draw_usec`). Headless uses the dummy renderer, so this is the CPU side only. T-507's numbers are in its result notes.

## The art (T-509)

`data/rain.json` names `drop_texture` (`res://art/rain/rain_drops.png`, a strip of `drop_variants` = 3 drops of 8 x 16) and `splash_texture` (`rain_splash.png`, a strip of `splash_frames` = 4 frames of 12 x 8, impact at the bottom middle). Each drop picks a variant at random. Empty texture names fall back to the code-drawn placeholder. Retuned for the art: 200 drops per 1080p screen (400 first, halved on the board's word), splash chance 0.45, most splashes 90, splash life 0.32 s. Frame time: `game/tools/bench_rain.sh`, rain's own work about 0.4 ms a frame, no measurable headless difference.
