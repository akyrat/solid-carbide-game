class_name HitFlash
extends RefCounted
## A red flash for anything that takes damage (T-403; Game loop architecture,
## Decisions, "A red flash when the car takes damage"). One small helper, so the
## car and the enemies (T-404) flash the same way.
##
## Use: make one per thing, call trigger() when it takes a hit that counts,
## advance(delta) every step (or frame), and apply_to(canvas_item) after, which
## sets the item's modulate to the flash colour while it lasts and back to white
## after. A hit while flashing restarts the flash. Length and colour come from
## run.json's hit_flash section (RunData.hit_flash_seconds() / hit_flash_color()).
## The flash only tints: whether the thing is drawn (the car's blink) is not its job.

var seconds: float = 0.4
var color: Color = Color(1.0, 0.25, 0.25)
var left: float = 0.0


## A flash with run.json's length and colour.
static func from_data(run_data: RunData = null) -> HitFlash:
	var d := run_data if run_data != null else RunData.new()
	var flash := HitFlash.new()
	flash.seconds = d.hit_flash_seconds()
	flash.color = d.hit_flash_color()
	return flash


## Starts (or restarts) the flash.
func trigger() -> void:
	left = seconds


## Moves the flash on by `delta` seconds.
func advance(delta: float) -> void:
	left = maxf(left - delta, 0.0)


func is_active() -> bool:
	return left > 0.0


## The tint now: the flash colour while it lasts, white otherwise.
func current_color() -> Color:
	return color if is_active() else Color.WHITE


## Sets the item's modulate to the tint now.
func apply_to(item: CanvasItem) -> void:
	item.modulate = current_color()


## Ends the flash at once (a new run).
func reset() -> void:
	left = 0.0
