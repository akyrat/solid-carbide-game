extends Node
## The Polarized Steering Wheel's tier 4 shock (task T-502; Drifting, Decisions,
## "Rusty Paintjob and the Polarized Steering Wheel"). Each burst at tier 4 sets off
## Bricks' normal wave where the car is: the wave of Bricks' tier `shock_bricks_tier`
## (1: radius 4, damage 6, minions pushed 4, the kaiju damaged and never pushed),
## whether or not the car owns Bricks.
##
## It reuses Bricks' own code: it keeps its own Bricks node (bricks.gd), never on the
## rack's list (so it is never stepped, levelled up or owned), bound to the run's
## weapon rack for its enemies, its height levels, its damage bonus and its
## projectiles; send_wave() does the hits, the pushes and the drawing (Bricks' r4
## wave sheet). Its numbers are read from weapons.json at each shock, so the car
## owning Bricks at any tier never changes the shock. The hits are credited to
## "polarized_steering_wheel" (the recap's weapon kills stay Bricks' own).
##
## The run makes it (child "PolarizedShock") and calls bind(rack, car).

const BricksScript := preload("res://scripts/weapons/bricks.gd")
const SOURCE := "polarized_steering_wheel"

## A shock went out at `centre` (flat world, units) and hit `hit_count` enemies.
signal shock_sent(centre: Vector2, hit_count: int)

## The Bricks node that sends the wave (not on the rack's list).
var bricks: Node = null
var rack: Node = null
var car: Node = null
## Shocks sent (tests).
var shocks := 0


func _init() -> void:
	bricks = BricksScript.new()
	bricks.name = "ShockBricks"
	bricks.weapon_id = SOURCE
	add_child(bricks)


## Binds to the run's weapon rack and car: every tier 4 burst of the car's
## Polarized Steering Wheel sends a wave.
func bind(the_rack: Node, the_car: Node) -> void:
	rack = the_rack
	car = the_car
	bricks.rack = the_rack
	if the_car != null and not the_car.polarized.shock.is_connected(send):
		the_car.polarized.shock.connect(send)


## One wave at `centre` (flat world, units) with Bricks' tier `bricks_tier`
## numbers (the garage damage bonus applies, as to every weapon). Returns the
## enemies hit.
func send(centre: Vector2, bricks_tier: int = -1) -> Array:
	if rack == null:
		return []
	var t := bricks_tier
	if t < 1:
		t = car.polarized.shock_bricks_tier if car != null else 1
	t = maxi(t, 1)
	var stats: Dictionary = bricks.data.bricks_at(t)
	stats["damage"] = bricks.boosted_damage(float(stats["damage"]))
	bricks.stats = stats
	var hit: Array = bricks.send_wave(centre)
	shocks += 1
	shock_sent.emit(centre, hit.size())
	return hit


## The last wave drawn (a BricksWave), for tests and screenshots.
func last_wave() -> Node2D:
	return bricks.last_wave
