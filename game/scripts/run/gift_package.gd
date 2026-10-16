class_name GiftPackage
extends Node2D
## The gift pack's package (task T-144; Game loop architecture, Decisions,
## "Gift pack drop"). Carried by the helicopter, then falling, then landed on
## the map, where driving over it opens the level-up screen for its level.
## gift_drops.gd moves it and picks it up: this node holds its state and its
## drawing.
##
## The art: the child Sprite2D "Sprite" (res://scenes/run/gift_package.tscn).
## T-146 swaps its texture (now res://art/gift_pack/package_placeholder.png)
## and nothing else; the sprite's bottom stands on the node's origin, the
## landing spot.

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


## The sprite T-146 replaces.
func sprite() -> Sprite2D:
	return get_node("Sprite") as Sprite2D
