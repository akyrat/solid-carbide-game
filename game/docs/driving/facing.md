# The car points where it goes (T-583)

The board's decision: Drifting, Decisions, "The car points where it goes". What T-580 found: Drifting, Content, "Facing versus travel (task T-580, investigation)". Two fixes, each switchable in `game/data/car_facing.json` (read once at start; restart the game after changing it).

## Fix A: the frame remap (`frame_remap`)

- `scripts/driving/car_facing.gd` (static). With the switch on, `car_sprite.gd` `frame_for_rotation()` draws a heading with the frame whose drawing points closest, on screen, to where that heading points in the run's 2:1 projection (screen = (x - y, (x + y) / 2)). Off: frame = round(heading / 11.25) as before (`index_frame_for_rotation()` always gives this one).
- Each frame's drawn screen angle is `seen_nose_screen_angle_deg_approx` in `game/art/car/car_iso.json` (T-102's measurement, checked by eye in T-580). A sheet without those angles (the flat placeholder) keeps the index rule.
- The shadowless sheet (in the air) and the tilt sheet (`car_iso_tilt`, its columns are the normal sheet's directions) use the same frame. The rail snap's outline (`car_outline.gd frame_for`) does too, so a rail catches the drawing the player sees.
- With the current art, frames 21 to 23 (all drawn pointing straight up) are used only for a narrow band of headings, and the screen's up-right diagonal is drawn with frame 24 (5 degrees off instead of 45). The biggest gap left is 23.5 degrees at world heading 239 (between frame 20 and 24's drawings); only redrawn art (T-584) closes it.
- **After a redraw** (T-584): `python game/tools/measure_car_facing.py --frames 19-23,2,3 --write` re-measures those frames and writes their angles (the long axis of the car's pixels without its shadow, calibrated by every other frame's recorded angle; leave-one-out on the T-102 sheet: mean error 3.2 degrees, worst 13). With no options it only reports. A frame that reads wrong by eye: `--set 22=300 --write`. Each changed frame records its `seen_source`.

## Fix C: the straight grip (`straight_grip_on`, `straight_grip`)

- `car_model.gd sideways_grip()`: on a step where W is held without A or D (driving straight under power, not a drift), the car keeps `straight_grip` (0.9) of its sideways speed per physics step instead of `drift_factor` (0.98, the Unity value). A slide halves in 0.13 s instead of 0.7 s, so after a turn the car goes where it points within about half a second of pressing W.
- Unchanged, exactly (tests): a held drift, its start included (W or S with A or D: the base grip stays `drift_factor`), and a coast (no W), steering or not, so the Polarized Steering Wheel's lift and steer still swings the nose 60 degrees and more off the travel. Out of a drift with W still held, the grip comes in as the drift amount falls (`drift_exit_rate`, 0.33 s), so a drift still slides out for about half a second.
- Why 0.9 (proposal for the playtest): with 0.95 and 0.93 the slide after a drift still lasts 0.7 to 1 s; 0.85 and 0.8 gain only about 0.1 s more and start to make W feel like rails. Every case's time is printed by `test_grip_candidates`.
- `reset_to_unity()` turns it off (the Unity car); `reset_to_defaults()` restores the data's value. No slider.

## Measuring

- `game/tests/unit/test_t583_facing_fixes.gd` checks both fixes and prints T-580's cases for none, A, C and A+C (search "T583"); the probe (`tests/helpers/facing_travel_probe.gd`, `set_combo()`) measures any combination whatever the data says, and T-580's own test still measures "none".
- Before and after pictures: `bash game/tools/record_t583_facing.sh` (needs a window) records the fixture `tests/fixtures/t580_facing_demo.tscn` with `T583_COMBO=none` and `AC` (or `AFTER=A` / `C`) and writes side-by-side GIFs and stills into `art-archive/T-583/screenshots/` (`game/tools/t583_before_after.py`).
