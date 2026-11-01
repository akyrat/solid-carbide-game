class_name Perf
extends RefCounted
## Timed zones for the performance recorder (task T-468; game/docs/game-loop/perf-recorder.md).
##
## The game's systems wrap their work in begin/end calls with a zone name:
##
##     Perf.begin(&"minions.step")
##     ...
##     Perf.end(&"minions.step")
##
## Zones nest. While the recorder is off (`Perf.on` false, the default) every call returns at
## once, so the game behaves as before. While it is on, each zone's time is added to the
## frame's totals (inclusive and self time, and the number of calls), and each occurrence is
## kept as an event for the trace (a flame graph in Perfetto or chrome://tracing).
##
## Work done once per item, many times a frame (each minion's path, each minion sprite's
## drawing), uses the "each" form, guarded so it costs almost nothing while off:
##
##     if Perf.on: Perf.each_begin(&"minions.path")
##     ...
##     if Perf.on: Perf.each_end(&"minions.path")
##
## Each-zones are summed, not kept one by one: the trace shows one block per each-zone under
## the zone that holds them, as wide as their self time together (the block's `calls` and
## `us` arguments hold the true numbers; blocks are laid side by side after the zone's last
## real child, squeezed to fit). Any zone begun inside an each-zone counts as an each-zone
## too, so the trace always nests.
##
## An end() closes the innermost open zone of that name and any zone left open inside it
## (counted in `unbalanced`), so a missed end never breaks the nesting. Nothing here is
## thread-safe: call it from the main thread only.

## True while a recording is on. Set by PerfRecorder; read by the guarded each-zone calls.
static var on := false

## Zone names by id, and ids by name.
static var names := PackedStringArray()
static var _ids := {}

## The open real zones, innermost last, STRIDE ints each: id, start (usec), time of its
## finished children (usec), end of its last finished real child (usec).
const STRIDE := 4
static var _s := PackedInt64Array()
## The open each-zones, innermost last (ids), with their start and children's time by id.
static var _e := PackedInt32Array()
static var _e_t0 := PackedInt64Array()
static var _e_child := PackedInt64Array()
## Each-zone sums waiting for their real zone to end: by id, the self usec, the calls and the
## real zone that holds them (its index in the stack); `_blk_ids` lists the ids waiting.
static var _blk_us := PackedInt64Array()
static var _blk_calls := PackedInt32Array()
static var _blk_owner := PackedInt32Array()
static var _blk_ids := PackedInt32Array()

## This frame's totals by id: inclusive usec, self usec, calls. `touched` lists the ids used.
static var tot_us := PackedInt64Array()
static var self_us := PackedInt64Array()
static var calls := PackedInt32Array()
static var touched := PackedInt32Array()
## This frame's events for the trace, 5 ints each: id, start, end, depth, calls (0 for a
## real zone, the number of calls for an each-zone block).
static var events := PackedInt64Array()
## Zone calls this frame (begin and each_begin), for the overhead estimate.
static var zone_calls := 0
## Ends that closed zones left open inside them, since the recording began.
static var unbalanced := 0
## Called with (id, name) when a zone name is seen for the first time.
static var on_new_zone: Callable = Callable()


## Starts a fresh recording state (no open zones, empty frame). Keeps the names.
static func reset() -> void:
	_s.clear()
	_e.clear()
	unbalanced = 0
	clear_frame()


## Empties this frame's totals and events (the recorder calls it after reading them).
static func clear_frame() -> void:
	for id in touched:
		tot_us[id] = 0
		self_us[id] = 0
		calls[id] = 0
	touched.clear()
	for id in _blk_ids:
		_blk_us[id] = 0
		_blk_calls[id] = 0
	_blk_ids.clear()
	events.clear()
	zone_calls = 0


## The id of a zone name, registering it on first use.
static func id_of(zone: StringName) -> int:
	var id: int = _ids.get(zone, -1)
	if id < 0:
		id = names.size()
		names.append(String(zone))
		_ids[zone] = id
		var n := id + 1
		tot_us.resize(n)
		self_us.resize(n)
		calls.resize(n)
		_e_t0.resize(n)
		_e_child.resize(n)
		_blk_us.resize(n)
		_blk_calls.resize(n)
		_blk_owner.resize(n)
		if on_new_zone.is_valid():
			on_new_zone.call(id, String(zone))
	return id


## Opens a zone. Inside an each-zone it is an each-zone too.
static func begin(zone: StringName) -> void:
	if not on:
		return
	if not _e.is_empty():
		each_begin(zone)
		return
	var id: int = _ids.get(zone, -1)
	if id < 0:
		id = id_of(zone)
	zone_calls += 1
	var n := _s.size()
	_s.resize(n + STRIDE)
	_s[n] = id
	var t := Time.get_ticks_usec()
	_s[n + 1] = t
	_s[n + 2] = 0
	_s[n + 3] = t


## Closes the innermost open zone named `zone`.
static func end(zone: StringName) -> void:
	if not on:
		return
	if not _e.is_empty():
		each_end(zone)
		return
	var t := Time.get_ticks_usec()
	var n := _s.size() - STRIDE
	if n < 0:
		return
	if _s[n] != _ids.get(zone, -1):
		_pop_to(zone, t)
		return
	_pop_real(t)


## Opens a zone that is summed rather than kept one by one (see the top).
static func each_begin(zone: StringName) -> void:
	if not on:
		return
	var id: int = _ids.get(zone, -1)
	if id < 0:
		id = id_of(zone)
	zone_calls += 1
	_e.append(id)
	_e_child[id] = 0
	_e_t0[id] = Time.get_ticks_usec()


static func each_end(zone: StringName) -> void:
	if not on:
		return
	var t := Time.get_ticks_usec()
	var k := _e.size() - 1
	if k < 0:
		end(zone)  # not an each-zone after all (begun as a real zone)
		return
	var want: int = _ids.get(zone, -1)
	if _e[k] != want:
		var j := k
		while j >= 0 and _e[j] != want:
			j -= 1
		if j < 0:
			return  # not open: ignored
		while _e.size() - 1 > j:
			unbalanced += 1
			_pop_each(t)
	_pop_each(t)


## Number of zones open now.
static func depth() -> int:
	return _s.size() / STRIDE + _e.size()


## Closes every open zone at `t` (usec), as at the end of a frame or a recording.
static func close_all(t: int) -> void:
	while not _e.is_empty():
		_pop_each(t)
	while not _s.is_empty():
		_pop_real(t)


static func _pop_to(zone: StringName, t: int) -> void:
	var id: int = _ids.get(zone, -1)
	if id < 0:
		return
	var i := _s.size() - STRIDE
	while i >= 0 and _s[i] != id:
		i -= STRIDE
	if i < 0:
		return  # not open (begun before the recording started): ignored
	while _s.size() - STRIDE > i:
		unbalanced += 1
		_pop_real(t)
	_pop_real(t)


static func _pop_real(t: int) -> void:
	var n := _s.size() - STRIDE
	var id := _s[n]
	var t0 := _s[n + 1]
	var dur := t - t0
	var last_child_end := _s[n + 3]
	self_us[id] += maxi(dur - _s[n + 2], 0)
	_s.resize(n)
	tot_us[id] += dur
	if calls[id] == 0:
		touched.append(id)
	calls[id] += 1
	if n > 0:
		_s[n - STRIDE + 2] += dur
		_s[n - STRIDE + 3] = t
	var d := n / STRIDE
	if not _blk_ids.is_empty():
		_emit_blocks(d, last_child_end, t)
	var m := events.size()
	events.resize(m + 5)
	events[m] = id
	events[m + 1] = t0
	events[m + 2] = t
	events[m + 3] = d
	events[m + 4] = 0


static func _pop_each(t: int) -> void:
	var k := _e.size() - 1
	var id := _e[k]
	_e.resize(k)
	var dur := t - _e_t0[id]
	var own := maxi(dur - _e_child[id], 0)
	tot_us[id] += dur
	self_us[id] += own
	if calls[id] == 0:
		touched.append(id)
	calls[id] += 1
	if k > 0:
		_e_child[_e[k - 1]] += dur
	elif not _s.is_empty():
		_s[_s.size() - STRIDE + 2] += dur
	# Its block, under the innermost real zone (the first one it was summed under, if that
	# one is still open).
	if _s.is_empty():
		return
	if _blk_calls[id] == 0:
		_blk_owner[id] = _s.size() / STRIDE - 1
		_blk_ids.append(id)
	_blk_us[id] += own
	_blk_calls[id] += 1


## The each-zone blocks of the real zone at stack index `d` that just ended, laid side by
## side from the end of its last real child, squeezed to fit before its end `t1`.
static func _emit_blocks(d: int, start: int, t1: int) -> void:
	var mine := PackedInt32Array()
	var total := 0
	for id in _blk_ids:
		if _blk_owner[id] == d:
			mine.append(id)
			total += _blk_us[id]
	if mine.is_empty():
		return
	var room := maxi(t1 - start, 0)
	var scale := 1.0 if total <= room or total == 0 else float(room) / float(total)
	var at := start
	for id in mine:
		var w := int(floor(_blk_us[id] * scale))
		var m := events.size()
		events.resize(m + 5)
		events[m] = id
		events[m + 1] = at
		events[m + 2] = at + w
		events[m + 3] = d + 1
		events[m + 4] = _blk_calls[id]
		at += w
		_blk_us[id] = 0
		_blk_calls[id] = 0
		_blk_ids.remove_at(_blk_ids.find(id))
