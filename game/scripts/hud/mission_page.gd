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
## and no count. Each goal has a checkbox; a done goal is ticked and its line crossed off.
## When a mission completes the next one replaces it (mission_started); after the last one
## the page hides (RunMissions.is_all_done).
##
## Place (layout page 1152 x 648, scaled by the HUD): the left edge between the weapon icons
## above (down to about y 300 with four weapons) and the coins at y 496 below.

const TEXTS_PATH := "res://data/screen_texts.json"
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
var header_label: Label
var _missions: RunMissions


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
	visible = false


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


## A goal's line: its text with {done}/{total} or {seconds} filled in.
static func goal_text(trick: String, kind: String, done: float, amount: float) -> String:
	var template := String(texts().get("goals", {}).get(trick, ""))
	return template.replace("{done}", format_number(floorf(done) if kind == "count" else done)) \
		.replace("{total}", format_number(amount)) \
		.replace("{seconds}", format_number(amount))


## Follows this tracker from now on, and shows its current mission.
func bind(missions: RunMissions) -> void:
	if _missions != null:
		_missions.goal_progress.disconnect(_on_goal_progress)
		_missions.goal_completed.disconnect(_on_goal_completed)
		_missions.mission_started.disconnect(_on_mission_started)
	_missions = missions
	missions.goal_progress.connect(_on_goal_progress)
	missions.goal_completed.connect(_on_goal_completed)
	missions.mission_started.connect(_on_mission_started)
	show_current()


## Rebuilds the rows from the tracker's current mission; hidden when all are done.
func show_current() -> void:
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
	l.text = goal_text(row.trick, row.kind, float(g["done"]), row.amount)
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
	if goal >= rows.size():
		return
	var row: Row = rows[goal]
	row.label.text = goal_text(row.trick, row.kind, done, row.amount)
	row.queue_redraw()


func _on_goal_completed(_mission: int, goal: int) -> void:
	if goal >= rows.size():
		return
	var row: Row = rows[goal]
	row.ticked = true
	row.crossed = true
	row.queue_redraw()


func _on_mission_started(_index: int) -> void:
	show_current()


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
