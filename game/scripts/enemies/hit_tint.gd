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
## and puts it back by itself after hit_flash.seconds (run.json). It runs in _process, so pausing stops it.
##
## It never fights another tint on the same sprite (the flamethrower's orange burn flash, T-042):
## it does not start while the sprite already has a tint, and it only puts the colour back if
## the sprite still has its own red tint. So an orange flash always wins and is never cut short.
##
## T-404 (board, 2026-10-30, "same for the enemies"): it is now the car's red flash, T-403's HitFlash,
## same length and colour from run.json. It replaces the pale 0.12 s tint of T-072. Cheap: one small
## HitFlash per enemy, no material, and _process runs only while a flash lasts.

## Shared by every enemy: the length and colour are read from run.json once (not per enemy).
static var _proto: HitFlash = null

var _owner: Node = null
var _flash: HitFlash = null
var _sprite: CanvasItem = null


## The shared numbers (T-404): run.json's hit_flash, read once.
static func proto() -> HitFlash:
	if _proto == null:
		_proto = HitFlash.from_data()
	return _proto


## Adds a HitTint node to `enemy` (which must have a `sprite` property) and returns it.
static func attach(enemy: Node) -> Node:
	var n: Node = load("res://scripts/enemies/hit_tint.gd").new()
	n.name = "HitTint"
	n._owner = enemy
	n.set_process(false)
	enemy.add_child(n)
	return n


## Starts the flash (call when the enemy takes damage and stays alive; a kill skips it,
## the enemy is gone at once).
func flash() -> void:
	var s = _owner.get("sprite") if _owner != null else null
	if s == null or not is_instance_valid(s) or not (s is CanvasItem):
		return
	if s.modulate != Color.WHITE and not (_flash != null and _flash.is_active()):
		return  # already tinted (for example the flamethrower's orange): leave it alone
	if _flash == null:
		_flash = HitFlash.new()
		_flash.seconds = proto().seconds
		_flash.color = proto().color
	_sprite = s
	_flash.trigger()
	_flash.apply_to(_sprite)
	set_process(true)


func is_active() -> bool:
	return _flash != null and _flash.is_active()


func _process(delta: float) -> void:
	if _flash == null or not _flash.is_active():
		set_process(false)
		return
	_flash.advance(delta)
	if not _flash.is_active():
		if _sprite != null and is_instance_valid(_sprite) and _sprite.modulate == _flash.color:
			_sprite.modulate = Color.WHITE
		_sprite = null
		set_process(false)
