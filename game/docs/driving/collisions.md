# Collisions

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Car collisions

Task T-033. What the car does when it hits things is decided in Drifting, Decisions: it bounces off walls (buildings and the map's edge), raised areas' sides and boulders, even with W held ("The car bounces off walls", 2026-10-30, task T-435), and does not bounce off enemies, which only damage it. Minions and meteors knock it back (Enemies, Decisions).

### Collision layers

Every task that adds physics bodies uses these layers. They are named in `project.godot` (Project Settings, Layer Names, 2D Physics), and `scripts/driving/car.gd` has them as constants (`LAYER_OBSTACLES`, `LAYER_CAR`, `LAYER_ENEMIES`, `LAYER_PICKUPS`).

| Layer | Bit value | Name | What is on it | Set up as |
| --- | --- | --- | --- | --- |
| 1 | 1 | `obstacles` | Walls, buildings, the map's edge and boulders: everything the car bounces off. The MVP map's `Walls` and `Boulders_*` bodies, and the drift prototype's test room | `StaticBody2D` on layer 1, mask none |
| 2 | 2 | `car` | The player's car (`car.gd`) | Layer 2, mask 1: it collides only with obstacles |
| 3 | 4 | `enemies` | Minions, the kaiju, meteors | Layer 3. Their mask must not include layer 2, so they and the car never push each other. To touch or damage the car, use an `Area2D` whose mask includes layer 2 (the minions measure their overlap with the car's body themselves instead, see "Minions") |
| 4 | 8 | `pickups` | Coins and other pickups | `Area2D` on layer 4 with mask 2, to notice the car driving over it |

Walls and boulders share layer 1 because the MVP map builds them that way and the car treats them the same. To tell them apart (for example in the combo), use the body `hit_obstacle` reports: on the MVP map, `map.walls` is the buildings and the edge, `map.boulder_bodies` the pattern copies' boulders and `map.meteor_boulder_bodies` the boulders meteors left. The starting gun's bullets have no physics body and no layer: they find enemies through the group `enemies` (see "Weapons"). A weapon that does need a body or an `Area2D` adds a layer (the next free number) to this table.

### Bounce

When the car's 1 by 1 unit body hits anything on layer 1 (or the drawn car meets a raised area's side, task T-184/T-411), it stops against it for that physics step, and the part of its velocity going into the surface is replaced by a bounce away from it: the hit speed (the speed into the surface), capped at `tuning.wall_bounce_max_hit_speed`, times `tuning.wall_bounce`. The part along the surface is kept, so after a glancing hit the car carries on along the wall while bouncing off it. `car.gd`, `_reflect()`.

**Why the car used to stick (task T-435).** After the bounce, W held with the forward speed below cruise speed snapped the forward speed straight back to cruise (`car_model.gd`, step 5) on the very next step, before the car had moved: a head-on bounce (forward speed negative) became cruise speed into the wall again, and a glancing or drifting hit lost its bounce the same way, so the car stayed pressed against the wall and a held drift kept climbing on it.

**How the bounce wins over W (task T-435).** Each bounce sets `CarModel.bounce_normal` (the wall's normal). While it is set and the nose points into that wall, W with the forward speed below cruise does not snap: it speeds the car up at `tuning.wall_bounce_pull` units/s per second. So the bounce first carries the car away from the wall, then W slows it and brings it back, like a ball; the next touch bounces again, smaller. W always acts: there is no timer and no time when W does nothing. The bounce ends (and W snaps again as before) when the forward speed is back at cruise speed, when W is let go or S reverses, or when the nose turns away from the wall. While a bounce runs, touching the same wall or boulder again is the same hit (no second `hit_obstacle`, so no second combo cut); the 0.25-unit re-arm rule below still applies otherwise. **A wall hit ends the drift (task T-438).** Any bounce with a speed into the surface (`_reflect()` above 0, a wall, building, boulder, map edge or a raised area's side) clears `model.is_drifting` on that step (`car.gd`, `_end_drift_on_hit()`), after `hit_obstacle` is emitted. The drift amount fades as when the player lets go, and the keys are not touched, so a player still holding W and A drifts again on the next step. The trick detector then sees the drift end on the hit step and pays it once, for the time up to the hit; in a run the crash's `settle_tricks()` has already paid it, before the combo cut (`combo.json`'s `crash_pays_trick_first`, true), and the cut applies once. A knockback that pushes the car into a wall does the same. Tests: `tests/unit/test_wall_hit_ends_drift.gd`.

| Setting (Collisions group on the tuning panel) | Key | Proposed default (for the playtest) |
| --- | --- | --- |
| Wall bounce | `wall_bounce` | **0.4** (was 0.25) |
| Wall bounce: hardest hit | `wall_bounce_max_hit_speed` | **16.5 units/s** (the top speed) |
| Wall bounce: W pull-back | `wall_bounce_pull` | **12 units/s per second** |

**Bouncy Bumpers (T-462).** With the power-up owned, `car.gd`'s `set_bouncy_bumpers_tier(tier)` (the run calls it from `RunState.power_up_tier("bouncy_bumpers")`, next to Jump and Rev Charge) reads the tier's `bounce_distance_multiplier` from `power_ups.json`. `_reflect()` multiplies the bounce speed (which already includes the hardest-hit cap, so the maximum scales too) by `sqrt(multiplier)`, so the distance grows by the multiplier itself; the re-arm reach uses the same scaled bounce. Tier 0 leaves the multiplier at 1.0, and the bounce is today's. Tests: `tests/unit/test_bouncy_bumpers.gd`.

With these, holding W, a head-on hit at cruise speed (11 units/s) bounces back at 4.4 units/s and travels about 0.9 units from the wall before W brings it back; one at top speed (16.5) or faster bounces back at 6.6 units/s, about 1.75 units. A faster hit (the hype speed bonus, a knockback into a wall) bounces no further. With W let go the car rolls away with its normal coasting. The Unity prototype has no bounce (report, section 3). The drawn car (1 by 3 units) may overlap a wall or boulder: only the body collides. Tests: `tests/unit/test_wall_bounce.gd`.

### Collision signal

```
signal hit_obstacle(collider: Object, shape_index: int, normal: Vector2, impact_speed: float)
```

The car emits it once per hit on anything on layer 1, for the combo (task T-081). `collider` is the `StaticBody2D` hit and `shape_index` which of its shapes (which building or boulder); `normal` is the surface normal, pointing out of the obstacle towards the car; `impact_speed` is the car's speed into the surface in units per second, before the bounce. Staying pressed against the same obstacle is one hit: it counts again only once the car has been more than 0.25 units away from it (`REARM_GAP_UNITS`).

### Knockback

```
func apply_knockback(direction: Vector2, strength: float) -> void
```

Call it on the car node to knock the car back, for example for a minion hit or a meteor impact (Enemy Behavior Agent; the strengths are game data). `direction` is in the flat physics world (x right, y down) and does not need to be normalized; a zero direction is ignored. `strength` is a speed in units per second. On the car's next physics step, after the driving model's own update, `direction.normalized() * strength` is added to the car's velocity. Several calls before one step add up. `pending_knockback()` returns what is waiting.

From then on the push is ordinary speed: the part across the nose fades with the sideways grip (like a drift), the part along the nose changes the forward speed (with W held and the nose against the push, W snaps it back to cruise speed on the step after), and a push into a wall bounces off it and emits `hit_obstacle`.

