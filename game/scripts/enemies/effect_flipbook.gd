extends Sprite2D
## A one-shot effect drawn from a one-row sheet (task T-072): enemy hit, enemy
## death and car damage. It plays its frames once at `fps`, then frees itself.
## The frames pop and shrink away in the art itself; nothing here fades.
## It advances in _process, so pausing the tree pauses it.

const ART_DIR := "res://art/effects/"

var fps := 14.0
var _t := 0.0


## Makes a flipbook of the sheet `sheet_name` (e.g. "enemy_hit") with `frames` frames.
static func make(sheet_name: String, frames: int, frames_per_second: float = 14.0) -> Sprite2D:
	var s: Sprite2D = load("res://scripts/enemies/effect_flipbook.gd").new()
	s.texture = load(ART_DIR + sheet_name + ".png")
	s.hframes = frames
	s.frame = 0
	s.fps = frames_per_second
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return s


func _process(delta: float) -> void:
	_t += delta
	var f := int(_t * fps)
	if f >= hframes:
		queue_free()
		return
	frame = f
