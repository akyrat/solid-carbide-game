extends SceneTree
## The screen gallery (task T-479): opens every screen the player can meet, one after the other,
## and saves a 1280 x 720 PNG of each, with a manifest.json naming each screen, its file and how
## it was reached. For the board's pass through every menu before the MVP
## (HUD and menus, Decisions and Content, "The MVP pass: the screen gallery and the text list").
##
## Needs a real window (not --headless). Normally run through screen_gallery.py:
##   python game/tools/screen_gallery.py [--out screenshots/mvp-gallery]
## or by hand:
##   godot --path game --resolution 1280x720 -s res://tools/screen_gallery.gd -- --out=C:/abs/dir
##
## The game's own saves are never touched: settings, progress and the runs list point at
## user://gallery_*.* files, which are deleted first. A screen it can't reach is written in the
## manifest under "not_reached" with the reason; the script still exits 0.

var SIZE := Vector2i(1280, 720)  ## 1280 x 720, or --size=WxH (the scaling scan, T-493)
const GameSettingsScript := preload("res://scripts/ui/game_settings.gd")

var _out := ""
var _shots: Array = []
var _not_reached: Array = []
var _game: Node = null
var _text_mode := false  ## --text-layout (T-524): each shot also saves a _blank.png and the text nodes' rows
var _text_rows: Array = []
var _text_screens: Array = []
var _not_capturable: Array = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--size="):
			var parts := arg.substr(7).split("x")
			SIZE = Vector2i(int(parts[0]), int(parts[1]))
		elif arg == "--text-layout":
			_text_mode = true
	if _out == "":
		printerr("screen_gallery.gd: need --out=<folder>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	TextLayout.out_dir = _out
	_run()


func _run() -> void:
	GameSettings.path = "user://gallery_settings.cfg"
	PlayerProgress.path = "user://gallery_progress.json"
	RunHistory.path = "user://gallery_history.json"
	for p in [GameSettings.path, PlayerProgress.path, RunHistory.path]:
		DirAccess.remove_absolute(p)
	root.size = SIZE
	await _frames(5)

	await _menu_and_tutorial()
	await _garage()
	await _hud()
	await _gift_and_power_up()
	await _pause()
	await _time_up_and_wreck()
	await _recaps()
	if _text_mode:
		await _text_states()
	_not_reached.append({"name": "runs_list", "reason": "the runs list (Past streams) is not in the game yet: its texts exist (runs_list_text.json) but no screen reads them"})

	var manifest := {"size": [SIZE.x, SIZE.y], "actual_window": [root.size.x, root.size.y], "screens": _shots, "not_reached": _not_reached}
	var f := FileAccess.open(_out.path_join("manifest.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "  ") + "\n")
	f.close()
	if _text_mode:
		var nf := FileAccess.open(_out.path_join("text_layout_nodes.json"), FileAccess.WRITE)
		nf.store_string(JSON.stringify({"size": [SIZE.x, SIZE.y], "screens": _text_screens, "rows": _text_rows, "not_capturable": _not_capturable}, "  ") + String.chr(10))
		nf.close()
	print("screen_gallery.gd: %d screens saved, %d not reached, in %s" % [_shots.size(), _not_reached.size(), _out])
	for p in [GameSettings.path, PlayerProgress.path, RunHistory.path]:
		DirAccess.remove_absolute(p)
	quit(0)


# ---- the screens ----------------------------------------------------------------------

func _menu_and_tutorial() -> void:
	await _fresh_game()
	await _frames(10)
	await _shot("main_menu", "Launch: the splash and main menu.")
	_game.show_tutorial()
	for i in 3:
		_game.tutorial.show_slide(i)
		await _frames(6)
		await _shot("tutorial_slide_%d" % (i + 1), "Main menu, Start: tutorial slide %d of 3." % (i + 1))


func _garage() -> void:
	await _fresh_game()
	var p: PlayerProgress = _game.progress
	p.coins = 120
	p.levels["damage_bonus"] = GarageData.new().max_level()
	p.levels["pickup_magnet"] = 3
	p.levels["air_turn"] = 6
	_game.show_garage()
	await _frames(10)
	await _shot("garage", "Main menu, Garage: 120 coins, one upgrade at its last level so every state shows.")


func _hud() -> void:
	await _start_run()
	await _frames(40)
	await _shot("hud_run_start", "Main menu, Start (tutorial skipped): the run's HUD at the start, with the mission notebook page.")
	var run: Node = _game.run
	var m: RunMissions = run.state.missions
	m.start(7)
	_finish_goals(m)  # mission 1 done: mission 2 is "Alt drifts 0/10"
	for i in 5:
		m.on_trick("alternate_drift")
	await _frames(2)
	run.power_up_screen.visible = false  # the overlay opens on each completed mission
	await _frames(10)
	await _shot("hud_mission_page", "Run: mission 1 done, mission 2 half way, so the notebook page shows a count.")
	# Popups over the car: a trick with its multiplier add, a score and the cracked combo broken.
	run.power_up_screen.visible = false
	var state: RunState = run.state
	for i in 3:
		state.add_trick("three_sixty")
	await _frames(14)
	await _shot("hud_trick_popup", "Run: a trick popup with its multiplier add over the car.")
	state.combo_broken.emit()
	await _frames(10)
	await _shot("hud_combo_broken", "Run: the combo broken popup.")


func _gift_and_power_up() -> void:
	await _start_run()
	await _frames(20)
	var run: Node = _game.run
	run.weapons.offers.rng.seed = 3
	run.state.add_xp(run.state.xp_needed())
	run.gift_drops.pick_up_all()
	run.level_up_screen.skip_animation()
	await _frames(20)
	await _shot("level_up_gift_pack", "Run: the sub goal filled, the gift pack taken: the weapons gift screen with its cards.")
	await _start_run()
	await _frames(20)
	run = _game.run
	run.power_up_offers.rng.seed = 3
	run.state.missions.mission_completed.emit(0)
	run.power_up_screen.skip_animation()
	await _frames(20)
	await _shot("power_up_overlay", "Run: mission 1 completed: the driving power-up overlay with its two cards.")


func _pause() -> void:
	await _start_run()
	await _frames(30)
	var ps: CanvasLayer = _game.pause_screen
	ps.pause()
	await _frames(10)
	await _shot("pause_screen", "Run, Escape: the pause screen with its settings (zoom, volumes, HUD size, camera).")
	ps.open_trick_list()
	await _frames(8)
	await _shot("pause_trick_list", "Pause screen, Trick list.")
	ps.close_trick_list()
	await _frames(4)
	ps.open_hud_layout()
	await _frames(8)
	await _shot("pause_hud_layout_editor", "Pause screen, Edit HUD layout: the HUD layout editor.")


func _time_up_and_wreck() -> void:
	await _start_run()
	await _frames(20)
	var run: Node = _game.run
	var s: RunState = run.state
	s.advance(RunState.RUN_SECONDS + 1.0)
	var tu: CanvasLayer = run.get_node("TimeUpScreenLayer")
	tu.advance(2.0)
	await _frames(6)
	await _shot("time_up_screen", "Run: the clock reaches 0:00 with the kaiju alive: the time's up screen, about two seconds in.")
	await _start_run()
	await _frames(20)
	s = _game.run.state
	s.damage_car(s.max_health)
	await _frames(25)
	await _shot("wreck", "Run: the last heart lost: the wreck, before the run ends.")


func _recaps() -> void:
	for ending in ["win", "time_up", "wreck"]:
		await _start_run()
		await _frames(15)
		var run: Node = _game.run
		_script_run(run, ending)
		await _frames(2)
		var s: RunState = run.state
		match ending:
			"wreck":
				s.damage_car(s.max_health)
				s.advance(s.wreck_seconds)
			"time_up":
				s.advance(RunState.RUN_SECONDS + 1.0)
				s.advance(s.time_up_seconds)
			_:
				s.kaiju_killed()
		await _frames(10)
		if _game.recap == null:
			_not_reached.append({"name": "recap_" + ending, "reason": "the run did not end into the recap screen"})
			continue
		_game.recap.finish_animation()
		await _frames(6)
		await _shot("recap_" + ending, "Run ended by %s: the end-of-run recap, pop-in finished." % {"win": "the kaiju killed", "time_up": "the clock running out", "wreck": "the wreck"}[ending])


# ---- helpers --------------------------------------------------------------------------

func _fresh_game() -> void:
	if _game != null:
		root.remove_child(_game)
		_game.queue_free()
		_game = null
		await _frames(2)
	_game = preload("res://scenes/game/game.tscn").instantiate()
	root.add_child(_game)
	await _frames(3)


func _start_run() -> void:
	await _fresh_game()
	_game.start_run()  # straight into a run, without the tutorial slides
	await _frames(3)


func _finish_goals(m: RunMissions) -> void:
	for g in m.current_goals():
		if String(g["kind"]) == "seconds":
			m.on_trick(String(g["trick"]), float(g["amount"]))
		else:
			for i in int(g["amount"]):
				m.on_trick(String(g["trick"]))


## A scripted run for the recap, as the recap screen's own fixture does it.
func _script_run(run: Node, ending: String) -> void:
	var s: RunState = run.state
	var take := ["gun", "gun", "gun", "wiper", "wiper", "molotov", "underglow"]
	if ending == "win":
		take += ["flamethrower", "bricks", "gun"]
	for id in take:
		run.weapons.upgrade(id)
	for i in 47:
		s.enemy_slain("minion", "gun")
	if ending == "win":
		s.enemy_slain("kaiju", "wiper")
	for i in 4:
		s.add_trick("three_sixty")
	for i in 3:
		s.add_trick("alternate_drift")
	s.add_needle_trick()
	if ending == "win":
		s.add_airtime_trick(1.2)
		s.add_trick("air_one_eighty")
		s.add_trick("air_three_sixty")
		for i in 6:
			s.add_trick("extended_drift", 2.0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(shot_name: String, how: String) -> void:
	if _text_mode:
		Engine.time_scale = 0.0  # the pair (normal, blank) is taken in the same animation state
		await _frames(2)
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_not_reached.append({"name": shot_name, "reason": "the viewport gave no image (run with a window, not --headless)"})
		return
	if SIZE == Vector2i(1280, 720) and image.get_size() != SIZE:
		image.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_NEAREST)
	var file := shot_name + ".png"
	var err := image.save_png(_out.path_join(file))
	if err != OK:
		_not_reached.append({"name": shot_name, "reason": "saving the PNG failed (error %d)" % err})
		return
	var win := Vector2(image.get_size())
	_shots.append({"name": shot_name, "file": file, "how": how, "image_size": [image.get_width(), image.get_height()], "pieces": _pieces(win)})
	print("screen_gallery.gd: saved ", file)
	if _text_mode:
		await _text_pair(shot_name, how, image)
		Engine.time_scale = 1.0


## T-524: the rows of every text node on screen, then the same frame with the text blanked.
func _text_pair(shot_name: String, how: String, normal: Image) -> void:
	var nodes := TextLayout.find_nodes(root, Vector2(normal.get_size()))
	var count := _text_rows.size()
	for n in nodes:
		_text_rows.append(TextLayout.row(n, shot_name))
	for nc in TextLayout.not_capturable(root, shot_name):
		_not_capturable.append(nc)
	var undo := TextLayout.blank(nodes)
	await _frames(1)
	await RenderingServer.frame_post_draw
	var blank := root.get_texture().get_image()
	if SIZE == Vector2i(1280, 720) and blank.get_size() != SIZE:
		blank.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_NEAREST)
	var leaked := TextLayout.leaked(nodes)
	blank.save_png(_out.path_join(shot_name + "_blank.png"))
	TextLayout.restore(undo)
	# How much of the picture changed away from the text: pixels that differ outside every text rect
	# (grown by 6 px for outlines and shadows). Animation is frozen, so it should be near zero.
	var outside := 0
	var rects: Array = []
	for i in range(count, _text_rows.size()):
		var r: Array = _text_rows[i]["rect"]
		rects.append(Rect2(r[0], r[1], r[2], r[3]).grow(6.0))
	var step := 2
	for y in range(0, normal.get_height(), step):
		for x in range(0, normal.get_width(), step):
			if normal.get_pixel(x, y) != blank.get_pixel(x, y):
				var inside := false
				for r in rects:
					if (r as Rect2).has_point(Vector2(x, y)):
						inside = true
						break
				if not inside:
					outside += 1
	_text_screens.append({"name": shot_name, "file": shot_name + ".png", "blank_file": shot_name + "_blank.png", "how": how,
		"rows": _text_rows.size() - count, "text_nodes_still_showing_in_blank": leaked, "pixels_changed_outside_text": outside * step * step})


## The visible Controls that show something (T-493, the scaling scan): path, class and pixel rect.
## Ones that fill the window are left out, they are backgrounds, not content.
func _pieces(win: Vector2) -> Array:
	var out: Array = []
	_collect(root, win, out)
	return out


func _collect(n: Node, win: Vector2, out: Array) -> void:
	if n is Control:
		var c := n as Control
		if c.is_visible_in_tree() and c.modulate.a > 0.05 and c.self_modulate.a > 0.05 				and (c is Label or c is RichTextLabel or c is BaseButton or c is TextureRect or c is Range 				or c is Panel or c is PanelContainer or c is LineEdit or c is TextureProgressBar):
			var r := c.get_global_rect()
			if r.size.x > 1 and r.size.y > 1 and not (r.size.x >= win.x * 0.95 and r.size.y >= win.y * 0.95):
				out.append({"path": String(c.get_path()).replace("/root/", ""), "class": c.get_class(),
					"rect": [snappedf(r.position.x, 0.1), snappedf(r.position.y, 0.1), snappedf(r.size.x, 0.1), snappedf(r.size.y, 0.1)]})
	for ch in n.get_children():
		_collect(ch, win, out)


## T-524: the extra states that show each kind of text the shots above do not.
func _text_states() -> void:
	await _fresh_game()
	_game.show_tutorial()
	_game.tutorial.show_slide(3)
	await _frames(8)
	await _shot("tutorial_slide_4", "Main menu, Start: tutorial slide 4 of 4 (the goal).")
	# The combo multiplier beside the car, a few tricks in.
	await _start_run()
	await _frames(20)
	var run: Node = _game.run
	var state: RunState = run.state
	run.power_up_screen.visible = false
	for i in 4:
		state.add_trick("three_sixty")
	for i in 3:
		state.add_trick("alternate_drift")
	await _frames(100)
	await _shot("hud_combo_multiplier", "Run: a few tricks in, the combo multiplier beside the car.")
	state._cut_combo()
	await _frames(12)
	await _shot("hud_multiplier_loss", "Run: a crash cut the combo: the multiplier flashes red and drops what was lost.")
	state.sub_goal_healed.emit(1.0)
	await _frames(10)
	await _shot("hud_heal_popup", "Run: a full sub goal healed the car (all weapons maxed): the heal popup.")
	# The God mode page on the pause screen.
	await _start_run()
	await _frames(20)
	GodMode.unlocked = true
	var ps: CanvasLayer = _game.pause_screen
	ps.pause()
	ps.refresh_god_mode_entry()
	await _frames(8)
	await _shot("pause_god_mode_entry", "Run, Escape, after God mode is unlocked (N): the pause screen with its God mode button.")
	ps.open_god_mode()
	await _frames(8)
	await _shot("pause_god_mode_page", "Pause screen, God mode: the weapons and power-ups page.")
	GodMode.unlocked = false
