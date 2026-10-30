class_name SubGoal
extends Control
## The sub goal (task T-337; HUD and menus, Decisions, "The HUD looks like a
## livestream"): a black square that fills green from the bottom as subs come
## in, with the gift pack inside it, greyed out and dimmed until the goal is
## reached, and the "{subs} / {goal} SUBS" label (T-331) with the subs icon
## under it. It replaces the likes bar and its "Likes ... Hype Lv" row.
##
## It only shows: the Hud sets `fill` (the spring's shown share, 0 to 1),
## `lit` (the goal is reached), the label's numbers (`set_numbers`) and starts
## `celebrate()` at a level-up. The frame and the subs icon are T-339's art,
## the gift is `art/gift_pack/package.png` cropped to its box. Placement comes
## from res://data/hud.json (`sub_goal.layout`, the board's layout page at
## 1152 x 648), anchored to the right edge.
##
## The celebration (the goal reached): the gift lights up in full colour and
## bounces, and a pixel glow rings the square, for CELEBRATE_FRAMES frames of
## ComboHeat.FLICKER_FRAME (1 s). It runs while the game is paused
## (PROCESS_MODE_ALWAYS), like the old bar's level-up animation (T-139).

const FRAME_PATH := "res://art/hud/subgoal_frame.png"
const ICON_PATH := "res://art/hud/subs_icon.png"
const GIFT_PATH := "res://art/gift_pack/package.png"
## T-339's HUD art is shown at 2x: one art pixel is two screen pixels.
const ART_SCALE := 2
## The gift fills this share of the square (a 10% margin on each side).
const GIFT_SHARE := 0.8
## The greyed gift's brightness (its grey times this) until the goal.
const GREY_DIM := 0.6
## The label under the square, and the space between it and the square.
const LABEL_FONT_SIZE := HudStyle.LABEL_FONT_SIZE
const LABEL_GAP := 2
## The fill: the HUD's green (the health bar's, not Greenbull's light green),
## with a lighter top line one art pixel tall. Colours are HudStyle's (T-428).
const FILL_COLOR := HudStyle.HEALTH_COLOR
const FILL_TOP_COLOR := HudStyle.HEALTH_TOP_COLOR
## The celebration: frames, the gift's scale per frame (it bounces), and the
## glow ring's colour per frame (index into GLOW_COLORS, -1 = no glow).
const CELEBRATE_FRAMES := 12
const BOUNCE: Array[float] = [1.08, 1.16, 1.2, 1.12, 1.0, 0.94, 1.0, 1.06, 1.08, 1.03, 1.0, 1.0]
const GLOW_STEP: Array[int] = [0, 0, 1, 0, 1, 2, 1, 2, 2, -1, 2, -1]
## White, pale mint (the fill's top line), the fill's green.
const GLOW_COLORS: Array[Color] = HudStyle.SUB_GOAL_GLOW
## The glow ring: art pixels wide, outside the frame.
const GLOW_WIDTH := 2

## The shown fill, 0 to 1 (clamped).
var fill := 0.0:
	set(value):
		fill = clampf(value, 0.0, 1.0)
		queue_redraw()
## True when the goal is reached: the gift in full colour.
var lit := false:
	set(value):
		if lit == value:
			return
		lit = value
		if gift != null:
			gift.texture = _gift_color if lit else _gift_grey
## The label's numbers.
var subs := 0
var goal := 0
## True while the celebration plays.
var celebrating := false
## The celebration's frame (0 to CELEBRATE_FRAMES - 1) while it plays.
var frame := 0
## How many times it has started (tests count them).
var celebrations := 0

## The square's frame art, shown at ART_SCALE (128 x 128).
var square_size := Vector2.ZERO
var gift: TextureRect
var label: Label
var icon: TextureRect
## Icon and label, centred under the square.
var label_row: HBoxContainer
var _frame_tex: Texture2D
var _gift_color: Texture2D
var _gift_grey: Texture2D
## The black inside, row by row in art pixels: Vector3i(y, x_from, x_to).
var _inside_rows: Array[Vector3i] = []
var _time := 0.0
var _layout: Dictionary = {}


func _init() -> void:
	name = "SubGoal"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)
	var r := GameData.load_file("hud")
	var cfg: Dictionary = r.data.get("sub_goal", {}) if r.ok else {}
	_layout = cfg.get("layout", {"x": 988, "y": 340, "w": 128, "h": 180, "reference_w": 1152, "reference_h": 648})
	_frame_tex = load(FRAME_PATH)
	square_size = _frame_tex.get_size() * ART_SCALE
	_inside_rows = inside_rows(_frame_tex.get_image())
	_build_gift()
	_build_label()
	_anchor()


## Anchored to the right edge (the board's layout page): the same distance from
## it at any window width, and at the same share of the height (x988 y340 at
## 1152 x 648 is 36 px from the right edge, about two thirds down).
func _anchor() -> void:
	var ref_w := float(_layout["reference_w"])
	var ref_h := float(_layout["reference_h"])
	var y_share := float(_layout["y"]) / ref_h
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = y_share
	anchor_bottom = y_share
	offset_left = float(_layout["x"]) - ref_w
	offset_right = offset_left + float(_layout["w"])
	offset_top = 0.0
	offset_bottom = float(_layout["h"])


## The frame's black inside, from its centre pixel's colour: per art row, the
## first and last inside pixel (the rounded corners make the rows differ).
static func inside_rows(img: Image) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var w := img.get_width()
	var h := img.get_height()
	var inside := img.get_pixel(w / 2, h / 2)
	for y in h:
		var x0 := -1
		var x1 := -1
		for x in w:
			if img.get_pixel(x, y).is_equal_approx(inside):
				if x0 < 0:
					x0 = x
				x1 = x
		# Only the inside: a row whose span starts in from the ring.
		if x0 > 0 and x1 < w - 1 and img.get_pixel(w / 2, y).is_equal_approx(inside):
			out.append(Vector3i(y, x0, x1))
	return out


func _build_gift() -> void:
	var img: Image = (load(GIFT_PATH) as Texture2D).get_image()
	img.convert(Image.FORMAT_RGBA8)
	var crop := img.get_region(img.get_used_rect())
	_gift_color = ImageTexture.create_from_image(crop)
	_gift_grey = ImageTexture.create_from_image(grey_image(crop))
	gift = TextureRect.new()
	gift.name = "Gift"
	gift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gift.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gift.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gift.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gift.texture = _gift_grey
	var box := roundf(square_size.x * GIFT_SHARE)
	gift.size = Vector2(box, box)
	gift.position = ((square_size - gift.size) / 2.0).round()
	gift.pivot_offset = gift.size / 2.0
	add_child(gift)


## The gift greyed out and dimmed: each pixel's grey times GREY_DIM, alpha kept.
static func grey_image(src: Image) -> Image:
	var out := src.duplicate() as Image
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			var g := (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) * GREY_DIM
			out.set_pixel(x, y, Color(g, g, g, c.a))
	return out


func _build_label() -> void:
	label_row = HBoxContainer.new()
	label_row.name = "LabelRow"
	label_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_row.alignment = BoxContainer.ALIGNMENT_CENTER
	label_row.add_theme_constant_override("separation", 4)
	add_child(label_row)
	icon = TextureRect.new()
	icon.name = "SubsIcon"
	icon.texture = load(ICON_PATH)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.custom_minimum_size = icon.texture.get_size() * ART_SCALE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label_row.add_child(icon)
	label = Label.new()
	label.name = "SubGoalLabel"
	HudStyle.apply(label, "sub_goal")
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	label_row.add_child(label)
	set_numbers(0, 0)
	label_row.resized.connect(_layout_label)
	label.resized.connect(_layout_label)


## The label row centred under the square (it may be wider than the square).
func _layout_label() -> void:
	label_row.size = label_row.get_combined_minimum_size()
	label_row.position = Vector2(
		roundf((square_size.x - label_row.size.x) / 2.0), square_size.y + LABEL_GAP)


## "42 / 156 SUBS" (T-331's text, Hud.TEXT_SUB_GOAL).
static func label_text(sub_count: int, goal_count: int) -> String:
	return Hud.TEXT_SUB_GOAL.format({"subs": sub_count, "goal": goal_count})


func set_numbers(sub_count: int, goal_count: int) -> void:
	subs = sub_count
	goal = goal_count
	label.text = label_text(sub_count, goal_count)
	_layout_label()


## The square's rectangle in this node's coordinates (the label is under it).
func square_rect() -> Rect2:
	return Rect2(Vector2.ZERO, square_size)


## The gift's drawn rectangle (the cropped art kept to its aspect, centred in
## its 80% box), in this node's coordinates, at rest.
func gift_drawn_rect() -> Rect2:
	var ts := gift.texture.get_size()
	var k := minf(gift.size.x / ts.x, gift.size.y / ts.y)
	var s := ts * k
	return Rect2(gift.position + (gift.size - s) / 2.0, s)


## How many art rows of the inside are green at the current fill.
func filled_rows() -> int:
	return int(roundf(fill * _inside_rows.size()))


func inside_row_count() -> int:
	return _inside_rows.size()


## The goal is reached: the gift bounces and the square glows (the Hud sets
## `lit`). A new one restarts it.
func celebrate() -> void:
	celebrating = true
	celebrations += 1
	_time = 0.0
	frame = 0
	_apply_frame()
	set_process(true)


## Ends the celebration at once (a new run, tests).
func stop() -> void:
	celebrating = false
	_time = 0.0
	frame = 0
	gift.scale = Vector2.ONE
	set_process(false)
	queue_redraw()


## The celebration's length in seconds.
static func celebrate_length() -> float:
	return CELEBRATE_FRAMES * ComboHeat.FLICKER_FRAME


func _process(delta: float) -> void:
	advance(delta)


## Moves the celebration on by `delta` seconds (tests call it directly).
func advance(delta: float) -> void:
	if not celebrating:
		return
	_time += delta
	var f := int(floorf(_time / ComboHeat.FLICKER_FRAME))
	if f >= CELEBRATE_FRAMES:
		stop()
		return
	if f != frame:
		frame = f
		_apply_frame()


func _apply_frame() -> void:
	gift.scale = Vector2.ONE * BOUNCE[frame]
	queue_redraw()


## The glow ring's colour now, or a transparent colour when none shows.
func glow_color() -> Color:
	if not celebrating or GLOW_STEP[frame] < 0:
		return HudStyle.NO_GLOW
	return GLOW_COLORS[GLOW_STEP[frame]]


func _draw() -> void:
	var p := float(ART_SCALE)
	var g := glow_color()
	if g.a > 0.0:
		# A square ring of whole art pixels just outside the frame.
		var o := GLOW_WIDTH * p
		var r := Rect2(-Vector2(o, o), square_size + Vector2(o, o) * 2.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, o)), g)
		draw_rect(Rect2(Vector2(r.position.x, r.end.y - o), Vector2(r.size.x, o)), g)
		draw_rect(Rect2(Vector2(r.position.x, r.position.y + o), Vector2(o, r.size.y - o * 2.0)), g)
		draw_rect(Rect2(Vector2(r.end.x - o, r.position.y + o), Vector2(o, r.size.y - o * 2.0)), g)
	draw_texture_rect(_frame_tex, square_rect(), false)
	var n := filled_rows()
	var total := _inside_rows.size()
	for i in n:
		var row: Vector3i = _inside_rows[total - 1 - i]
		var c := FILL_TOP_COLOR if i == n - 1 else FILL_COLOR
		# Vector3i(art row, first inside x, last inside x), at ART_SCALE.
		draw_rect(Rect2(Vector2(row.y, row.x) * p, Vector2(row.z - row.y + 1, 1) * p), c)
