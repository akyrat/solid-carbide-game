extends RefCounted
## Task T-405's level (tests and screenshot fixtures): short buildings joined into platforms, built
## through the creator's own LevelDocument.place (no snapping), so every number is exact.
##
## Units (x east, y south):
## - a low-rise "short-0" at (-12, -12) and "short-1" at (0, -12), 12 x 12 each: joined east-west;
## - two small buildings at (-12, 0) and (-6, 0), 6 x 6: joined to each other and under the low-rise;
## - a long building (ew) at (0, 0), 12 x 6: under "short-1", east of the small ones;
## - a rooftop at height 3 at (12, -12), 12 x 18: beside "short-1" and the long building;
## - a 0-to-3 ramp up the low-rise's west side at (-24, -10), 12 x 8;
## - an AC unit on "short-1" at (4, -12); a barrier on the street just east of the rooftop at (26, -8)
##   (1 x 4, turned east);
## - a skyscraper at (38, -12);
## - the spawn at (-35, -5) facing east: the drive line y = -5 runs up the ramp, across the low-rises
##   and the rooftop, off its east edge over the barrier, and into the skyscraper.

const SPAWN := Vector2(-35, -5)


static func build() -> LevelDocument:
	var doc := LevelDocument.new(LevelDocument.new_level_data("T-405 platforms"))
	doc.place("short-0", Vector2(-12, -12))
	doc.place("short-1", Vector2(0, -12), "", true)
	doc.place("building-small", Vector2(-12, 0))
	doc.place("building-small", Vector2(-6, 0), "", true)
	doc.place("building-long", Vector2(0, 0), "ew")
	doc.place("rooftop-3", Vector2(12, -12), "", false, Vector2(12, 18))
	doc.place("ramp-0-3", Vector2(-24, -10), "east", false, Vector2(12, 8))
	doc.place("prop-ac-unit", Vector2(4, -12), "north")
	doc.place("prop-barrier", Vector2(26, -8), "east")
	doc.place("skyscraper-1", Vector2(38, -12))
	doc.data["spawn"] = {"x": SPAWN.x, "y": SPAWN.y, "heading": 0}
	return doc


## The level as a file's data (what the editor saves).
static func file_data() -> Dictionary:
	return build().file_data("T-405 platforms")
