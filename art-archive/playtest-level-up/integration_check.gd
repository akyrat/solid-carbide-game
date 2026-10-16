extends Node
## Throwaway integration check (playtest build): one run, level-up -> helicopter ->
## package falls and lands -> drive over it -> level-up screen -> take a card -> run resumes.
## Run with the screenshot tool's scene runner, e.g.:
##   godot --path game -s res://tools/screenshot.gd -- --scene=res://tests/fixtures/integration_check.tscn --frames=2000 --out=x.png
## (copy this file and a scene using it into game/tests/fixtures/ first; the copy is not committed)

const OUT := "res://../art-archive/playtest-level-up/"
var game: Node
var run: Node2D
var fails := 0


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://").path_join("../art-archive/playtest-level-up/") + name + ".png"
	img.save_png(path)
	print("SHOT ", name)


func _check(ok: bool, msg: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + msg)
	if not ok:
		fails += 1


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ready() -> void:
	game = preload("res://scenes/game/game.tscn").instantiate()
	add_child(game)
	game.menu.start_button.pressed.emit()
	await _frames(3)
	run = game.run
	run.minions.enabled = false
	var state: RunState = run.state
	var hud: Hud = run.hud
	await _shot("1_before_level_up")
	var lvl := state.level
	state.add_xp(state.xp_needed())
	await _frames(1)
	_check(state.level == lvl + 1, "level rose")
	_check(run.gift_drops.helicopters.size() == 1, "helicopter sent")
	_check(not run.level_up_screen.visible and not get_tree().paused, "screen not opened by the level-up itself")
	await _shot("2_level_up_flash_helicopter_enters")
	await _frames(4)
	await _shot("3_flash_frame_later")
	# wait for falling
	var pkg: GiftPackage = null
	var guard := 0
	while guard < 1500 and (run.gift_drops.packages.is_empty() or not run.gift_drops.packages[0].is_falling()):
		await get_tree().process_frame
		guard += 1
	_check(not run.gift_drops.packages.is_empty(), "package dropped")
	pkg = run.gift_drops.packages[0]
	await _frames(15)
	await _shot("4_package_falling_with_parachute")
	guard = 0
	while guard < 1500 and not pkg.is_landed():
		await get_tree().process_frame
		guard += 1
	_check(pkg.is_landed(), "package landed")
	await _frames(3)
	await _shot("5_package_landed")
	# drive over it
	run.car.use_keyboard = false
	run.car.scripted_input = [true, false, 0.0]
	guard = 0
	while guard < 1500 and not run.level_up_screen.visible:
		await get_tree().process_frame
		guard += 1
	_check(run.level_up_screen.visible, "driving over the package opens the level-up screen")
	_check(get_tree().paused, "run paused while screen is open")
	_check(run.gift_drops.packages.is_empty(), "package removed on pickup")
	await _frames(4)
	await _shot("6_level_up_screen_build_up")
	guard = 0
	while guard < 300 and run.level_up_screen.is_animating():
		await get_tree().process_frame
		guard += 1
	await _frames(2)
	await _shot("7_level_up_screen_finished")
	var ids := []
	for c in run.level_up_screen.cards:
		ids.append(c.id)
	_check(ids.size() >= 1, "cards offered: %s" % str(ids))
	run.level_up_screen.take_highlighted()
	await _frames(3)
	_check(not run.level_up_screen.visible, "screen closed after taking a card")
	_check(not get_tree().paused, "run resumed")
	run.car.scripted_input = [false, false, 0.0]
	var t0: float = state.time_left if "time_left" in state else 0.0
	await _frames(30)
	await _shot("8_run_resumed")
	print("RESULT fails=", fails)
	get_tree().quit(1 if fails > 0 else 0)
