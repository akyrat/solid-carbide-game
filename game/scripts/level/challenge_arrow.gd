extends Node2D
## Placeholder for a challenge's painted arrow (task T-019): a flat band as wide
## as the corridor along the arrow's centre line, a thin centre line, a white dot
## at the start and an arrowhead at the end. The painted, animated arrow comes
## later (Visual style, Decisions); it replaces this node's drawing only.
##
## Drawn in flat world pixels; the parent may give it the isometric transform.

## Centre line in units (the layout data's centre_line).
var centre_line := PackedVector2Array()
var corridor_width := 3.0
var px_per_unit := 16.0

## Visual style, Decisions: the arrows of the challenges on the map are blue.
var band_color := Color(0.25, 0.55, 1.0, 0.45)
var line_color := Color(0.45, 0.75, 1.0, 1.0)
var start_color := Color(1.0, 1.0, 1.0, 1.0)


func _draw() -> void:
	if centre_line.size() < 2:
		return
	var u := px_per_unit
	var pts := PackedVector2Array()
	for p in centre_line:
		pts.append(p * u)
	var r := corridor_width / 2.0 * u
	# The band: a round-capped polyline. Overlapping parts of a self-crossing
	# arrow draw on top of each other, which only darkens the crossing.
	draw_polyline(pts, band_color, corridor_width * u)
	draw_circle(pts[0], r, band_color)
	draw_circle(pts[pts.size() - 1], r, band_color)
	draw_polyline(pts, line_color, 0.35 * u)
	# Arrowhead at the end, pointing along the last stretch of the centre line.
	var tip := pts[pts.size() - 1]
	var back := pts[maxi(0, pts.size() - 6)]
	var dir := (tip - back).normalized()
	var hl := 1.6 * u
	var left := tip - dir.rotated(-0.45) * hl
	var right := tip - dir.rotated(0.45) * hl
	draw_colored_polygon(PackedVector2Array([tip, left, right]), line_color)
	draw_circle(pts[0], 0.4 * u, start_color)
