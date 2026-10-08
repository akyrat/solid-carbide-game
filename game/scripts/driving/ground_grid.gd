extends Node2D
## A flat, empty ground with a grid, so movement and speed are visible. Drawn in
## flat world pixels; the drift prototype gives this node the isometric
## transform in the isometric view. Only the area around the car is drawn.

## Pixels per unit (Car.PX_PER_UNIT).
var px_per_unit := 16.0
## Units drawn on each side of the car.
var half_extent_units := 80
## A thin line every unit, a stronger one every major_every units.
var major_every := 5

var ground_color := Color(0.07, 0.07, 0.14)
var minor_color := Color(0.17, 0.17, 0.30)
var major_color := Color(0.33, 0.30, 0.52)
var origin_color := Color(0.85, 0.35, 0.65)

## The unit cell the grid is centred on.
var _centre_cell := Vector2i(1 << 30, 0)


## Recentres the grid on a flat world position (pixels). Redraws only when the
## car enters another cell.
func follow(world_px: Vector2) -> void:
	var cell := Vector2i(floori(world_px.x / px_per_unit), floori(world_px.y / px_per_unit))
	if cell != _centre_cell:
		_centre_cell = cell
		queue_redraw()


func _draw() -> void:
	var u := px_per_unit
	var n := half_extent_units
	var x0 := (_centre_cell.x - n) * u
	var x1 := (_centre_cell.x + n) * u
	var y0 := (_centre_cell.y - n) * u
	var y1 := (_centre_cell.y + n) * u
	draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), ground_color)
	var minor := PackedVector2Array()
	var major := PackedVector2Array()
	for i in range(-n, n + 1):
		var gx := _centre_cell.x + i
		var gy := _centre_cell.y + i
		var vline := PackedVector2Array([Vector2(gx * u, y0), Vector2(gx * u, y1)])
		var hline := PackedVector2Array([Vector2(x0, gy * u), Vector2(x1, gy * u)])
		if posmod(gx, major_every) == 0:
			major.append_array(vline)
		else:
			minor.append_array(vline)
		if posmod(gy, major_every) == 0:
			major.append_array(hline)
		else:
			minor.append_array(hline)
	draw_multiline(minor, minor_color, 1.0)
	draw_multiline(major, major_color, 2.0)
	# A marker at the start point.
	draw_circle(Vector2.ZERO, u * 0.5, origin_color)
