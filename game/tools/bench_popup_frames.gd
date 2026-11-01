extends SceneTree
## T-480: a scripted run of trick popups (many names, heat steps, distinct amounts, broken
## cards) at 60 frames a second. Times, per popup, the show_popup call (where the
## pictures are made now) and the picture lookups the popup's _draw() does each frame
## (texture() or broken_textures()), and the popup's _process.
## Run: godot --headless --path game -s res://tools/bench_popup_frames.gd
const Popups := preload("res://scripts/hud/trick_popups.gd")

var _popups
var _show_ms: Array[float] = []
var _draw_ms: Array[float] = []
var _proc_ms: Array[float] = []
var _live := []


func _initialize() -> void:
	_popups = Popups.new()
	_popups.fly_amounts = true
	root.add_child(_popups)
	_run()


func _run() -> void:
	var ids := Popups.TEXTS.keys()
	var n := 0
	# Let a prewarm (when there is one) finish, as it does while the player drives to the first trick.
	for i in 90:
		await process_frame
		OS.delay_msec(16)
	for frame in 60 * 40:
		if frame % 30 == 0:
			var t0 := Time.get_ticks_usec()
			var p
			if n % 5 == 4:
				p = _popups.show_popup(Popups.BROKEN_TEXT, Vector2(300, 300), Popups.SIZE_NORMAL, Callable(), 0, true)
			else:
				var id: String = ids[n % ids.size()]
				var text := "%s +%d.%dK" % [Popups.TEXTS[id], 3 + n * 7 % 90, n % 10]
				p = _popups.show_popup(text, Vector2(300, 300), Popups.SIZES[id], Callable(), n % 4, false, true)
				p.on_detach = func(_x): pass
			_show_ms.append((Time.get_ticks_usec() - t0) / 1000.0); print("SHOW %.1f %s heat %d" % [_show_ms[-1], p.text, p.heat])
			_live.append(p)
			n += 1
		for p in _live:
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				var t1 := Time.get_ticks_usec()
				if p.broken:
					p.broken_textures()
				else:
					p.texture()
				_draw_ms.append((Time.get_ticks_usec() - t1) / 1000.0)
		await process_frame
		OS.delay_msec(16)
		_live = _live.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	_report("show_popup", _show_ms)
	_report("draw lookups", _draw_ms)
	quit()


func _report(name: String, a: Array[float]) -> void:
	var s := a.duplicate()
	s.sort()
	var over := 0
	for v in a:
		if v >= 1.0:
			over += 1
	print("RESULT %s: calls %d, median %.3f ms, p99 %.3f ms, max %.2f ms, calls over 1 ms: %d" % [name, a.size(), s[s.size() / 2], s[int(s.size() * 0.99)], s[-1], over])
