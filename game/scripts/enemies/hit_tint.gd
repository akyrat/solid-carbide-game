extends Node
class_name HitTint
## The brief red tint an enemy gets when it takes damage (task T-072; board, 2026-10-15:
## "the enemies get like a slight red hue very briefly when they take damage").
##
## A small reusable piece for any enemy that has a `sprite` (a CanvasItem): the minion uses it,
## and the kaiju can too. To use it:
##   var hit_tint = preload("res://scripts/enemies/hit_tint.gd").attach(self)   # once, in _ready()
##   hit_tint.flash()                                                           # in take_damage(), when still alive
## It tints the owner's `sprite` through `modulate` (a multiply, so it works on art or drawings)
## and puts it back by itself after DURATION seconds. It runs in _process, so pausing stops it.
##
## It never fights another tint on the same sprite (the flamethrower's orange burn flash, T-042):
## it does not start while the sprite already has a tint, and it only puts the colour back if
## the sprite still has its own red tint. So an orange flash always wins and is never cut short.
##
## Not Redgull red: TINT is a pale, pinkish red (about 62% green and blue left), well away from
## Redgull's (0.86, 0.1, 0.16).

const DURATION := 0.12
const TINT := Color(1.0, 0.62, 0.62, 1.0)

var _owner: Node = null
var _left := 0.0
var _sprite: CanvasItem = null


## Adds a HitTint node to `enemy` (which must have a `sprite` property) and returns it.
static func attach(enemy: Node) -> Node:
	var n: Node = load("res://scripts/enemies/hit_tint.gd").new()
	n.name = "HitTint"
	n._owner = enemy
	enemy.add_child(n)
	return n


## Starts the tint (call when the enemy takes damage and stays alive).
func flash() -> void:
	var s = _owner.get("sprite") if _owner != null else null
	if s == null or not is_instance_valid(s) or not (s is CanvasItem):
		return
	if s.modulate != Color.WHITE:
		return  # already tinted (for example the flamethrower's orange): leave it alone
	_sprite = s
	_sprite.modulate = TINT
	_left = DURATION


func is_active() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		_left = 0.0
		if _sprite != null and is_instance_valid(_sprite) and _sprite.modulate == TINT:
			_sprite.modulate = Color.WHITE
		_sprite = null
