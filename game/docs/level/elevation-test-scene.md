# Elevation test scene

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Elevation test scene (T-182)

The elevation test scene (Level design, Decisions, "Raised areas and ramps"; Drifting, Decisions, "Elevation"). T-182 made the ground side (data and a query), T-183 and T-184 the car's height, T-185 the scene and its drawing ("The scene and its drawing (T-185)" below, with how to run it), T-186 the platform and ramp art, T-192 the round shadow (T-187's bigger-when-high option was tried and removed). Every number is a proposal for the board's playtest.

### Ground-height data

`game/data/level/elevation_test.json`, in flat-world units (x east, y south, so north is -y; the car's units). Two lists, so more can be added later (the level editor):

- `platforms`: each has `id`, an axis-aligned rectangle (`x`, `y` = its north-west corner, `w`, `h`) and `height` (units). Proposal: one platform, 16 by 16 units at (-8, -8), height 3.
- `ramps`: each has `id`, `platform` (the id it climbs), `side` (`north`, `east`, `south` or `west`: the platform side it climbs), a footprint rectangle (`x`, `y`, `w`, `h`) next to that side, `bottom_height` (0) and `top_height` (the platform's). The height rises in a straight line from the far end of the footprint (bottom) to the platform side (top). Proposal: one ramp on the east side, 12 by 8 units at (8, -4).
- Every platform side without a ramp (and the platform's sides beside a ramp) is a drop-off.

### The query

`scripts/level/ground_height.gd` (`GroundHeight`, a RefCounted with no nodes or physics). `GroundHeight.from_file(path = DEFAULT_PATH)` (or `new()` then `load_file(path)`, which returns false on a bad file and leaves the ground flat):

- `height_at(point: Vector2) -> float`: 0 off the platform, the platform's height on top, the straight rise along a ramp.
- `is_ramp(point) -> bool` and `ramp_at(point) -> Dictionary` (empty off a ramp).
- `edge_between(a, b) -> Dictionary`: `{"drop": bool, "height": float, "up": bool}`. `drop` is true when the move from a to b crosses a platform edge that is not a ramp; `height` is the step's size and `up` says it is a climb (from below). Moving along a ramp is never a drop.

Tests: `tests/unit/test_ground_height.gd`.

### The car's height (T-183)

`scripts/driving/car_height.gd`, a node-free model (Drifting, Decisions, "Elevation"). The car (`car.gd`) owns one in `height_model` and steps it once per physics step, after its flat step, with the flat position before and after and the flat velocity. It reads the ground from `car.ground` (a `GroundHeight`); with `ground` null (the drift prototype, the run) the height stays 0. The flat driving (50 steps per second, the Unity values) is not changed, in the air too: the car steers in the air exactly as on the ground (a proposal; the docs don't say). The drawing of the height: "The scene and its drawing (T-185)" below.

- `car.height` (units, up), `car.vertical_speed` (units/s, up positive, 0 on the ground), `car.airborne`. Signals on `height_model`: `took_off(from_ramp, vertical_speed)` and `landed(impact_vertical_speed)`.
- **On the ground** (the ramp included) the height is the ground's height under the car.
- **Takeoff at the ramp's top:** on the step the car goes from the ramp onto ground that is not ramp, climbing, at a flat speed of at least `RAMP_TAKEOFF_MIN_SPEED`, it leaves the ground with vertical speed `vz = (velocity . climb direction) x (top_height - bottom_height) / ramp length x RAMP_TAKEOFF_FACTOR` (the climb direction points from the ramp's foot to its top; ramp length is the footprint's size along it). Its height that step carries on along the slope's line: `height + vz x dt`. With the test scene's ramp (rise 3 over 12) at cruise speed, 11 units/s, that is 2.75 units/s. Slower, it just follows the ground onto the platform.
- **Takeoff at a drop-off edge:** on the step the car crosses a step down (a drop-off edge or, since T-184, a ramp's side; see "The platform's sides" below), it is in the air with vertical speed 0 (flat platform ground), at any speed, and falls.
- **In the air:** each step `vertical_speed -= GRAVITY x dt`, then `height += vertical_speed x dt`.
- **Landing:** when the height reaches the ground under the car, the height snaps to the ground and the vertical speed becomes 0.
- The platform's and the ramp's sides against the car: "The platform's sides (T-184)" below.

Every number, in one place at the top of `car_height.gd`, is a proposal for the board's playtest:

| Constant | Value | Meaning |
|---|---|---|
| `GRAVITY` | 12 units/s² | Pulls the vertical speed down in the air |
| `RAMP_TAKEOFF_MIN_SPEED` | 4 units/s | The slowest flat speed that leaves the ground at the ramp's top |
| `RAMP_TAKEOFF_FACTOR` | 1.0 | Share of the ramp's vertical speed kept at takeoff |
| `STEP_CLIMB_MAX` | 0.1 units | The biggest step of the ground driven over like a curb (T-184) |

Tests: `tests/unit/test_car_height.gd`.

### The platform's sides (T-184)

The proposals (Drifting, Content, "Elevation: the platform's sides"), all in `car_height.gd`'s `step`, which now returns what the sides did to the move:

- **The walk.** Each step, the move from the flat position before to the one after is walked in 0.05-unit pieces (`SAMPLE_STEP`) with the car's height along it: in the air, the straight line from the step's start height to its end height under gravity; on the ground, the ground's height. A piece that steps the ground **up** by more than `STEP_CLIMB_MAX` (a side, not a slope: the test ramp rises 0.0125 per piece) to more than `STEP_CLIMB_MAX` above the car is a **wall**: the walk stops at the last piece outside it. On the ground, the first piece that steps the ground **down** by more than `STEP_CLIMB_MAX` is a **drop**: the car takes off there (`took_off(false, 0)`) at its height before the step and falls. This replaces `edge_between` for the car (still in `GroundHeight`, unchanged), so a ramp's side is a drop too; driving along, up or down a ramp is neither.
- **A wall** (a drop-off edge from below, a ramp's side from beside it, or a platform's side met in the air below its top): `step` returns `{"wall": true, "point", "normal", "area", "wall_height", ...}`. `car.gd` moves the car to `point`, reflects its velocity off `normal` exactly as off a physics wall (`tuning.wall_bounce`, "Bounce") and emits `hit_obstacle(ground, area, normal, impact_speed)`: the collider is the `GroundHeight`, the shape index the area's index (`GroundHeight.area_index_at`: a platform's index in `platforms`, a ramp's `platforms.size()` + its index in `ramps`). Pressed against the side it counts once; it re-arms once the car is more than `REARM_GAP_UNITS` (0.25) from where it stopped, as for walls. The height is stepped as if the car had moved only to `point`, so a car in the air keeps falling beside the side.
- **Landing** is unchanged: when the height reaches the ground under the car's end position, on the top or on the street. Together with the walls, a step never ends with the car lower than the ground under it.
- `GroundHeight` adds `area_index_at(point) -> int`, `area_rect(index) -> Rect2` and `side_normal(index, a, b) -> Vector2` (the outward normal of the side a move from a, outside, to b, inside, enters through; at a corner the side crossed last).

Tests: `tests/unit/test_elevation_edges.gd`.

### The car's footprint (T-411)

Since T-411 the whole drawn car (1 wide, 3 long around its centre) meets the sides, not only its centre (Drifting, Content, "The car's footprint (task T-411)"):

- `car_height.gd`: `OUTLINE` is 10 points of the drawn outline (`HALF_LENGTH` 1.5, `HALF_WIDTH` 0.5; corners, nose and tail middles, and two points on each flank). `step(prev, pos, velocity, dt, rot_prev, rot_new)` takes the heading before and after the step; `car.gd` passes them. `_walk` walks every outline point with the centre, the heading turning evenly, in pieces short enough that no point moves more than `SAMPLE_STEP`. A point meets a side by the centre's rule, against its own ground: a step up of more than `STEP_CLIMB_MAX` to more than `STEP_CLIMB_MAX` above the car's body there, which is the car's height, along the ramp's slope when the centre is on a ramp (so the ramp the car is on is never a wall for its nose or tail). A wall returns `rotation` too, the heading at the last piece outside: `car.gd` puts the car back to it, so a turn into a side is stopped like a drive into it. Left out (`NAN`), only the centre is walked, as before.
- Falling off an edge and landing stay with the centre (the board's choice is open).
- Cost: only where a raised area is near. `GroundHeight.areas_near(box)` lists the areas touching the move's box grown by the outline's reach; `height_among(point, near)` and `area_among(point, near)` are `height_at` and `area_index_at` over those only. With none near, the outline is skipped. About 0.13 ms a step on the elevation sample map (test machine, busy).
- `drift_marks.gd`: `lay(drifting, position, rotation, car_height)` gets the car's height (`bind` passes it); a rear tyre whose ground is more than `STEP_CLIMB_MAX` below it (`overhangs`) lays nothing and its mark ends, and a new one starts when it is back on the ground.

Tests: `tests/unit/test_car_footprint_height.gd`, `tests/unit/test_drift_marks_overhang.gd`; `test_elevation_edges.gd`, `test_elevation_see_through.gd` and `test_elevation_sample_see_through.gd` now expect the centre to stop up to the outline's reach (1.58) from a side.

### The scene and its drawing (T-185)

The scene itself (Drifting, Content, "Elevation test scene"): `scenes/elevation_test/elevation_test.tscn`, script `scripts/driving/elevation_test.gd`. Not the main scene, not reachable from the menus, no on-screen text.

**Run it:** open the scene in the editor and press F6, or from the repo root `"$GODOT_BIN" --path game res://scenes/elevation_test/elevation_test.tscn`. W/S/A/D drive. The car starts at (26, 0) facing west (`START_UNITS`, `START_ROTATION`), in front of the ramp's foot.

How it is built (like the drift prototype, isometric only):

- `PhysicsWorld` (never drawn) holds the `Car` (`car.gd`), whose `ground` is the scene's `GroundHeight` (`ground_height`, from `data/level/elevation_test.json`). `place_car(units, rotation)` puts the car at rest on the ground there (the fixtures use it).
- `View` draws the street (`ground_grid.gd`, z_index -100), one `elevation_platform_drawing.gd` node per platform and ramp (`areas`, back to front), the `CarShadow` (`car_shadow.gd`), the `CarSprite` (`car_sprite.gd`, the final isometric sheet) and the `Camera`.
- `sync_view()` runs after every physics step (`car.stepped`): `car_sprite.place(drawn ground position, car.height)`, `shadow.place(map position, ground height under the car)`, `update_depth()`, then the camera (`camera_follow.gd`, as in the drift prototype) on the car's drawn position at height 0.

The drawing's main functions:

- `car_sprite.gd`: `lift_for_height(height_units, px_per_unit = 16) -> Vector2`, the lift straight up the screen (`(0, -height x 16)`); `place(drawn_ground_px, height_units)` sets the sprite's position to the drawn map position plus the lift. The lift is in the position, so physics interpolation smooths it.
- `car_shadow.gd` (round since T-192): `place(map_units, ground_height)` puts the shadow at the drawn map position lifted by the ground's height under the car; `outline()` is a 32-point circle on the ground, `DIAMETER_UNITS` (1.0 unit across, a proposal), run through the view's transform so it is an ellipse twice as wide as tall on screen, centred on the shadow's position; it does not turn with the car. Drawn in one opaque `COLOR`, no antialiasing. The car's drawing is always at the sheet's own scale, at every height.
- `elevation_platform_drawing.gd`: `setup(kind, block, view_basis)` with a `GroundHeight` platform or ramp; `corner_heights()` (NW, NE, SE, SW), `top_height_at(point)`, `top_face()`, `east_face()`, `south_face()` (drawn polygons; a side of height 0 has none); `colors_used()` lists every colour (clear of the heart's red); `is_behind(centre, radius, height)` is the depth rule: the centre west or north of the area's rectangle (the footprint, `radius` around it, not wholly east or south of it) and lower than its top there. The centre, not the footprint, since T-191: the sides stopped only the car's centre then, so at a back-side wall hit its footprint reached into the rectangle (since T-411 the drawn outline stops at the side and the centre waits up to 1.58 out; the centre rule still holds).
- `elevation_test.gd`: `z_for(centre, height, offset)` puts something just under the first area it is behind, or over every area (areas at z_index 3, 6, ...; the shadow at offset 0 under the car at offset 1); `update_depth()` places the shadow with the ground's height under the car and the car with its own height; `sync_view()` then calls `update_see_through(car.model.dt)` (see-through, T-191 below).

Every colour and size in the drawing is a proposal for the board's playtest. Tests: `tests/unit/test_elevation_drawing.gd`. Screenshot fixtures: `tests/fixtures/elevation_test_{ground,ramp,platform,air,behind}.tscn` and, for the round shadow (T-192; `lift_units` puts the car in the air), `elevation_test_shadow_{street,platform,air,platform_air}.tscn` (`elevation_test_demo.gd`: a start, W held for `drive_steps` physics steps, then the car stops), for example `bash game/tools/screenshot.sh res://tests/fixtures/elevation_test_air.tscn docs/drifting/elevation-air.png 90`.

### See-through raised areas (T-191)

The platform and the ramp turn see-through like the map's buildings (Drifting, Content, "Elevation test scene"; Level design, Content, "When a building fades") while they cover the car. The code is shared with the buildings, not copied:

- The numbers: each area's `see_through_alpha` and `fade_time` default to `mvp_map.gd`'s `SEE_THROUGH_ALPHA` (0.15) and `SEE_THROUGH_FADE_TIME` (0.15 s), the buildings' constants.
- The fade step: `map_building.gd`'s static `faded_alpha(a, covering, delta, see, time)`, which the buildings' `step_fade` now calls too.
- The car's shape on screen: `mvp_map.gd`'s static `car_screen_shape_at(centre, rotation, lift_px)` (the 1 by 3 unit car, 1 unit tall; `car_screen_shape` calls it with no lift). The scene lifts it by the car's height (`elevation_test.gd`, `car_shape()`).
- `elevation_platform_drawing.gd`: `silhouette()` (the convex hull of the top face and the ground corners, drawn pixels), `covers(centre, radius, height, car_shape)` (`is_behind` and the shapes overlap), `update_fade(centre, radius, height, car_shape, delta)` (sets `covering` and moves `modulate.a`; the art sprite is a child, so it fades with it), `alpha()`.
- `elevation_test.gd`: `update_see_through(delta)` updates every area with the car's position, height and shape, after every physics step (from `sync_view`); `covering_areas()` lists the areas covering the car.

Tests: `tests/unit/test_elevation_see_through.gd` (the fade and its numbers; driving into the west and north sides straight, angled and steering, the car under the platform on every step). Screenshot fixtures: `tests/fixtures/elevation_test_see_through.tscn` (behind the platform), `elevation_test_wall_west.tscn` and `elevation_test_wall_north.tscn` (the step the car meets each back side), and `elevation_test_wall_{west,north}_solid.tscn` (the same with the fade off, `elevation_test_demo.gd`'s `see_through = false`, to show the depth order alone).

### The round shadow, and no bigger-when-high (T-192)

The board tried drawing the car bigger when high (T-187) and removed it: `draw_bigger_when_high`, `HEIGHT_SCALE_PER_UNIT`, `height_scale_per_unit` and `scale_factor_for_height` are gone, and the car is drawn at the sheet's own scale at every height. The shadow is a round shadow instead (`car_shadow.gd`, above): a 1-unit circle on the ground under the car's map position, an ellipse twice as wide as tall on screen, not turning with the car. Tests: `tests/unit/test_elevation_drawing.gd` (`test_the_cars_drawing_scale_is_the_same_at_every_height`, `test_the_shadow_*`). Screenshots: `art-archive/T-192/screenshots/`.

**The shadow on raised ground (T-258).** In the run and the level creator's runs (`run.gd` `_sync_view_elevation`, `elevation_sample_map.gd` `update_depth`) the shadow's depth is `elevation_layer.gd` `shadow_z_for(units, rot, height, ground_h)`: under the car, under the buildings and boulders that cover it, but under a rooftop or ramp only while the car itself is under it (`z_for(..., include_areas = false)` for the ground part). Before, the shadow took the depth of the ground height alone, so a car in the air drawn over a rooftop or ramp (flying in from behind it or off its edge) had its shadow drawn under that area and lost. Test: `tests/unit/run/test_run_shadow_on_raised_ground.gd`; screenshots and a GIF of a 6 to 3 jump: `art-archive/T-258/screenshots/` (fixtures `tests/fixtures/run_shadow_air_*.tscn`, `run_shadow_jump_6_to_3.tscn`). The elevation test scene (`elevation_test.gd` `update_depth`) uses the same rule (under the car, and under an area only while the car is); `test_elevation_drawing.gd` `test_the_car_above_the_platform_behind_it_is_over_it_and_so_is_its_shadow` was changed to expect it.

### The platform and ramp art (T-186)

PixelLab art replaces the script drawing: `art/elevation/platform.png` (1024 x 608) and `ramp.png` (640 x 416), each with its record (`platform.json`, `ramp.json`: sources, `top_left_art_px` from the drawn origin, 32 art px per unit). `elevation_platform_drawing.gd` adds a `Sprite2D` (`art_sprite`, scale 0.5, nearest filter, at `top_left_art_px` x 0.5) when the PNG and record exist, and then draws nothing itself; the script drawing stays as the fallback, and its geometry functions and the depth order (`is_behind`) are unchanged.

Made from 3 PixelLab textures (art-archive/T-186/, 3 generations) by `python game/tools/build_elevation_art.py build` (projects them onto the faces of `data/level/elevation_test.json`; `check` runs the rules on the committed files; run `build` again if the JSON's sizes change). Tests: `game/tools/test_build_elevation_art.py` (Python) and `tests/unit/test_elevation_art.gd`. Screenshots: `docs/drifting/elevation-final-art.png` (car at the platform's edge, in the air) and `elevation-final-art-platform.png` (on the platform).

