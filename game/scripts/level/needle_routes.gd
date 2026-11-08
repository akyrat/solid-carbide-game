class_name NeedleRoutes
extends RefCounted
## Needle routes (task T-592; Level design, Decisions, "Needle routes"): thread-the-needle pairs
## grouped into a route in the level creator. A level file's "routes" list holds
## [{id: "route-N", order: "in_order" | "random", pairs: ["pair-3", "pair-1", ...]}], the pair ids
## in the order the board clicked them (a pair is in one route at most). The creator writes it
## (level_document.gd), game/tools/check_level.py checks it by the same rules, and a run reads it
## here through ThreadTheNeedle:
## - only each route's active pair pays thread the needle (is_paying); its other pairs wait;
## - threading the active pair makes the next one active (threaded): in order, the next in the list,
##   back to the first after the last; random, a random other pair (never the same one twice in a
##   row when the route has more than one);
## - a pair in no route pays as before (T-272), and so does a route of one pair (it stays active);
## - what threading a waiting pair does, how bright and how faint the pairs show, and where a random
##   route starts are proposals in data/level/needle_routes.json (with their reasons).

const DATA_PATH := "res://data/level/needle_routes.json"
const ORDER_IN_ORDER := "in_order"
const ORDER_RANDOM := "random"
const ORDERS := [ORDER_IN_ORDER, ORDER_RANDOM]

## A pair's state in a run: in no route, its route's active pair, or waiting in its route.
const FREE := "free"
const ACTIVE := "active"
const WAITING := "waiting"

## Emitted when a route's active pair changes (after a thread), with the route's id and the new pair.
signal active_changed(route_id: String, pair_id: String)

## The routes with at least one pair that exists in the run: {id, order, pairs: [pair ids], active: index}.
var routes: Array = []
## Per pair id: the index into `routes` of the route holding it.
var _route_of: Dictionary = {}
var rng := RandomNumberGenerator.new()
var settings: Dictionary = {}


## `layout` a level's data; `pair_ids` the pairs that exist in the run (the gates; [] means every
## pair the routes name); `seed_value` seeds the random order (-1: a random seed).
func _init(layout: Dictionary = {}, pair_ids: Array = [], seed_value: int = -1) -> void:
	settings = load_settings()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	setup(layout, pair_ids)


func setup(layout: Dictionary, pair_ids: Array = []) -> void:
	routes = []
	_route_of = {}
	for r in routes_of(layout):
		var ids: Array = []
		for pid in r.get("pairs", []):
			var s := str(pid)
			if s in ids or _route_of.has(s):
				continue  # check_level refuses it; the run keeps the first
			if not pair_ids.is_empty() and not s in pair_ids:
				continue  # its obstacles are gone: the rest of the route plays on
			ids.append(s)
		if ids.is_empty():
			continue
		var order := order_of(r)
		var start := 0
		if order == ORDER_RANDOM and str(settings.get("random_start", "random")) == "random":
			start = rng.randi_range(0, ids.size() - 1)
		for s in ids:
			_route_of[s] = routes.size()
		routes.append({"id": str(r.get("id", "")), "order": order, "pairs": ids, "active": start})


## The settings (data/level/needle_routes.json) with defaults.
static func load_settings() -> Dictionary:
	var out := {
		"active": {"alpha": 0.9, "width": 1.6},
		"waiting": {"alpha": 0.12, "width": 1.0},
		"free": {"alpha": 0.35, "width": 1.0},
		"waiting_threaded": "nothing",
		"random_start": "random",
	}
	var d = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
	if d is Dictionary:
		for k in out.keys():
			if d.has(k):
				out[k] = d[k]
	return out


## A level's routes ([] for none).
static func routes_of(layout: Dictionary) -> Array:
	var l = layout.get("routes", [])
	return l if l is Array else []


## A route's order, ORDER_IN_ORDER for anything that is not ORDER_RANDOM.
static func order_of(route) -> String:
	if route is Dictionary and str(route.get("order", "")) == ORDER_RANDOM:
		return ORDER_RANDOM
	return ORDER_IN_ORDER


## FREE, ACTIVE or WAITING for pair `pair_id`.
func state_of(pair_id: String) -> String:
	if not _route_of.has(pair_id):
		return FREE
	var r: Dictionary = routes[_route_of[pair_id]]
	return ACTIVE if str(r.pairs[int(r.active)]) == pair_id else WAITING


## Whether threading pair `pair_id` pays now: a free or active pair; a waiting one only when
## waiting_threaded says so (the proposal: "nothing").
func is_paying(pair_id: String) -> bool:
	return state_of(pair_id) != WAITING or str(settings.get("waiting_threaded", "nothing")) == "pays"


## The active pair of route `route_id`, "" for none.
func active_of(route_id: String) -> String:
	for r in routes:
		if str(r.id) == route_id:
			return str(r.pairs[int(r.active)])
	return ""


## Pair `pair_id` was threaded (and paid): when it is its route's active pair, the next one becomes
## active. Returns the new active pair's id, "" when nothing changed.
func threaded(pair_id: String) -> String:
	if state_of(pair_id) != ACTIVE:
		return ""
	var r: Dictionary = routes[_route_of[pair_id]]
	var n: int = r.pairs.size()
	if n < 2:
		return ""
	var at := int(r.active)
	if str(r.order) == ORDER_RANDOM:
		var pick := rng.randi_range(0, n - 2)  # one of the n - 1 others
		at = pick if pick < at else pick + 1
	else:
		at = (at + 1) % n
	r.active = at
	var now := str(r.pairs[at])
	active_changed.emit(str(r.id), now)
	return now


## The look of a pair's line for its state: {alpha, width (a factor of the marker's width)}.
func look_of(pair_id: String) -> Dictionary:
	var l = settings.get(state_of(pair_id), {})
	return {"alpha": float(l.get("alpha", 0.35)), "width": float(l.get("width", 1.0))} if l is Dictionary \
		else {"alpha": 0.35, "width": 1.0}
