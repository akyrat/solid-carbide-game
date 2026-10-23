class_name LikesSpring
extends Node
## The likes bar's spring (task T-273): the share of the bar that is shown
## (`shown`, 0 to 1) shoots to its new level in DURATION seconds, overshoots a
## little and settles (an ease-out-back), instead of jumping there at once.
## All the timing is here: tune DURATION and OVERSHOOT.
##
## When the bar fills completely, `fill_then` springs it to full first and,
## the moment it is full, starts it again from empty towards the leftover
## (`restarted` fires then). It never shows below the level it started from
## and the Hud clamps the picture at full. Pausable: it stands still while the
## game is paused. The Hud owns the numbers and draws them; this node only
## moves `shown`.

## Seconds from the old level to the new one (the settle ends here too).
const DURATION := 0.25
## The ease-out-back's overshoot strength; 1.2 passes the new level by about
## 5 percent of the step and settles.
const OVERSHOOT := 1.2

## The shown fill (0 to 1; it may pass 1 or the target a little while it
## overshoots, the Hud clamps what it draws).
signal changed(shown: float)
## The bar was full and starts again from empty (after `fill_then`).
signal restarted()

var shown := 0.0
var target := 0.0
## True while it moves.
var active := false
## True while it springs to full before starting again.
var has_follow := false
var follow := 0.0
var _from := 0.0
var _t := 0.0


func _init() -> void:
	name = "LikesSpring"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_process(false)


## The ease-out-back curve: 0 at 0, 1 at 1, above 1 in between, never below 0.
static func ease_back(t: float) -> float:
	var x := clampf(t, 0.0, 1.0) - 1.0
	return 1.0 + (OVERSHOOT + 1.0) * x * x * x + OVERSHOOT * x * x


## Where the fill is `t` seconds into a move from `from` to `to`.
static func value_at(from: float, to: float, t: float) -> float:
	return from + (to - from) * ease_back(t / DURATION)


## Moves to `ratio` at once, no spring, and drops any pending restart.
func snap(ratio: float) -> void:
	_stop()
	has_follow = false
	shown = ratio
	target = ratio
	changed.emit(shown)


## Springs from where it is now to `ratio`.
func spring_to(ratio: float) -> void:
	has_follow = false
	_start(ratio)


## Springs to full, then (once full) starts again from empty towards `ratio`.
func fill_then(ratio: float) -> void:
	has_follow = true
	follow = ratio
	_start(1.0)


## Changes the leftover a pending restart goes to.
func set_follow(ratio: float) -> void:
	follow = ratio


## Jumps to the end of everything it is doing (tests, and a new run).
func finish() -> void:
	if has_follow:
		_restart()
	_stop()
	shown = target
	changed.emit(shown)


func _start(to: float) -> void:
	_from = shown
	target = to
	_t = 0.0
	active = true
	set_process(true)


func _stop() -> void:
	active = false
	set_process(false)


func _process(delta: float) -> void:
	advance(delta)


## Moves on by `delta` seconds (tests call it directly).
func advance(delta: float) -> void:
	if not active:
		return
	_t += delta
	if _t >= DURATION:
		shown = target
		changed.emit(shown)
		if has_follow:
			# Full now: start again from empty, springing to the leftover.
			_restart()
			changed.emit(shown)
			_start(target)
		else:
			_stop()
		return
	shown = value_at(_from, target, _t)
	changed.emit(shown)


func _restart() -> void:
	has_follow = false
	shown = 0.0
	target = follow
	restarted.emit()
