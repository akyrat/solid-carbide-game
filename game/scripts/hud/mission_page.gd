class_name MissionPage
extends Control
## The current mission as a notebook page on the left of the HUD (task T-458; Game loop
## architecture, Decisions, "Mission packs"). PLACEHOLDER art: a pale page with ruled lines
## and a red margin, drawn in code, until the art ticket replaces it. It only shows: the
## tracker (RunMissions, T-457) owns the goals and their progress.
##
## The header and every goal line are the texts of data/screen_texts.json (missions.header,
## missions.goals.<trick id>, T-456), word for word. A quantity goal's line holds
## "{done}/{total}" and follows goal_progress live; a duration goal has {seconds} (its amount)
## and no count, except a running total (T-565: time added up, like the airtime), whose line
## shows the seconds so far with one decimal against its goal and follows goal_progress too.
## Its name box falls only when a trick adds a lump of seconds (a landing's airtime), never for
## time added a little at a time (RunMissions.add_seconds, the tutorial's drift slide). Each goal has a checkbox; a done goal is ticked and its line crossed off.
## When a mission completes the next one replaces it (mission_started); after the last one
## the page hides (RunMissions.is_all_done).
##
## Place (layout page 1152 x 648, scaled by the HUD): the left edge between the weapon icons
## above (down to about y 300 with four weapons) and the coins at y 496 below.

const TEXTS_PATH := "res://data/screen_texts.json"
## A running total's goal line (T-565; T-564's texts): missions.<TOTAL_GOALS_KEY>, one template with
## {name}, {done} and {total} for every such goal, and its {name} per trick in
## missions.<TOTAL_NAMES_KEY>.<trick>. A trick without a name keeps its usual line (missions.goals).
const TOTAL_GOALS_KEY := "total_seconds"
const TOTAL_NAMES_KEY := "total_seconds_names"
const PAGE_POS := Vector2(12, 304)
const PAGE_SIZE := Vector2(176, 180)
const PAD := Vector2(10, 8)
const MARGIN_X := 20.0
const BOX_SIZE := 14.0
const TEXT_X := 40.0
const RULE_STEP := 20
const ROW_GAP := 6.0
const HEADER_H := 28.0

## The final art (T-464), drawn at 2x with nearest filtering; the code drawing is the
## fallback when a file is missing.
const PAGE_ART := "res://art/hud/mission_page.png"
const CHECKBOX_ART := "res://art/hud/mission_checkbox.png"
const TICK_ART := "res://art/hud/mission_tick.png"
const CROSS_ART := "res://art/hud/mission_cross.png"

## A trick falls into the page (T-563): a small box with the trick's name drops from above
## the page's top onto its goal line, splashes, and only then the count updates. All numbers
## are proposals for the playtest.
const FALL_TIME := 0.32  ## seconds from the top to the goal line
const FALL_GAP := 0.14  ## least seconds between two boxes starting, so quick tricks queue
const SPLASH_TIME := 0.28
const SQUASH_TIME := 0.07
const MAX_QUEUED := 4  ## more than this waiting: the trick counts at once, no box
const BOX_START_Y := -34.0
const BOX_H := 24.0
const BOX_FONT_SIZE := 16
const DROPLETS := 7

static var _texts: Dictionary = {}
static var _art_cache: Dictionary = {}


## A piece of the page's art, or null when its file is missing. Loaded once and kept: a
## texture loaded inside `_draw` was drawn as flat white in a real run (T-464).
static func art(path: String) -> Texture2D:
	if not _art_cache.has(path):
		_art_cache[path] = (load(path) as Texture2D) if ResourceLoader.exists(path) else null
	return _art_cache[path]

## The rows of the mission on show, top to bottom.
var rows: Array = []
## Goal lines this page shows instead of the missions' texts (task T-561: the tutorial's practice
## windows): goal trick id -> a template with {done} and {total} (or {seconds}). Empty in the run.
var goal_templates: Dictionary = {}
var header_label: Label
var _missions: RunMissions
## The boxes still falling, splashing or waiting to start (see _on_trick_counted).
var _falls: Array = []
## Page updates held back until the box before them has landed: {"after": fall id, "call"}.
var _deferred: Array = []
var _fall_seq := 0
var _clock := 0.0
var _last_start := -100.0
var _overlay: Control


## One goal's line: a checkbox, the text, and the stroke across it when done.
class Row extends Control:
	var goal_index := 0
	var trick := ""
	var kind := ""
	var amount := 0.0
	var label: Label
	var ticked := false
	var crossed := false

	func _draw() -> void:
		var box := Rect2(0, 3, MissionPage.BOX_SIZE, MissionPage.BOX_SIZE)
		var box_art := MissionPage.art(MissionPage.CHECKBOX_ART)
		var tick_art := MissionPage.art(MissionPage.TICK_ART)
		var cross_art := MissionPage.art(MissionPage.CROSS_ART)
		if box_art != null:
			draw_texture_rect(box_art, box, false)
		else:
			draw_rect(box, HudStyle.MISSION_PAPER)
			draw_rect(box, HudStyle.MISSION_INK, false, 2.0)
		if ticked and tick_art != null:
			draw_texture_rect(tick_art, Rect2(box.position,
				tick_art.get_size() * float(HudStyle.HUD_ART_SCALE)), false)
		elif ticked:
			var a := box.position + Vector2(3, 7)
			var b := box.position + Vector2(6, 10)
			var c := box.position + Vector2(12, 1)
			draw_polyline(PackedVector2Array([a, b, c]), HudStyle.MISSION_INK, 2.0)
		if crossed:
			var font := label.get_theme_font("font")
			var fs := label.get_theme_font_size("font_size")
			var lh := font.get_height(fs)
			var y := label.position.y + lh * 0.55
			for l in _wrapped_widths():
				if cross_art != null:
					_draw_strike(cross_art, label.position.x, y, l)
				else:
					draw_line(Vector2(label.position.x, y), Vector2(label.position.x + l, y),
						HudStyle.MISSION_INK, 2.0)
				y += lh

	## The pen stroke across a width: its two end caps, the plain middle repeated.
	func _draw_strike(tex: Texture2D, x: float, y: float, width: float) -> void:
		var s := float(HudStyle.HUD_ART_SCALE)
		var cap := 8.0 * s
		var h := tex.get_height() * s
		var top := y - h * 0.5
		var th := tex.get_height()
		if width <= 2.0 * cap:
			draw_texture_rect_region(tex, Rect2(x, top, width, h), Rect2(0, 0, width / s, th))
			return
		draw_texture_rect_region(tex, Rect2(x, top, cap, h), Rect2(0, 0, 8, th))
		var mid := x + cap
		var end := x + width - cap
		while mid < end:
			var w := minf(cap, end - mid)
			draw_texture_rect_region(tex, Rect2(mid, top, w, h), Rect2(8, 0, w / s, th))
			mid += cap
		draw_texture_rect_region(tex, Rect2(end, top, cap, h), Rect2(16, 0, 8, th))

	## The widths of the label's wrapped lines (the stroke runs along each).
	func _wrapped_widths() -> Array:
		var font := label.get_theme_font("font")
		var fs := label.get_theme_font_size("font_size")
		var out: Array = []
		var shaped := TextParagraph.new()
		shaped.add_string(label.text, font, fs)
		shaped.width = label.custom_minimum_size.x
		for i in shaped.get_line_count():
			out.append(shaped.get_line_size(i).x)
		return out


func _init() -> void:
	name = "MissionPage"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = PAGE_POS
	size = PAGE_SIZE
	custom_minimum_size = PAGE_SIZE
	header_label = Label.new()
	header_label.name = "Header"
	header_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.apply(header_label, "mission_header")
	header_label.position = Vector2(TEXT_X - 4.0, PAD.y)
	header_label.size = Vector2(PAGE_SIZE.x - TEXT_X - PAD.x, HEADER_H)
	header_label.text = String(texts().get("header", ""))
	add_child(header_label)
	_overlay = Control.new()
	_overlay.name = "Falls"
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.size = PAGE_SIZE
	_overlay.draw.connect(_draw_falls)
	add_child(_overlay)
	visible = false
	set_process(false)


## The notebook page's texts (screen_texts.json, missions), read once.
static func texts() -> Dictionary:
	if _texts.is_empty():
		var f := FileAccess.open(TEXTS_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary and (parsed as Dictionary).has("missions"):
				_texts = parsed["missions"]
	return _texts


## A number as the page shows it: whole numbers without decimals, others with one place.
static func format_number(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return "%.1f" % v


## A running total's seconds (T-565): always one decimal, cut down (not rounded) so the line
## never reads its goal before the goal is done.
static func format_seconds(v: float) -> String:
	return "%.1f" % (floorf(v * 10.0 + 0.0001) / 10.0)


## The template of a goal's line in screen_texts.json: a running total (RunMissions.is_running_total,
## T-565) uses missions.<TOTAL_GOALS_KEY> with its {name} (missions.<TOTAL_NAMES_KEY>.<trick>)
## filled in when the trick has a name, else missions.goals.<trick>.
static func goal_template(trick: String, kind: String) -> String:
	if RunMissions.is_running_total(trick, kind):
		var names: Variant = texts().get(TOTAL_NAMES_KEY, {})
		var line := String(texts().get(TOTAL_GOALS_KEY, ""))
		if names is Dictionary and String((names as Dictionary).get(trick, "")) != "" and line != "":
			return line.replace("{name}", String(names[trick]))
	return String(texts().get("goals", {}).get(trick, ""))


## Fills a goal line's template: {done} (a count as a whole number; a running total's seconds with
## one decimal), {total} and {goal} (the amount; a running total's with one decimal too, T-564's
## "1.4/3.0"), {seconds} (the amount of a duration goal).
static func fill(template: String, trick: String, kind: String, done: float, amount: float) -> String:
	var done_text := format_number(floorf(done))
	var total_text := format_number(amount)
	if RunMissions.is_running_total(trick, kind):
		done_text = format_seconds(done)
		total_text = format_seconds(amount)
	elif kind != "count":
		done_text = format_number(done)
	return template.replace("{done}", done_text) \
		.replace("{total}", total_text) \
		.replace("{goal}", total_text) \
		.replace("{seconds}", format_number(amount))


## A goal's line: its text with {done}/{total} or {seconds} filled in.
static func goal_text(trick: String, kind: String, done: float, amount: float) -> String:
	return fill(goal_template(trick, kind), trick, kind, done, amount)


## The line this page shows for a goal: its goal_templates entry when it has one (T-561), else
## goal_text().
func line_text(trick: String, kind: String, done: float, amount: float) -> String:
	if not goal_templates.has(trick):
		return goal_text(trick, kind, done, amount)
	return fill(String(goal_templates[trick]), trick, kind, done, amount)


## Follows this tracker from now on, and shows its current mission.
func bind(missions: RunMissions) -> void:
	if _missions != null:
		_missions.goal_progress.disconnect(_on_goal_progress)
		_missions.goal_completed.disconnect(_on_goal_completed)
		_missions.mission_started.disconnect(_on_mission_started)
		_missions.trick_counted.disconnect(_on_trick_counted)
	_clear_falls()
	_missions = missions
	missions.trick_counted.connect(_on_trick_counted)
	missions.goal_progress.connect(_on_goal_progress)
	missions.goal_completed.connect(_on_goal_completed)
	missions.mission_started.connect(_on_mission_started)
	show_current()


## Rebuilds the rows from the tracker's current mission; hidden when all are done.
func show_current() -> void:
	_clear_falls()
	for r in rows:
		remove_child(r)
		(r as Node).free()
	rows = []
	var goals := _missions.current_goals() if _missions != null else []
	visible = not goals.is_empty()
	var y := PAD.y + HEADER_H
	for i in goals.size():
		var g: Dictionary = goals[i]
		var row := _make_row(i, g)
		row.position = Vector2(MARGIN_X, y)
		add_child(row)
		rows.append(row)
		y += row.size.y + ROW_GAP
	if _overlay != null:
		move_child(_overlay, get_child_count() - 1)
	queue_redraw()


func _make_row(i: int, g: Dictionary) -> Row:
	var row := Row.new()
	row.name = "Goal%d" % i
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.goal_index = i
	row.trick = String(g["trick"])
	row.kind = String(g["kind"])
	row.amount = float(g["amount"])
	var l := Label.new()
	l.name = "Text"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudStyle.apply(l, "mission_goal")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var w := PAGE_SIZE.x - MARGIN_X - TEXT_X + 6.0 - PAD.x
	l.custom_minimum_size = Vector2(w, 0)
	l.text = line_text(row.trick, row.kind, float(g["done"]), row.amount)
	l.position = Vector2(TEXT_X - MARGIN_X, 0)
	row.label = l
	row.add_child(l)
	var font := l.get_theme_font("font")
	var fs := l.get_theme_font_size("font_size")
	var h := font.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, w, fs).y
	row.size = Vector2(TEXT_X - MARGIN_X + w, maxf(h, BOX_SIZE + 4.0))
	l.size = Vector2(w, h)
	row.ticked = bool(g["completed"])
	row.crossed = row.ticked
	return row


func _on_goal_progress(_mission: int, goal: int, done: float, _total: float) -> void:
	_defer(func() -> void:
		if goal >= rows.size():
			return
		var row: Row = rows[goal]
		row.label.text = line_text(row.trick, row.kind, done, row.amount)
		row.queue_redraw())


func _on_goal_completed(_mission: int, goal: int) -> void:
	_defer(func() -> void:
		if goal >= rows.size():
			return
		var row: Row = rows[goal]
		row.ticked = true
		row.crossed = true
		row.queue_redraw())


func _on_mission_started(_index: int) -> void:
	# The next mission replaces the page only after the last box has landed.
	_defer(func() -> void: show_current(), true)


## Runs `what` now, or after the last box in flight has landed, so the page changes in order.
func _defer(what: Callable, replaces_page := false) -> void:
	if _falls.is_empty():
		what.call()
		return
	_deferred.append({"after": _fall_seq, "call": what, "page": replaces_page})


## A trick counts toward goal `goal`: its name falls into the page.
func _on_trick_counted(_mission: int, goal: int, trick_id: String) -> void:
	if goal >= rows.size() or not TrickPopups.TEXTS.has(trick_id):
		return
	if _falls.size() >= MAX_QUEUED:
		return  # a burst: the count just updates
	_fall_seq += 1
	var row: Row = rows[goal]
	var text: String = TrickPopups.TEXTS[trick_id]
	var font := header_label.get_theme_font("font")
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOX_FONT_SIZE).x + 14.0
	w = minf(w, PAGE_SIZE.x - 8.0)
	var start := maxf(_clock, _last_start + FALL_GAP)
	_last_start = start
	_falls.append({
		"id": _fall_seq, "text": text, "w": w, "start": start,
		"x": clampf(row.position.x + row.label.position.x, 4.0, PAGE_SIZE.x - w - 4.0),
		"land_y": row.position.y + 2.0 - BOX_H * 0.5,
		"landed_at": -1.0})
	set_process(true)


## Moves the boxes on by `delta` seconds (also called by the tests).
func advance(delta: float) -> void:
	_clock += delta
	for f in _falls:
		if f["landed_at"] < 0.0 and _clock >= f["start"] + FALL_TIME:
			f["landed_at"] = f["start"] + FALL_TIME
			_run_deferred(int(f["id"]))
	var kept: Array = []
	for f in _falls:
		if f["landed_at"] < 0.0 or _clock < f["landed_at"] + SPLASH_TIME:
			kept.append(f)
	_falls = kept
	if _falls.is_empty():
		set_process(false)
		_deferred.clear()
	_overlay.queue_redraw()


func _process(delta: float) -> void:
	advance(delta)


func _run_deferred(fall_id: int) -> void:
	while not _deferred.is_empty() and int(_deferred[0]["after"]) <= fall_id:
		var d: Dictionary = _deferred.pop_front()
		(d["call"] as Callable).call()


## Drops every box and applies the held-back changes at once (not a mission change that
## is rebuilding the page itself).
func _clear_falls() -> void:
	_falls.clear()
	var held := _deferred.duplicate()
	_deferred.clear()
	for d in held:
		if not bool(d["page"]):
			(d["call"] as Callable).call()
	if _overlay != null:
		_overlay.queue_redraw()
	set_process(false)


## Plays every box out at once (a tick of the clock each), so the page shows its final state.
func finish_falls() -> void:
	var guard := 0
	while not _falls.is_empty() and guard < 1000:
		advance(0.1)
		guard += 1


## True while a box is falling, waiting or splashing.
func is_falling() -> bool:
	return not _falls.is_empty()


## Where a box is at the clock's time: {"y", "squash"}, or {} before it starts.
func box_state(f: Dictionary) -> Dictionary:
	var t: float = _clock - float(f["start"])
	if t < 0.0:
		return {}
	var u := clampf(t / FALL_TIME, 0.0, 1.0)
	var y := lerpf(BOX_START_Y, float(f["land_y"]), u * u)  # gravity: it speeds up
	var squash := 1.0
	if f["landed_at"] >= 0.0:
		var since: float = _clock - float(f["landed_at"])
		squash = 1.0 - 0.45 * clampf(1.0 - since / SQUASH_TIME, 0.0, 1.0)
	return {"y": y, "squash": squash}


func _draw_falls() -> void:
	var font := header_label.get_theme_font("font")
	for f in _falls:
		var st := box_state(f)
		if st.is_empty():
			continue
		var landed: bool = f["landed_at"] >= 0.0
		var since := _clock - float(f["landed_at"]) if landed else 0.0
		var w: float = f["w"]
		var x: float = f["x"]
		if not landed or since < SQUASH_TIME:
			var h := BOX_H * float(st["squash"])
			var box := Rect2(x, float(st["y"]) + BOX_H - h, w, h)
			_overlay.draw_rect(box.grow(2.0), HudStyle.MISSION_INK)
			_overlay.draw_rect(box, HudStyle.MISSION_PAPER)
			_overlay.draw_string(font, box.position + Vector2(0, h * 0.5 + 5.0), String(f["text"]),
				HORIZONTAL_ALIGNMENT_CENTER, w, BOX_FONT_SIZE, HudStyle.MISSION_INK)
		if landed:
			var p := clampf(since / SPLASH_TIME, 0.0, 1.0)
			var base := Vector2(x + w * 0.5, float(f["land_y"]) + BOX_H)
			for k in DROPLETS:
				var a := PI + PI * (float(k) + 0.5) / float(DROPLETS)  # an upward fan
				var dir := Vector2(cos(a) * 1.5, sin(a))
				var pos := base + dir * (14.0 + 26.0 * p) + Vector2(0, 30.0 * p * p)
				var d := 6.0 * (1.0 - p) + 2.0
				_overlay.draw_rect(Rect2(pos - Vector2(d, d) * 0.5, Vector2(d, d)),
					Color(0.25, 0.45, 0.75))


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var page := art(PAGE_ART)
	if page != null:
		draw_texture_rect(page, r, false)
		return
	draw_rect(r.grow(2.0), HudStyle.MISSION_EDGE)
	draw_rect(r, HudStyle.MISSION_PAPER)
	var y := PAD.y + HEADER_H + RULE_STEP - 4
	while y < size.y - 6:
		draw_line(Vector2(4, y), Vector2(size.x - 4, y), HudStyle.MISSION_RULE, 1.0)
		y += RULE_STEP
	draw_line(Vector2(MARGIN_X - 6.0, 0), Vector2(MARGIN_X - 6.0, size.y), HudStyle.MISSION_MARGIN, 2.0)
