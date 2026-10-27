class_name CreatorFamilies
extends RefCounted
## The level creator's families (task T-262): one per kind of piece, the side panel's buttons. The
## data is written by game/tools/build_creator_assets.py into data/level/creator_assets.json
## ("groups", "families"; the one place that says which catalogue entry belongs where). Each family
## lists its members: one pose of a catalogue entry each ({asset, view, mirror, variant}: what is
## placed, exactly what the old panel placed) and where it sits in the family ({look, turn, flip,
## height}). This script is the one place that steps them; the editor's keys (editor.gd
## KEY_ACTIONS: V look, R turn, M flip, H height) call step().

## The family axes the keys step, in the order they are kept when another one changes.
const AXES := ["height", "look", "turn", "flip"]


static func groups() -> Array:
	return LevelDocument.catalogue().get("groups", [])


static func families() -> Array:
	return LevelDocument.catalogue().get("families", [])


static func family(fid: String) -> Dictionary:
	for f in families():
		if str(f.id) == fid:
			return f
	return {}


## The families of a group, in the panel's order.
static func in_group(group: String) -> Array:
	return families().filter(func(f): return str(f.group) == group)


## The family holding a pose of `asset_id` ("" for none).
static func family_of_asset(asset_id: String) -> String:
	for f in families():
		for m in f.members:
			if str(m.asset) == asset_id:
				return str(f.id)
	return ""


## A family's first member (its first look, turn, flip and height).
static func first_member(fid: String) -> Dictionary:
	var f := family(fid)
	return f.members[0] if not f.is_empty() and not f.members.is_empty() else {}


## The member placing `asset_id` in `view` and `mirror` (else its first pose of that asset), {} for none.
static func member_for(asset_id: String, view: String = "", mirror: bool = false, variant: String = "") -> Dictionary:
	var f := family(family_of_asset(asset_id))
	if f.is_empty():
		return {}
	var best: Dictionary = {}
	var best_score := -1
	for m in f.members:
		if str(m.asset) != asset_id:
			continue
		var score := (4 if str(m.view) == view else 0) + (2 if bool(m.mirror) == mirror else 0) \
			+ (1 if str(m.variant) == variant else 0)
		if score > best_score:
			best = m
			best_score = score
	return best


## The values `axis` takes among the family's members that share `m`'s values on `keep`, in the
## members' order (the builder writes them in order: heights low to high, looks and turns from 0).
static func values_of(fid: String, m: Dictionary, axis: String, keep: Array) -> Array:
	var out: Array = []
	for x in family(fid).get("members", []):
		if _same(x, m, keep) and not (x[axis] in out):
			out.append(x[axis])
	return out


## The member after `m` along `axis` (look, turn, flip, height), back to the first after the last,
## keeping the other axes as far as the family has them. `m` itself when there is nothing to step to.
static func step(fid: String, m: Dictionary, axis: String) -> Dictionary:
	if m.is_empty():
		return first_member(fid)
	var vs := values_of(fid, m, axis, _keep_for(axis))
	if vs.size() < 2:
		return m
	var i := vs.find(m[axis])
	return with_value(fid, m, axis, vs[(i + 1) % vs.size()])


## True when `axis` has more than one value for `m` (the key does something).
static func can_step(fid: String, m: Dictionary, axis: String) -> bool:
	return not m.is_empty() and values_of(fid, m, axis, _keep_for(axis)).size() > 1


## The member with `axis` = `value`, the closest to `m` on the other axes (AXES order first).
static func with_value(fid: String, m: Dictionary, axis: String, value) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1
	for x in family(fid).get("members", []):
		if x[axis] != value:
			continue
		var score := 0
		var weight := 8
		for a in AXES:
			if a == axis:
				continue
			if x[a] == m.get(a):
				score += weight
			weight /= 2
		if score > best_score:
			best = x
			best_score = score
	return best if not best.is_empty() else m


## The looks strip (T-262): one member per look at `m`'s height, each the closest to `m`'s turn and flip.
static func looks(fid: String, m: Dictionary) -> Array:
	var out: Array = []
	for v in values_of(fid, m, "look", ["height"]):
		out.append(with_value(fid, m, "look", v))
	return out


## `m`'s place among its looks (0-based), -1 when it has none.
static func look_index(fid: String, m: Dictionary) -> int:
	return values_of(fid, m, "look", ["height"]).find(m.get("look"))


## The axes kept fixed while `axis` steps: R turns and M flips the same look at the same height;
## V and H change look or height, keeping the rest where the family has it (with_value).
static func _keep_for(axis: String) -> Array:
	match axis:
		"turn":
			return ["height", "look", "flip"]
		"flip":
			return ["height", "look", "turn"]
		"look":
			return ["height"]
	return []


static func _same(a: Dictionary, b: Dictionary, keys: Array) -> bool:
	for k in keys:
		if a.get(k) != b.get(k):
			return false
	return true
