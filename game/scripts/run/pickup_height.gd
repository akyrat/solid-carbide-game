class_name PickupHeight
extends RefCounted
## Pickups and heights (task T-402; Game loop architecture, Decisions, "Gift pack drop" and
## "Pickup magnet"; the board, 2026-10-30: every pickup is drawn and picked up at the height it
## is at). One rule for the gift package, coins and health pickups: a pickup lies at the height of
## the ground under it (a rooftop's on a rooftop), and the car picks it up only when its own height
## is at least that less TOLERANCE, so a car on the street beside a rooftop does not pick up what
## lies on it, and a car jumping over a pickup on the street still does. The pickup magnet reaches
## only pickups on the level the car is on (the ground under the car, within TOLERANCE).

## Units of height.
const TOLERANCE := 0.5


## True when a car at `car_height` (units) can pick up a pickup lying at `pickup_height`.
static func car_reaches(car_height: float, pickup_height: float) -> bool:
	return car_height >= pickup_height - TOLERANCE


## True when two ground heights are the same level (within TOLERANCE).
static func same_level(a: float, b: float) -> bool:
	return absf(a - b) <= TOLERANCE


## A node's `height` (the car's, units), or 0 when it has none.
static func height_of(node: Object) -> float:
	if node == null:
		return 0.0
	var h = node.get("height")
	return float(h) if h != null else 0.0


## The ground's height at `units` from a GroundHeight (ground_height.gd), or 0 without one.
static func ground_at(ground, units: Vector2) -> float:
	return ground.height_at(units) if ground != null else 0.0
