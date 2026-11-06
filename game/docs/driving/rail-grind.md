# Rail grinding

(Task T-541, a prototype; the index is [../../README.md](../../README.md).) What it does and every proposed number: Drifting, Content, "Rail grinding (task T-541)". The rail format: Level design, Content, "Rails (task T-541)".

## The pieces

| File | What it does |
| --- | --- |
| `scripts/level/rails.gd` | Reads a level's `"rails"` list (`from_layout(layout)`), checks each entry (`problem(entry)`, "" when usable) and gives the geometry: `along`, `point_at`, `height_at`, `side_distance`. A rail is `{id, a, b, za, zb, length, dir}` (units; `dir` the unit vector a to b). Node-free. |
| `scripts/driving/rail_grind.gd` | The grind, node-free: `find(pos, vel, height, vz)` (the rail a car in the air catches), `start(info, heading)` (adds the landing boost `land_boost` to the speed and sets `boost_left`, T-548), `turn(steer, rate_deg, dt)` (A and D spin `body_heading` at the air turn rate, the board's tweak of 2026-11-06), `step(dt)` ("", "end" or "slow"; the speed loses `decel` a second, and the boost's part `boost_left` another `boost_decline` a second until it is gone), `stop(reason)`, `nose_side()` (+1 nose left of the rail line, -1 right, 0 along it), `leave_velocity(reason)` (a jump along the nose, `body_heading`, at `jump_speed`, whatever the travel, T-548; a slow drop pushed toward `nose_side()`), `touched_ground()`. Signals `grind_started(rail_index)` and `grind_ended(reason, seconds, length)`. Its numbers come from `data/rail_grind.json` (`load_numbers()`, with `DEFAULTS`). |
| `scripts/driving/car.gd` | `car.grind` (a RailGrind; `car.grind.rails` empty: nothing changes). `physics_step()`: while grinding, `_grind_step(steer)` does the step (no driving, no collisions, no height step) and returns; when the grind ends that step (`_leave_grind`), the normal step carries on from the rail (the fall, or the Jump's hop). After the normal step's height step, a car in the air is checked with `grind.find()`, and on the ground `grind.touched_ground()`. |
| `scripts/driving/car_height.gd` | `set_on_rail(h)` (on the bar: not airborne, no vertical speed) and `leave_rail(vz)` (into the air, `took_off` sent). The Jump's `hop()` works from the bar as from the ground. |
| `scripts/driving/jump_power_up.gd` | `hop_off_rail(height_model)` (quick tuning 2): the Jump off a rail, at the tier's takeoff speed, ignoring the cooldown and leaving it as it was. `car._leave_grind("jump")` calls it and uses up the press. |
| `scripts/level/rail_drawing.gd` | The placeholder look (Level design, Content, "Rails (task T-541)"): `build(map, rails, height_at, depth_for)` adds the drawing to `map.view_root`, a shadow node right after the ground tiles and one node per piece (`PIECE_UNITS` long at most) with `base_z = depth_for(mid, rail angle, bar height) - 1`; `update_for_car(units, height, car_z)` lifts the pieces just in front of a car under the bar over it. Each node's transform undoes the view's projection, so it draws in screen pixels (`screen_of(units, height)`). |
| `scripts/driving/rail_sparks.gd` | The sparks, in the run's car view (child `RailSparks` of View). `step(car, dt)` each physics step. |
| `scripts/run/run.gd` | `_build_rails()` with every map: the rails to `car.grind`, the drawing (`rail_drawing`, with the elevation layer's `z_for` as its depth), and `car.grind.grind_ended` to `state.add_grind_trick(seconds)`. `_on_car_rails_step()` after each car step: the sparks and `update_for_car`. |
| `scripts/run/run_state.gd` | `add_grind_trick(seconds)`: the combo up by `ComboData.grind_add(seconds)`, `combo_trick("rail_grind", added, multiplier)` (the GRIND! popup, `trick_popups.gd` TEXTS), the subs `ComboData.grind_subs(seconds)` times the multiplier before (`trick_subs_paid`). `jump_at_start()`: the playtest switch. |
| `rail_grind.gd` joints (T-542 round 2) | `joint_at_end()` finds the connected rail past the end the car leaves by (`join_distance`, `join_height`, `join_max_angle_deg`); `step()` crosses to it (`_cross_joint`, counted in `joints`) with the speed untouched and the rest of the step carried along it; `rail`, `rail_index`, `direction` and `s` switch to the new piece. |
| `data/rail_grind.json` | The grind's numbers (proposals; each explained in its `_comment` lines): `reach`, `end_margin`, `catch_above`, `catch_below`, `min_start_speed`, `max_angle_deg`, `decel`, `end_speed`, `drop_side_speed`, `land_boost`, `boost_decline`, `jump_speed` (T-548; `jump_angle_deg` is gone), `join_distance`, `join_height`, `join_max_angle_deg` (`catch_above` is 1.0 since T-542 round 2). |
| `data/combo.json` | `rail_grind`: `min_seconds`, `add_per_second`, `max_add`, `subs_per_second`, `max_subs`. |
| `data/playtest.json` | `jump_at_start`: the Jump tier every run starts with (0, off, on master). Tests override it with `RunState.jump_at_start_override`. |

The trick detector (`trick_detector.gd`) is not changed: while grinding the car is not airborne and not drifting, so a landing on a rail pays the air tricks and the airtime as any landing, and the grind's own trick is paid by the run from `grind_ended`.

## Tests

- `tests/unit/test_rail_grind.gd`: the format, locking on and not (across, rising, beside, too slow, above, under, past an end, on the ground), sliding and leaving at the end, backwards, too slow, Jump to a second rail (the nose turned 40 degrees toward it), A and D spinning the car at the air turn rate on the rail, the jump along the nose at `jump_speed` (forwards, sideways, backwards; a car turned 180 degrees jumps off against its travel), the landing boost and its decline, every landing boosting again, a joint adding no boost, the no-cooldown rail jump, the numbers from rail_grind.json, the rail left shut until the ground, paying the trick from combo.json, the popup text, the playtest switch, the posts and the projection.
- `tests/unit/test_rail_joints_and_heights.gd` (T-542 round 2): a joint at 30 and 90 degrees keeps the speed of a straight rail, one grind across a joint, which rail is connected (distance, height, fold-back, fork), the numbers in the data file, a hop from the street, a 3 and a 6 rooftop is caught for the same steps, lock-on distance and angle equal on a platform, real heights compared, the per-piece shadow on raised ground.
- `tests/unit/run/test_run_rails.gd`: a run on the game's map: the rails reach the car, are drawn in the map's depth order, a Jump from the street lands on rail-3 and its grind pays GRIND!, and a Jump with the nose turned 40 degrees right by D hops from rail-3 to rail-4.

## Recordings

`tests/fixtures/rail_grind_gif.tscn` (script `rail_grind_gif_demo.gd`): a run on the game's map with Jump at tier 1, driving north from the spawn point: a hop onto rail-3, a grind, D turning the nose about 25 degrees right of the rail, a Jump slightly to the right onto rail-4, a grind to its end. `RAIL_SCENE=climb` plays rail-1 instead (off roof-12 up to roof-13). Record with Godot's movie maker and assemble with `make_turn_gif.py`:

```
"$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/rail_grind_gif.tscn
python game/tools/make_turn_gif.py C:/abs/dir art-archive/T-541/screenshots/rail_jump.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40
```

T-548 (the landing boost and the Jump along the nose): `tests/fixtures/t548_rail_gif.tscn` (script `t548_rail_gif_demo.gd`), a run on the game's map with rail-3 and rail-4 added (a copy in `user://`, since the map has no rails of its own), with a recording readout of the speed along the rail and the boost left. `T548_SCENE=boost` (default): a hop onto rail-3 (the speed jumps by the boost and declines), D turning the nose 40 degrees right, a Jump along it onto rail-4 (boosted again). `T548_SCENE=back`: D spins the car round on rail-3 and the Jump sends it off backwards. Recorded and assembled as above; the GIFs are in `art-archive/T-548/screenshots/`.
