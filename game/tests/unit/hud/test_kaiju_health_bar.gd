extends GutTest
## Task T-050: the kaiju's health bar above it. Hidden before the kaiju
## appears, showing its health after (following the health signal), hidden when
## it dies; follows the kaiju, sits above it, is as wide as it is, has a divider
## at every 10%, is drawn above buildings; no Redgull red.

const RunScene := preload("res://scenes/run/run.tscn")
const KaijuBossScript := preload("res://scripts/enemies/kaiju_boss.gd")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")

var run: Node2D
var boss: Node
var bar: KaijuHealthBar


func before_each() -> void:
	get_tree().paused = false  # an earlier test (the run now pauses on level-ups) may leave the tree paused
	KaijuBossScript.playtest_override = -1.0  # the game's rules, whatever playtest.json says
	FlameScript.playtest_override = 0
	run = RunScene.instantiate()
	add_child_autofree(run)
	boss = run.kaiju_boss
	boss.rng.seed = 50
	run.minions.enabled = false
	run.car.use_keyboard = false
	bar = run.kaiju_health_bar


func after_each() -> void:
	get_tree().paused = false
	KaijuBossScript.playtest_override = -2.0
	FlameScript.playtest_override = -1


func _appear() -> Node:
	var car_units: Vector2 = run.car.position / 16.0
	boss.enabled = false
	var k: Node = boss.appear_at(car_units + Vector2(-5.0, 4.0))
	boss.update_drawing()
	return k


func test_hidden_before_the_kaiju_appears() -> void:
	assert_not_null(bar)
	assert_false(bar.visible)


func test_shows_health_after_appearing_and_follows_signal() -> void:
	var k := _appear()
	assert_true(bar.visible)
	assert_almost_eq(bar.fraction, 1.0, 0.0001)
	k.take_damage(k.max_health * 0.25)
	assert_almost_eq(bar.fraction, 0.75, 0.0001)
	k.take_damage(k.max_health * 0.5)
	assert_almost_eq(bar.fraction, 0.25, 0.0001)
	assert_true(bar.visible)


func test_hides_when_the_kaiju_dies() -> void:
	var k := _appear()
	k.take_damage(k.max_health)
	assert_false(bar.visible)


func test_hides_in_a_new_run() -> void:
	_appear()
	run.start_run()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_false(bar.visible)


func test_follows_the_kaiju_above_it_and_as_wide() -> void:
	var k := _appear()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var s: Node2D = k.sprite
	assert_almost_eq(bar.position.x, s.position.x, 1.0)
	assert_lt(bar.position.y, s.position.y - s.drawn_height_px(), "above the head")
	assert_almost_eq(bar.bar_width, s.drawn_width_px(), 1.0, "as wide as the kaiju")
	var before := bar.position
	k.set_position_units(k.position_units() + Vector2(3, 0))
	boss.update_drawing()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_ne(bar.position, before, "moved with the kaiju")
	assert_almost_eq(bar.position.x, k.sprite.position.x, 1.0)


func test_width_follows_the_sprite() -> void:
	# Final art in place of the placeholder: another sprite with its own width.
	var k := _appear()
	var stub_script := GDScript.new()
	stub_script.source_code = "extends Node2D
func drawn_width_px() -> float:
	return 200.0
func drawn_height_px() -> float:
	return 50.0
"
	stub_script.reload()
	var stub := Node2D.new()
	stub.set_script(stub_script)
	add_child_autofree(stub)
	stub.position = Vector2(30, 40)
	k.sprite = stub
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(bar.bar_width, 200.0)
	assert_almost_eq(bar.position.y, 40.0 - 50.0 - KaijuHealthBar.GAP - KaijuHealthBar.OUTLINE, 1.0)
	k.sprite = null


func test_divider_at_every_ten_percent() -> void:
	_appear()
	bar.bar_width = 100.0
	var xs := []
	for i in range(1, KaijuHealthBar.DIVISIONS):
		xs.append(bar.divider_x(i))
	assert_eq(KaijuHealthBar.DIVISIONS, 10)
	assert_eq(xs.size(), 9)
	assert_eq(xs, [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0])


func test_drawn_above_buildings() -> void:
	assert_false(bar.z_as_relative)
	assert_eq(bar.z_index, RenderingServer.CANVAS_ITEM_Z_MAX)
	assert_gt(bar.z_index, run.map.top_z_index())


func test_colours() -> void:
	assert_gt(KaijuHealthBar.FILL_COLOR.b, 0.9)
	assert_gt(KaijuHealthBar.FILL_COLOR.r, KaijuHealthBar.FILL_COLOR.g)
	assert_eq(KaijuHealthBar.BACK_COLOR, Color.WHITE)
	assert_eq(KaijuHealthBar.LINE_COLOR, Color.BLACK)
	var c := KaijuHealthBar.FILL_COLOR
	assert_false(c.r > 0.8 and c.g < 0.3 and c.b < 0.3, "not red")
