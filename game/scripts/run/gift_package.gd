class_name GiftPackage
extends Node2D
## The gift pack's package (task T-144; Game loop architecture, Decisions,
## "Gift pack drop"). Carried by the helicopter, then falling, then landed on
## the map, where driving over it opens the level-up screen for its level.
## gift_drops.gd moves it and picks it up: this node holds its state and its
## drawing.
##
## The art: the child Sprite2D "Sprite" (res://scenes/run/gift_package.tscn).
## T-146 swapped its texture (now res://art/gift_pack/package.png)
## and nothing else; the sprite's bottom stands on the node's origin, the
## landing spot.

## T-146's art: the box on the ground (also while carried), and the box under a
## parachute while it falls. Both stand on the node's origin (bottom row).
const GROUND_ART := "res://art/gift_pack/package.png"
const FALLING_ART := "res://art/gift_pack/package_falling.png"

const CARRIED := "carried"
const FALLING := "falling"
const LANDED := "landed"

## The level-up this package belongs to (its level-up screen's level).
var level := 0
## The landing spot in flat world pixels (the car's physics world) and in the
## isometric view's drawn pixels.
var ground_px := Vector2.ZERO
var drawn_ground := Vector2.ZERO
var phase := CARRIED
## Seconds since the drop, and the fall's length and height (gift_pack.json).
var fall_t := 0.0
var fall_seconds := 0.0
var drop_height := 0.0


func is_landed() -> bool:
	return phase == LANDED


func is_falling() -> bool:
	return phase == FALLING


## The landing spot in units from the map's centre.
func ground_units() -> Vector2:
	return ground_px / GiftDrops.PX_PER_UNIT


## How high above the landing spot it is now, in drawn pixels.
func height() -> float:
	return drawn_ground.y - position.y


## Picks the sprite's look from the phase (looks only; movement is gift_drops.gd).
func refresh_look() -> void:
	var path := FALLING_ART if phase == FALLING else GROUND_ART
	var s := sprite()
	if s.texture == null or s.texture.resource_path != path:
		s.texture = load(path)
		s.offset = Vector2(0, -48) if phase == FALLING else Vector2(0, -32)


func _process(_delta: float) -> void:
	refresh_look()


## The package's sprite (T-146's art).
func sprite() -> Sprite2D:
	return get_node("Sprite") as Sprite2D
