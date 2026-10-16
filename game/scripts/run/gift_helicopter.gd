class_name GiftHelicopter
extends Node2D
## The helicopter Redgull sends on a level-up (task T-144; Game loop
## architecture, Decisions, "Gift pack drop"). It flies across the screen from
## left to right in the isometric view's drawn pixels, carrying the package
## (GiftPackage), and drops it over the landing spot. gift_drops.gd moves it:
## this node only holds its path and its drawing.
##
## The art: the child Sprite2D "Sprite" (res://scenes/run/gift_helicopter.tscn).
## T-145 swaps its texture (now res://art/gift_pack/helicopter_placeholder.png)
## and nothing else; how it moves stays in gift_drops.gd.

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
