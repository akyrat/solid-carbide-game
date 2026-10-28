# The kaiju

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## The kaiju

Task T-045 (Enemy Behavior Agent): Crash City's final boss as Enemies, Decisions describes it, with T-039's numbers (`kaiju` and, T-119, `kaiju_coins` in `data/enemies.json` through `EnemyData`). What it does: `docs/enemies.md`, Content, "The kaiju". A placeholder for now (a large dark slate green Godzilla-style shape drawn in code); the final art comes from a separate art task. Its meteor attack (T-046): "The meteor attack" below.

**See it:** start the game (F5) and press Start, or open `scenes/run/run.tscn` and press F6. With the playtest switch on (below) the kaiju walks in from a screen edge 30 seconds into the run; the starting gun (and the flamethrower, with T-042's `flamethrower_at_start` on) can kill it, which wins the run. Screenshot, from the repo root: `bash game/tools/screenshot.sh res://tests/fixtures/kaiju_demo.tscn screenshots/kaiju.png 20` (the kaiju beside the car in the gravel square, with a few minions, in a run started from the main menu; fixture script `tests/fixtures/kaiju_demo.gd`). A copy is in `art-archive/T-045/screenshots/`.

**Playtest switch: early arrival.** The boss time is 7 minutes in, so for playtests `data/playtest.json` (its other keys are other tasks' switches) can bring the kaiju's arrival forward:

```
"kaiju_early_arrival": { "enabled": true, "after_seconds": 30 }
```

With `enabled` true, the kaiju arrives `after_seconds` into the run instead of at the boss time. **To switch it back, set `"enabled": false`**: the kaiju then arrives at the boss time (7 minutes in, 1:00 left) as Enemies and Game loop architecture decide. A missing file or key is off too. Only the kaiju's arrival moves: the clock, the minions' growth and the `boss_time` signal stay as they are, and a later `boss_time` brings no second kaiju. It is on (30 s) for the board's playtest of T-045 and is set back to `false` right before T-045 merges (board, 2026-10-14). `KaijuBoss.read_early_arrival_seconds()` (in `kaiju_boss.gd`) reads it into `run.kaiju_boss.early_arrival_seconds` (-1 = off) when the run is made. Tests set the static `playtest_override` in `kaiju_boss.gd` (-1 = off, seconds = on, -2 = read the file), as T-042's tests do for the flamethrower.

**How it is built** (`scripts/enemies/`):

- `kaiju_boss.gd`: the run's kaiju. The run scene adds it as `run.kaiju_boss` (child `Kaiju`) and calls `bind(run)`. On the state's `boss_time` it makes the kaiju appear (`try_appear()`; once per run). It moves everything in `step(dt)`, once per physics step from `_physics_process` (pausable, so the pause screen and the level-up pause stop the kaiju and its damage), and does nothing once the run is over. On `run.world_rebuilt` (a new run) it removes the kaiju; it arrives again at that run's boss time. `enabled = false` stops it (tests).
- `kaiju.gd`: the kaiju, a `CharacterBody2D` in the run's `PhysicsWorld` (flat world pixels, 16 per unit) on layer 3 (`enemies`) with mask 1 (obstacles): a circle of `RADIUS_UNITS` (2.0, so 4 units across). It slides along walls, buildings and boulders and walks round one it meets head-on, as a minion does; it never pushes or blocks the car. In the groups `enemies` and `kaiju` (not `minions`).
- `kaiju_sprite.gd`: the kaiju's drawing in the isometric view, `HEIGHT_UNITS` (7) tall. **Final art (T-069):** 5 walk sheets in `art/kaiju/` (`kaiju_s/se/e/ne/n.png`, 6 frames of 224 x 224 side by side, 30 colours at most per sheet; south-west, west and north-west mirror south-east, east and north-east), drawn at scale 0.5 (so the 224-pixel canvas is the 7 units), the direction chosen from the way it walks (`compass_index`, as the minion's), the frame from the walk cycle (`frame_for`), feet on the ground point (`ART_FEET_Y`), the ground shadow kept. `drawn_height_px()` is the art's visible height (head top `ART_TOP_Y` to feet) so the health bar sits on its head; `drawn_width_px()` is unchanged. Without the sheets it draws the T-045 placeholder (left or right facing). The sheets: `python game/tools/build_kaiju_sheets.py` (free; from the 6 first frames of each `art-archive/T-069/walk_<dir>/`, one shared palette per sheet by `reduce_palette.py`), tests `tools/test_build_kaiju_sheets.py` and `tests/unit/enemies/test_kaiju_sprite.gd`. PixelLab record, review pictures and the one-round notes: `art-archive/T-069/`; the raw 8 rotations are there too. Screenshots and a GIF of it walking in a run (`tests/fixtures/kaiju_walk_demo.tscn`, `KAIJU_REC_DIR=<folder>` saves a picture every 4 frames): `art-archive/T-069/screenshots/`.

**Arrival:** at a random point on `arrival_ring()`, the visible screen (the camera's view) grown so that the whole drawing, its ground circle and its height, is `OFFSCREEN_MARGIN_UNITS` (1) beyond the screen's edge, inside the map and clear of buildings and boulders (`is_free_spot()`; 24 tries a step, else it tries again on the next step). `appear_at(units)` puts it at a given place (tests, fixtures).

**Movement:** straight towards the car's centre at `move_speed` (3 units/s).

**Contact damage:** as a minion's: it touches the car when its circle overlaps the car's 1 x 1 unit body (`touches_car()`); while touching, it hits once every `contact_damage_interval` (1 s), the first hit at once: `RunState.damage_car(contact_damage)` (20; this also cuts the combo) and `car.apply_knockback(away from the kaiju, knockback)` (16 units/s).

**Damaging the kaiju (for the weapon tasks, T-041 and T-042):** exactly as a minion, so a weapon that finds minions finds the kaiju too: `take_damage(amount: float)` on the kaiju node, the same points as `health` (500). It can be damaged at any time, as soon as it has appeared (no shield, no vulnerability windows). Zero or negative amounts, and calls on a dead kaiju, are ignored. It is in the `enemies` group and its body on layer 3, so `get_tree().get_nodes_in_group("enemies")` and a projectile's `Area2D` with a mask of 4 find it; it has `position_units()`, `health`, `max_health` and `is_dead()` like a minion. It is much bigger than a minion, so it also has `hit_radius_units()`, its body on the ground as a radius in units (`RADIUS_UNITS`, 2.0, its collision circle; the minion's body is 0.5). The weapons read it ("Weapons", Targets): the gun's bullets hit when they come within their hit radius of its body, and the flamethrower counts any overlap of the flames with its body as a hit (board, 2026-10-14; minions keep the centre rule). Check `is_dead()` before damaging one found earlier in the same frame.

**Health, for the HUD:** `run.kaiju_boss.kaiju` is the live kaiju (null before it appears and after it dies). The boss relays everything a HUD needs, so it can connect once:

| Signal or function | Is |
| --- | --- |
| `kaiju_appeared(kaiju: Node)` | The kaiju appeared (just off-screen) |
| `kaiju_health_changed(health: float, max_health: float)` | Once when it appears (full health), then on every hit |
| `kaiju_defeated(coins: int)` | It died, with the coins it added |
| `kaiju_health()`, `kaiju_max_health()`, `has_appeared()` | Its health now (0 when there is none), its full health, and whether it has appeared this run |

The kaiju node itself sends `health_changed(health, max_health)` on every hit and `died(kaiju, position_units)` once.

**Death:** at 0 health the kaiju dies once: `died` fires, it leaves the groups `enemies` and `kaiju` at once, its drawing goes, and the node is freed at the end of the frame. The boss then adds its coins, `EnemyData.kaiju_coins_on_defeat()` (10), through `RunState.add_coins()`, **before** calling `RunState.kaiju_killed()`, which ends the run as a win; so `run_ended("win", coins)` carries the kaiju's coins and they are saved with the run.

**Draw order:** the kaiju's drawing is in the minions' draw node (`run.minions.draw_root`, the Y-sorted `Enemies` node just before the car's `View`), placed every physics step on its body in the isometric view with a `z_index` from `enemy_depth.gd` (the map's rule for the car, as for the minions, with the kaiju's size).

**Not in the data:** the kaiju's size (4 units across, 7 tall) and the off-screen margin are in the code: sizes and rules of the placeholder, not balancing numbers.

**Tests:** `tests/unit/enemies/test_kaiju.gd`, part of the GUT suite: no kaiju before boss time; boss time bringing it just off-screen, clear of obstacles, walking towards the car at the data's speed, once per run; walking round a building; weapon damage through `take_damage()` lowering its health as soon as it appears, with both health signals; a projectile-style physics query on the enemies mask finding it; damage to 0 adding its coins before the run ends as a win, `kaiju_killed()` called once; contact damage at the data's rate and knockback away from it; no damage without touching; standing still while paused and after the run ends; a new run removing it and boss time bringing it back; the collision layers; the draw order; the placeholder's size and clear of the heart's red; `hit_radius_units()` matching its body; the starting gun hitting it, the flamethrower burning it when only its body overlaps the flames, and the gun killing it winning the run with its coins; the playtest switch (arrival at its time, once, again in a new run), reading its key beside other keys, and the committed file keeping both switches.

**The kaiju's health bar (task T-050):** `scripts/hud/kaiju_health_bar.gd` (`KaijuHealthBar`), `run.kaiju_health_bar`, a child of the world view like the trick popups. `bind(boss)` follows `kaiju_appeared` (shows), `kaiju_health_changed` (`fraction`, 0 to 1) and `kaiju_defeated` (hides); each physics step (priority after the boss's) it sits `GAP` above the kaiju sprite's head and takes its width from the sprite's `drawn_width_px()` and `drawn_height_px()`, so the final kaiju art only has to provide those two functions (the placeholder's width is its ground circle, 90 px). It hides when there is no kaiju (a new run). Neon purple `FILL_COLOR` on white, black outline (`OUTLINE` 2 px, stepped corners), a black 1 px divider at each of `DIVISIONS` (10) tenths, `BAR_HEIGHT` 8 px, whole pixels, no text. Absolute depth `CANVAS_ITEM_Z_MAX`, so buildings never cover it. Change to the kaiju's files: only the static `drawn_width_px()` in `kaiju_sprite.gd`. Test: `tests/unit/hud/test_kaiju_health_bar.gd`. Screenshot (copy in `art-archive/T-050/screenshots/`): `bash game/tools/screenshot.sh res://tests/fixtures/kaiju_bar_demo.tscn screenshots/kaiju_bar.png 20`.

