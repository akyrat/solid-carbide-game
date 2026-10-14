extends Node2D
## One building of the MVP map (task T-034): a flat-coloured placeholder box
## that turns see-through while it covers the car on screen (Visual style,
## Decisions: the whole building fades to 15% visible over 0.15 seconds, and
## fades back when the car comes out; only buildings actually covering the car
## fade).
##
## The node lives in the map's drawing (map.view_root), so it draws in flat
## world pixels under the view's projection. In the isometric view the box
## rises `height_units` from its footprint: one unit up on screen is the world
## offset (-1, -1) unit, which the 2:1 projection turns into straight up. In
## the flat view it is drawn flat, has no height and never covers the car.
##
## The fade only ever changes this node's `modulate.a`, so the whole object
## fades as one, and any art added under this node (a child Sprite2D, task
## T-064) fades with it. No pixel of a sprite is made semi-transparent.

## Pixels per unit, the same as the map and the car.
const PX_PER_UNIT := 16.0
## The same 2:1 isometric projection as the map and the run.
const ISO_TRANSFORM := Transform2D(Vector2(1.0, 0.5), Vector2(-1.0, 0.5), Vector2.ZERO)

## The footprint on the ground, in units from the map's centre (x right, y down).
var footprint := Rect2()
## How tall the placeholder box is drawn in the isometric view, in units.
var height_units := 0.0
## The on-screen outline used for the cover test, in the map's screen pixels
## (the map node's own coordinates in the isometric view). Empty: the box's
## outline from footprint and height_units. Final art whose outline is not the
## box can set its own here.
var custom_silhouette := PackedVector2Array()
## "flat" or "iso", as the map's view.
var view := "flat"
## Whether the node draws its placeholder box. The final art (a child Sprite2D,
## task T-064) sets it false; the cover test and the fade work the same.
var draw_placeholder := true
## The tower art of the block (building_towers.gd, task T-064), or null.
var towers: Node2D = null

var top_color := Color(0.22, 0.15, 0.38)
var left_color := Color(0.15, 0.10, 0.27)
var right_color := Color(0.18, 0.12, 0.32)
var edge_color := Color(0.45, 0.30, 0.70)

## How visible the building is while it covers the car (1 = solid).
var see_through_alpha := 0.15
## Seconds for the whole fade, from solid to see_through_alpha or back (0 = instant).
var fade_time := 0.15

## True while the building covers the car (set by update_fade).
var covering := false
## The alpha the building is fading towards.
var target_alpha := 1.0


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## The building's alpha now (1 = solid). The same as modulate.a.
func alpha() -> float:
	return modulate.a


## Depth key for the draw order: the footprint's front corner (x + y of its
## bottom-right corner). Bigger is nearer to the viewer.
func depth_key() -> float:
	return footprint.end.x + footprint.end.y


## True when a point on the ground (units) is behind the building, i.e. not in
## front of either of its two visible faces (+x and +y). A point beside the
## building's left or right corner counts as in front; there the two never
## overlap on screen.
func is_behind(p: Vector2) -> bool:
	return p.x < footprint.end.x and p.y < footprint.end.y


## The building's on-screen outline in the map's screen pixels (isometric
## view): the box's six outer corners, or custom_silhouette. Empty in the flat
## view (a flat building covers nothing).
func silhouette() -> PackedVector2Array:
	if view != "iso":
		return PackedVector2Array()
	return iso_silhouette()


## The building's outline in the isometric view whatever the current view
## (custom_silhouette, or the box's six outer corners). The map uses it to put
## the boulders in the depth order once, when they are placed (task T-065).
func iso_silhouette() -> PackedVector2Array:
	if not custom_silhouette.is_empty():
		return custom_silhouette
	var u := PX_PER_UNIT
	var up := Vector2(0.0, -height_units * u)
	var a := ISO_TRANSFORM * (footprint.position * u)
	var b := ISO_TRANSFORM * (Vector2(footprint.end.x, footprint.position.y) * u)
	var c := ISO_TRANSFORM * (footprint.end * u)
	var d := ISO_TRANSFORM * (Vector2(footprint.position.x, footprint.end.y) * u)
	return PackedVector2Array([a + up, b + up, b, c, d, d + up])


## True when the building overlaps the given screen shape (map screen pixels).
func overlaps_on_screen(shape: PackedVector2Array) -> bool:
	var s := silhouette()
	if s.is_empty() or shape.is_empty():
		return false
	return not Geometry2D.intersect_polygons(s, shape).is_empty()


## True when the building covers the car: the car (its centre on the ground,
## units) is behind it and the car's screen shape overlaps it.
func covers(car_centre_units: Vector2, car_shape: PackedVector2Array) -> bool:
	return is_behind(car_centre_units) and overlaps_on_screen(car_shape)


## Decides whether the building covers the car and moves the fade by `delta`
## seconds. Returns `covering`.
func update_fade(car_centre_units: Vector2, car_shape: PackedVector2Array, delta: float) -> bool:
	covering = covers(car_centre_units, car_shape)
	step_fade(covering, delta)
	return covering


## Moves the whole building's alpha towards see_through_alpha (covering) or 1,
## at a speed that takes fade_time for the whole way.
func step_fade(is_covering: bool, delta: float) -> void:
	target_alpha = see_through_alpha if is_covering else 1.0
	var a := modulate.a
	if fade_time <= 0.0:
		a = target_alpha
	else:
		a = move_toward(a, target_alpha, delta / fade_time * (1.0 - see_through_alpha))
	modulate.a = a


## Puts the building straight back to solid (a new map, or the flat view).
func reset_fade() -> void:
	covering = false
	target_alpha = 1.0
	modulate.a = 1.0


func set_view(v: String) -> void:
	view = v
	queue_redraw()


func _draw() -> void:
	if not draw_placeholder:
		return
	var u := PX_PER_UNIT
	var r := Rect2(footprint.position * u, footprint.size * u)
	if view != "iso" or height_units <= 0.0:
		draw_rect(r, top_color)
		draw_rect(r, edge_color, false, 2.0)
		return
	# Drawn in flat world pixels: the view's projection turns the world
	# offset (-h, -h) into straight up on screen.
	var h := height_units * u
	var up := Vector2(-h, -h)
	var a := r.position
	var b := Vector2(r.end.x, r.position.y)
	var c := r.end
	var d := Vector2(r.position.x, r.end.y)
	# The two visible walls (+y face on the left, +x face on the right), then the roof.
	draw_colored_polygon(PackedVector2Array([d, c, c + up, d + up]), left_color)
	draw_colored_polygon(PackedVector2Array([c, b, b + up, c + up]), right_color)
	draw_colored_polygon(PackedVector2Array([a + up, b + up, c + up, d + up]), top_color)
	for line in [[a + up, b + up, c + up, d + up, a + up], [d, c, b], [d, d + up], [c, c + up], [b, b + up]]:
		draw_polyline(PackedVector2Array(line), edge_color, 2.0)
