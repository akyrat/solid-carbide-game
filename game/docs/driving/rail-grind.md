# Rail grinding

(Task T-541, a prototype; the index is [../../README.md](../../README.md).) What it does and every proposed number: Drifting, Content, "Rail grinding (task T-541)". The rail format: Level design, Content, "Rails (task T-541)".

## The pieces

| File | What it does |
| --- | --- |
| `scripts/level/rails.gd` | Reads a level's `"rails"` list (`from_layout(layout)`), checks each entry (`problem(entry)`, "" when usable) and gives the geometry: `along`, `point_at`, `height_at`, `side_distance`. A rail is `{id, a, b, za, zb, length, dir}` (units; `dir` the unit vector a to b). Node-free. |
| `scripts/driving/rail_grind.gd` | The grind, node-free: `find(pos, vel, height, vz)` (the rail a car in the air catches), `start(info, heading)`, `set_steer(steer)`, `step(dt)` ("", "end" or "slow"), `stop(reason)`, `leave_velocity(reason)`, `touched_ground()`. Signals `grind_started(rail_index)` and `grind_ended(reason, seconds, length)`. Its numbers are constants at the top (proposals). |
| `scripts/driving/car.gd` | `car.grind` (a RailGrind; `car.grind.rails` empty: nothing changes). `physics_step()`: while grinding, `_grind_step(steer)` does the step (no driving, no collisions, no height step) and returns; when the grind ends that step (`_leave_grind`), the normal step carries on from the rail (the fall, or the Jump's hop). After the normal step's height step, a car in the air is checked with `grind.find()`, and on the ground `grind.touched_ground()`. |
| `scripts/driving/car_height.gd` | `set_on_rail(h)` (on the bar: not airborne, no vertical speed) and `leave_rail(vz)` (into the air, `took_off` sent). The Jump's `hop()` works from the bar as from the ground. |
| `scripts/level/rail_drawing.gd` | The placeholder look (Level design, Content, "Rails (task T-541)"): `build(map, rails, height_at, depth_for)` adds the drawing to `map.view_root`, a shadow node right after the ground tiles and one node per piece (`PIECE_UNITS` long at most) with `base_z = depth_for(mid, rail angle, bar height) - 1`; `update_for_car(units, height, car_z)` lifts the pieces just in front of a car under the bar over it. Each node's transform undoes the view's projection, so it draws in screen pixels (`screen_of(units, height)`). |
| `scripts/driving/rail_sparks.gd` | The sparks, in the run's car view (child `RailSparks` of View). `step(car, dt)` each physics step. |
| `scripts/run/run.gd` | `_build_rails()` with every map: the rails to `car.grind`, the drawing (`rail_drawing`, with the elevation layer's `z_for` as its depth), and `car.grind.grind_ended` to `state.add_grind_trick(seconds)`. `_on_car_rails_step()` after each car step: the sparks and `update_for_car`. |
| `scripts/run/run_state.gd` | `add_grind_trick(seconds)`: the combo up by `ComboData.grind_add(seconds)`, `combo_trick("rail_grind", added, multiplier)` (the GRIND! popup, `trick_popups.gd` TEXTS), the subs `ComboData.grind_subs(seconds)` times the multiplier before (`trick_subs_paid`). `jump_at_start()`: the playtest switch. |
| `data/combo.json` | `rail_grind`: `min_seconds`, `add_per_second`, `max_add`, `subs_per_second`, `max_subs`. |
| `data/playtest.json` | `jump_at_start`: the Jump tier every run starts with (0, off, on master). Tests override it with `RunState.jump_at_start_override`. |

The trick detector (`trick_detector.gd`) is not changed: while grinding the car is not airborne and not drifting, so a landing on a rail pays the air tricks and the airtime as any landing, and the grind's own trick is paid by the run from `grind_ended`.

## Tests

- `tests/unit/test_rail_grind.gd`: the format, locking on and not (across, rising, beside, too slow, above, under, past an end, on the ground), sliding and leaving at the end, backwards, too slow, Jump to a second rail, the rail left shut until the ground, paying the trick from combo.json, the popup text, the playtest switch, the posts and the projection.
- `tests/unit/run/test_run_rails.gd`: a run on the game's map: the rails reach the car, are drawn in the map's depth order, a Jump from the street lands on rail-3 and its grind pays GRIND!, and a Jump with D held hops from rail-3 to rail-4.

## Recordings

`tests/fixtures/rail_grind_gif.tscn` (script `rail_grind_gif_demo.gd`): a run on the game's map with Jump at tier 1, driving north from the spawn point: a hop onto rail-3, a grind, a Jump with D held onto rail-4, a grind to its end. `RAIL_SCENE=climb` plays rail-1 instead (off roof-12 up to roof-13). Record with Godot's movie maker and assemble with `make_turn_gif.py`:

```
"$GODOT_BIN" --path game --fixed-fps 50 --write-movie C:/abs/dir/f.png res://tests/fixtures/rail_grind_gif.tscn
python game/tools/make_turn_gif.py C:/abs/dir art-archive/T-541/screenshots/rail_jump.gif --glob "f*.png" --every 2 --size 640 420 --scale 1 --ms 40
```
