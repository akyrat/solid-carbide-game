class_name LevelGround
extends RefCounted
## The ground layout mvp_map.gd draws for a level made in the level creator (task T-391; Level
## design, Decisions, "Roads painted in the creator show in the run"). One place for both the
## creator's editor (LevelDocument.ground_layout) and the run (mvp_map.gd _ready), so a level plays
## with exactly the ground and road tiles it was painted with.
##
## A level file's "ground" (LevelDocument: cell_units, origin, cols, rows, tiles = the catalogue
## ids used, cells = an index into tiles per 2 x 2 unit cell) becomes a layout in the format of
## data/level/mvp_ground.json: the game's ground atlas, one atlas tile per cell (the catalogue
## entry's atlas_index), and tiles outside the atlas (road_tile.png) in "extra", a cell value
## EXTRA_BASE + k drawing extra k. A file without "ground" (the game's own map, a level saved before
## the creator painted ground) gives {}: the run then draws the game's own ground as before.
##
## Before T-391 the run always drew data/level/mvp_ground.json, whatever the level's ground was.

const CATALOGUE_PATH := "res://data/level/creator_assets.json"
## The game's own ground tiles (T-103): the atlas, its tile size and columns.
const GAME_GROUND_PATH := "res://data/level/mvp_ground.json"
const CELL := 2
## The tile a cell gets when its index is out of the file's tile list.
const BASE_GROUND := "ground-gravel0"
## mvp_map.gd's ground tiles: cell values from here on draw the layout's "extra" textures.
const EXTRA_BASE := 1000

static var _values: Dictionary = {}
static var _extra: Array = []
static var _game_ground: Dictionary = {}


static func _load_json(path: String) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}


static func game_ground() -> Dictionary:
	if _game_ground.is_empty():
		_game_ground = _load_json(GAME_GROUND_PATH)
	return _game_ground


## Catalogue id -> the cell value it draws with (its atlas_index, or EXTRA_BASE + k for extra k).
static func values() -> Dictionary:
	if _values.is_empty():
		_extra = []
		for e in _load_json(CATALOGUE_PATH).get("entries", []):
			if not (str(e.kind) in ["ground", "road"]) or e.has("parts"):
				continue
			if e.has("atlas_index"):
				_values[str(e.id)] = int(e.atlas_index)
			else:
				_values[str(e.id)] = EXTRA_BASE + _extra.size()
				_extra.append(str(e.textures[0].texture))
	return _values


## The textures of the tiles outside the atlas, in the order their cell values count them.
static func extra() -> Array:
	values()
	return _extra.duplicate()


## The ground layout for rows of catalogue ids (one per 2 x 2 unit cell), the first cell's corner
## at `origin` (units). An id the catalogue doesn't know draws nothing (-1).
static func layout_from_ids(id_rows: Array, origin: Vector2) -> Dictionary:
	var value := values()
	var gg := game_ground()
	var out_rows: Array = []
	for row in id_rows:
		var out: Array = []
		for id in row:
			out.append(int(value.get(str(id), -1)))
		out_rows.append(out)
	var n_cols: int = id_rows[0].size() if not id_rows.is_empty() else 0
	return {"atlas": gg.get("atlas", "res://art/ground/ground_atlas.png"), "tile_px": gg.get("tile_px", [128, 64]),
		"atlas_columns": gg.get("atlas_columns", 8), "cell_units": CELL, "origin": [origin.x, origin.y],
		"cols": n_cols, "rows": id_rows.size(), "extra": extra(), "cells": out_rows}


## The rows of catalogue ids a level file's "ground" holds ([] when it has none).
static func id_rows_of(level: Dictionary) -> Array:
	var g = level.get("ground", {})
	if not (g is Dictionary and g.get("cells") is Array and g.get("tiles") is Array):
		return []
	var tiles: Array = g.tiles
	var rows: Array = []
	for row in g.cells:
		var out: Array = []
		for k in row:
			var i := int(k)
			out.append(str(tiles[i]) if i >= 0 and i < tiles.size() else BASE_GROUND)
		rows.append(out)
	return rows


## The ground layout of a level file (its "ground", drawn where its own origin says, else at the
## map's corner); {} when the file has no creator ground, so the caller draws the game's own.
static func layout_of(level: Dictionary) -> Dictionary:
	var rows := id_rows_of(level)
	if rows.is_empty():
		return {}
	var g: Dictionary = level.ground
	var origin := Vector2.ZERO
	if g.get("origin") is Array and g.origin.size() >= 2:
		origin = Vector2(float(g.origin[0]), float(g.origin[1]))
	else:
		var m = level.get("map", {})
		if m is Dictionary and m.get("rect") is Dictionary:
			origin = Vector2(float(m.rect.x), float(m.rect.y))
	return layout_from_ids(rows, origin)
