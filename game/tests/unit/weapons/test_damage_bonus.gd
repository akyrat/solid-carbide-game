extends GutTest
## Task T-062: the garage's damage bonus reaches both weapons.

const RunScene := preload("res://scenes/run/run.tscn")
const FlameScript := preload("res://scripts/weapons/flamethrower/exhaust_flamethrower.gd")
var PATH := RunPaths.file("test_progress_t062.json")
var run: Node2D
var rack: Node


func before_each() -> void:
	DirAccess.remove_absolute(PATH)
	FlameScript.playtest_override = 1  # the flamethrower is owned from the start
	run = RunScene.instantiate()
	add_child_autofree(run)
	run.minions.enabled = false
	rack = run.weapons


func after_each() -> void:
	FlameScript.playtest_override = -1
	DirAccess.remove_absolute(PATH)


func test_level_0_changes_nothing() -> void:
	var p := PlayerProgress.new(null, PATH)
	rack.set_damage_bonus(p.current_value("damage_bonus"))
	assert_eq(float(rack.gun.stats["damage"]), 2.0)
	assert_eq(float(rack.flamethrower.stats["damage"]), 2.0)


func test_higher_level_raises_both_weapons() -> void:
	var p := PlayerProgress.new(null, PATH)
	p.coins = 100000
	assert_true(p.buy("damage_bonus")["ok"])
	var pct := p.current_value("damage_bonus")
	assert_gt(pct, 0.0)
	rack.set_damage_bonus(pct)
	assert_almost_eq(float(rack.gun.stats["damage"]), 2.0 * (1.0 + pct / 100.0), 0.0001)
	assert_almost_eq(float(rack.flamethrower.stats["damage"]), 2.0 * (1.0 + pct / 100.0), 0.0001)


func test_bonus_stacks_with_tiers_and_survives_new_run() -> void:
	rack.set_damage_bonus(50.0)
	var base := WeaponData.new().flame_at(5)["damage"] as float
	rack.upgrade("gun")
	assert_almost_eq(float(rack.gun.stats["damage"]), WeaponData.new().gun_at(2)["damage"] * 1.5, 0.0001)
	rack.flamethrower.set_tier(5)
	assert_almost_eq(float(rack.flamethrower.stats["damage"]), base * 1.5, 0.0001)
	rack.reset_for_run()
	assert_almost_eq(float(rack.gun.stats["damage"]), 3.0, 0.0001)
