class_name GiftHelicopter
extends Node2D
## The helicopter Redgull sends on a level-up (task T-144; Game loop
## architecture, Decisions, "Gift pack drop"). It flies across the screen from
## left to right in the isometric view's drawn pixels, carrying the package
## (GiftPackage), and drops it over the landing spot. gift_drops.gd moves it:
## this node only holds its path and its drawing.
##
## The art: the child Sprite2D "Sprite" (res://scenes/run/gift_helicopter.tscn).
## T-145 swapped its texture for the final art (res://art/gift_pack/helicopter_sheet.png,
## 4 rotor frames of 192 x 160, drawn at scale 0.5); how it moves stays in gift_drops.gd.

## The rotor spin: frames per second (art only, no effect on the flight).
const ROTOR_FPS := 24.0
var _rotor_time := 0.0


func _process(delta: float) -> void:
	_rotor_time += delta
	var s := sprite()
	if s != null and s.hframes > 1:
		s.frame = int(_rotor_time * ROTOR_FPS) % s.hframes


## Where it starts and ends (drawn x), and where it drops the package.
var from_x := 0.0
var to_x := 0.0
var drop_x := 0.0
## Drawn pixels per second (gift_pack.json).
var speed := 0.0
## The package it carries; null once dropped.
var package: GiftPackage = null
var dropped := false


## The sprite T-145 replaces.
func sprite() -> Sprite2D:
	return get_node("Sprite") as Sprite2D
