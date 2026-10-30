extends GutTest
## Task T-232: the level creator's catalogue (data/level/creator_assets.json, made by
## game/tools/build_creator_assets.py) names only textures that exist, and names every
## building, boulder, ground and elevation texture the map and the elevation layer draw.

const CATALOGUE := "res://data/level/creator_assets.json"
const GROUND_LAYOUT := "res://data/level/mvp_ground.json"
const SAMPLE_MAP := "res://data/level/elevation_sample_map.json"
const BUILDING_ART := "res://art/buildings/skyscrapers.json"
const BOULDER_ART := "res://art/boulders/boulders.json"
const SAMPLE_ART_DIR := "res://art/elevation_sample/"


func _json(path: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func _named() -> Dictionary:
	var out := {}
	var cat := _json(CATALOGUE)
	for p in cat.get("building_pavements", []):
		out[str(p)] = true
	for e in cat.get("entries", []):
		for t in e.textures:
			out[str(t.texture)] = true
	return out


func test_catalogue_loads() -> void:
	var cat := _json(CATALOGUE)
	assert_gt(cat.get("entries", []).size(), 0, "the catalogue has entries")


func test_every_named_texture_exists() -> void:
	var named := _named()
	assert_gt(named.size(), 0)
	for path in named:
		assert_true(path.begins_with("res://art/"), "%s is under art/" % path)
		assert_true(ResourceLoader.exists(path), "%s exists" % path)


func test_entries_have_the_fields() -> void:
	var kinds := ["ground", "road", "building", "boulder", "rooftop", "ramp", "prop"]
	for e in _json(CATALOGUE).entries:
		assert_true(str(e.id) != "")
		assert_true(kinds.has(str(e.kind)), "%s kind" % e.id)
		assert_eq(e.footprint_units.size(), 2, "%s footprint" % e.id)
		assert_gt(e.views.size(), 0)
		assert_gt(e.mirrors.size(), 0)
		assert_gt(e.textures.size(), 0)


func test_rooftop_and_ramp_heights() -> void:
	var roofs := []
	var ramps := []
	for e in _json(CATALOGUE).entries:
		if e.kind == "rooftop":
			roofs.append(int(e.height))
		elif e.kind == "ramp":
			ramps.append("%d-%d" % [int(e.heights[0]), int(e.heights[1])])
	roofs.sort()
	ramps.sort()
	assert_eq(roofs, [3, 6])
	assert_eq(ramps, ["0-3", "0-6", "3-6"])


func test_buildings_the_map_draws_are_listed() -> void:
	var named := _named()
	var art := _json(BUILDING_ART)
	for p in art.bodies + art.pavements:
		assert_true(named.has(str(p)), "%s in the catalogue" % p)
	# T-405: the low-rise is listed with its platform art.
	var rec := _json("res://art/buildings/platforms/platforms.json")
	for p in art.short.bodies:
		assert_true(named.has(str(rec.textures[p].full)), "%s's platform art in the catalogue" % p)


func test_boulders_the_map_draws_are_listed() -> void:
	var named := _named()
	for v in _json(BOULDER_ART).variants:
		assert_true(named.has(str(v.texture)), "%s in the catalogue" % v.texture)


func test_ground_the_map_draws_is_listed() -> void:
	var layout := _json(GROUND_LAYOUT)
	var atlas_indices := {}
	var atlas_path := ""
	for e in _json(CATALOGUE).entries:
		if e.has("atlas_index"):
			atlas_indices[int(e.atlas_index)] = true
			atlas_path = str(e.textures[0].texture)
	assert_eq(atlas_path, str(layout.atlas), "the catalogue names the map's ground atlas")
	for row in layout.cells:
		for k in row:
			if int(k) >= 0:
				assert_true(atlas_indices.has(int(k)), "ground tile %d in the catalogue" % int(k))


## T-251: the catalogue's rooftops and ramps are of any size, drawn in the engine from the piece
## style (art/creator_pieces/piece_style.tres) rather than from the sample map's art pieces; each
## names that style, which exists and holds every face's texture.
func test_rooftops_and_ramps_name_the_piece_style_they_are_drawn_with() -> void:
	var n := 0
	for e in _json(CATALOGUE).entries:
		if not (str(e.kind) in ["rooftop", "ramp"]):
			continue
		n += 1
		assert_true(bool(e.get("resizable", false)), "%s is resizable" % e.id)
		assert_eq(str(e.style), "res://art/creator_pieces/piece_style.tres", str(e.id))
	assert_eq(n, 5, "two rooftops and three ramps")
	var style = load("res://art/creator_pieces/piece_style.tres")
	for key in ["roof_top", "wall", "ramp_top", "ramp_side", "parapet"]:
		assert_not_null(style.get(key), "the style has its %s texture" % key)
