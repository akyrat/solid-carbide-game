class_name TimeUpScreen
extends CanvasLayer
## The time's up screen (task T-317; HUD and menus, Content, "Time's up screen";
## Game loop architecture, Decisions, "Time's up screen"). When the 8-minute
## timer runs out with the kaiju alive, RunState freezes the run at 0:00 (the
## scene tree is paused) and sends time_up_started(seconds); this plays the
## failure screen over the dimmed, frozen run for those seconds (3 s). RunState
## counts the seconds and sends run_ended when they are over; this only shows.
## It can't be skipped (a proposal for the playtest).
##
## Look (placeholder drawn in code, in the game's comic look): the headline on
## the COMBO BROKEN! popup's cracked warning-red card (ComboBrokenArt: Bangers,
## white letters with a black outline, black border, hard pixel edges), its
## crack in the space between words nearest the middle so no letter is lost, shown
## at a whole-pixel scale so the edges stay hard.
## Animation (a proposal for the playtest), all a function of the time since it
## started (pose()), stepped at STEP_FPS frames a second like the comic popups:
## - 0.00-0.25 s: the run dims (DIM_ALPHA black).
## - 0.00-0.18 s: the headline slams in from SLAM_FROM times its size.
## - 0.18-0.60 s: the impact shake, dying away.
## - 0.90-1.30 s: the crack opens: the halves part, the right one drops and tilts.
## - to 3.00 s: it holds, cracked, over the frozen run; then the run ends.
## Text: data/screen_texts.json's time_up.headline (T-316), word for word.

const ComboBrokenArt := preload("res://scripts/hud/combo_broken_art.gd")

const TEXTS_PATH := "res://data/screen_texts.json"
## Over the HUD (10) and the level-up screen (15), under the pause screen (20).
const LAYER := 16
## The baked card's size style (ComboBrokenArt / TrickPopupArt "normal": 32 px Bangers).
const ART_STYLE := "normal"
## The card is scaled by the largest whole number that keeps it within this
## share of the screen's width, and never above MAX_SCALE.
const MAX_WIDTH_SHARE := 0.9
const MAX_SCALE := 4
const DIM_ALPHA := 0.55
const DIM_TIME := 0.25
const SLAM_TIME := 0.18
const SLAM_FROM := 2.6
const SHAKE_END := 0.6
## Shake amplitude in card pixels (times the scale on screen).
const SHAKE_PX := 3.0
const CRACK_START := 0.9
const CRACK_END := 1.3
## How far the halves part (card pixels, each side), the right half's drop, and the tilts.
const CRACK_PART_PX := 4.0
const CRACK_DROP_PX := 6.0
const LEFT_TILT_DEG := -2.0
const RIGHT_TILT_DEG := 5.0
## The animation's frames a second (stepped, like the level-up screen's build-up).
const STEP_FPS := 30.0

## The run's state, once bound.
var state: RunState
## The headline from the data file.
var headline := ""
## Seconds the screen lasts (from time_up_started) and seconds since it started.
var duration := 0.0
var elapsed := 0.0
var playing := false
## The whole-pixel scale the card is drawn at.
var art_scale := 1
var dim: ColorRect
## The card's two halves (left, right), centred on `card`.
var card: Node2D
var left_half: Sprite2D
var right_half: Sprite2D


## The headline from the data file (T-316), "" with an error if it is missing.
static func load_headline() -> String:
	var f := FileAccess.open(TEXTS_PATH, FileAccess.READ)
	if f == null:
		push_error("TimeUpScreen: cannot open %s" % TEXTS_PATH)
		return ""
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY or not data.has("time_up") \
			or not (data.time_up is Dictionary) or not data.time_up.has("headline"):
		push_error("TimeUpScreen: %s has no time_up.headline" % TEXTS_PATH)
		return ""
	return String(data.time_up.headline)


## The pose at `t` seconds after the start, stepped to STEP_FPS frames:
## dim (alpha), scale (times art_scale), shake (card px offset of both halves),
## left / right (card px offsets of each half) and their tilts (degrees).
static func pose(t: float) -> Dictionary:
	var s := floorf(maxf(t, 0.0) * STEP_FPS + 0.0001) / STEP_FPS
	var p := {}
	p.dim = DIM_ALPHA * clampf(s / DIM_TIME, 0.0, 1.0)
	var slam := clampf(s / SLAM_TIME, 0.0, 1.0)
	p.scale = lerpf(SLAM_FROM, 1.0, slam * slam)  # accelerates onto the screen
	var shake := Vector2.ZERO
	if s >= SLAM_TIME and s < SHAKE_END:
		var k := (s - SLAM_TIME) / (SHAKE_END - SLAM_TIME)
		var amp := SHAKE_PX * (1.0 - k)
		var n := int(round(s * STEP_FPS))
		shake = Vector2(amp if n % 2 == 0 else -amp, amp * 0.5 if (n / 2) % 2 == 0 else -amp * 0.5)
	p.shake = shake
	var c := clampf((s - CRACK_START) / (CRACK_END - CRACK_START), 0.0, 1.0)
	c = 1.0 - (1.0 - c) * (1.0 - c)  # eases out
	p.crack = c
	p.left = Vector2(-CRACK_PART_PX * c, 0.0)
	p.right = Vector2(CRACK_PART_PX * c, CRACK_DROP_PX * c)
	p.left_tilt = LEFT_TILT_DEG * c
	p.right_tilt = RIGHT_TILT_DEG * c
	return p


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS  # plays while the frozen run is paused
	headline = load_headline()
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0, 0, 0, 0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	card = Node2D.new()
	card.name = "Headline"
	add_child(card)
	var tex: Array = ComboBrokenArt.textures(headline, ART_STYLE, true)  # the crack between words
	left_half = _half("Left", tex[0])
	right_half = _half("Right", tex[1])
	visible = false


func _half(node_name: String, tex: Texture2D) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.name = node_name
	sp.texture = tex
	sp.centered = true
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card.add_child(sp)
	return sp


## Listens to the run's state: shows on time_up_started, hides when the run ends
## or a new one starts.
func bind(s: RunState) -> void:
	state = s
	state.time_up_started.connect(play)
	state.run_ended.connect(func(_r: String, _c: int) -> void: stop())
	state.run_started.connect(stop)


## Starts the screen for `seconds`.
func play(seconds: float) -> void:
	duration = seconds
	elapsed = 0.0
	playing = true
	visible = true
	_layout()
	_apply()


func stop() -> void:
	playing = false
	visible = false


func is_playing() -> bool:
	return playing


func _process(delta: float) -> void:
	if playing:
		advance(delta)


## Moves the animation on by `seconds` (tests and the screenshot tool call it).
## It holds its last pose at the end; RunState ends the run.
func advance(seconds: float) -> void:
	elapsed = minf(elapsed + maxf(seconds, 0.0), duration)
	_apply()


## The card's size in card pixels (the baked image).
func card_size() -> Vector2:
	return left_half.texture.get_size() if left_half.texture != null else Vector2.ZERO


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1152, 648)
	var w := card_size().x
	art_scale = 1
	if w > 0.0:
		art_scale = clampi(int(floor(vp.x * MAX_WIDTH_SHARE / w)), 1, MAX_SCALE)
	card.position = (vp * 0.5).round()


func _apply() -> void:
	var p := pose(elapsed)
	dim.color = Color(0, 0, 0, p.dim)
	var sc: float = art_scale * p.scale
	card.scale = Vector2(sc, sc)
	var vp := get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1152, 648)
	card.position = (vp * 0.5 + p.shake * art_scale).round()
	left_half.position = p.left
	right_half.position = p.right
	left_half.rotation_degrees = p.left_tilt
	right_half.rotation_degrees = p.right_tilt
