# Collisions

(From the old `game/README.md`; the index is [../../README.md](../../README.md).)

## Car collisions

Task T-033. What the car does when it hits things is decided in Drifting, Decisions: it bounces slightly off walls (buildings and the map's edge) and boulders, and does not bounce off enemies, which only damage it. Minions and meteors knock it back (Enemies, Decisions).

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

When the car's 1 by 1 unit body hits anything on layer 1, it stops against it for that physics step, and the part of its velocity going into the surface is reversed and scaled by the wall bounce setting (`tuning.wall_bounce`, the tuning panel's "Wall bounce" slider). The part along the surface is kept, so after a glancing hit the car carries on along the wall while being pushed off it. 0 = no bounce (it slides along), 1 = it bounces back as fast as it hit. The proposed default is **0.25**: a head-on hit at cruise speed (11 units/s) bounces back at 2.75 units/s, one at top speed (33) at 8.25. The board judges it in a playtest. The Unity prototype has no bounce (report, section 3).

After the bounce the driving model carries on as usual. Holding W with the nose against the wall snaps the car back to cruise speed into it on the next step, so it stays pressed against the wall; let go of W, reverse or steer away to leave it. The drawn car (1 by 3 units) may overlap a wall or boulder: only the body collides.

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

From then on the push is ordinary speed: the part across the nose fades with the sideways grip (like a drift), the part along the nose changes the forward speed (with W held and the nose against the push, W snaps it back to cruise speed on the step after, as after a bounce), and a push into a wall bounces off it and emits `hit_obstacle`.

