extends GutTest
## Task T-528: the cooldown on a power-up slot's icon, like a loading bar (HUD and menus,
## Decisions, "Weapon and power-up slots").

const HUD_SCENE := preload("res://scenes/hud/hud.tscn")
const WHEEL := "polarized_steering_wheel"


class StubWheel extends RefCounted:
	signal ready_again
	var left := 0.0

	func cooldown_fraction_left() -> float:
		return left


func _hud_with_wheel(stub: Object) -> Array:
	var sv := SubViewport.new()
	sv.size = Vector2i(1152, 648)
	add_child_autofree(sv)
	var hud: Hud = HUD_SCENE.instantiate()
	sv.add_child(hud)
	var state := RunState.new()
	hud.bind(state)
	hud.weapon_icons.bind_cooldown(WHEEL, stub)
	state.set_power_up_tier(WHEEL, 1)
	return [hud, state]


func test_veil_follows_the_fraction_at_0_half_and_1() -> void:
	var c := SlotCooldown.new()
	add_child_autofree(c)
	c.set_fraction(0.0)
	assert_eq(c.veil_rect().size.y, 0.0, "ready: nothing veiled")
	c.set_fraction(0.5)
	assert_eq(c.veil_rect().size.y, 24.0, "half: the top half veiled")
	c.set_fraction(1.0)
	assert_eq(c.veil_rect().size.y, 48.0, "just fired: the whole slot veiled")
	assert_eq(c.veil_rect().size.x, 48.0)


func test_veil_moves_in_whole_pixel_steps() -> void:
	var c := SlotCooldown.new()
	add_child_autofree(c)
	c.set_fraction(0.33)
	assert_eq(int(c.veil_rect().size.y) % SlotCooldown.STEP, 0)


func test_fraction_is_clamped() -> void:
	var c := SlotCooldown.new()
	add_child_autofree(c)
	c.set_fraction(3.0)
	assert_eq(c.fraction_left, 1.0)
	c.set_fraction(-1.0)
	assert_eq(c.fraction_left, 0.0)


func test_source_without_the_method_is_always_ready() -> void:
	var c := SlotCooldown.new()
	add_child_autofree(c)
	c.set_fraction(1.0)
	c.bind_source(RefCounted.new())
	assert_eq(c.fraction_left, 0.0, "today's wheel has no cooldown: full")
	c.bind_source(null)
	assert_eq(c.fraction_left, 0.0)


func test_ready_again_flashes_then_fades() -> void:
	var stub := StubWheel.new()
	var c := SlotCooldown.new()
	add_child_autofree(c)
	c.bind_source(stub)
	assert_eq(c.flash_alpha(), 0.0, "no flash before")
	stub.ready_again.emit()
	assert_almost_eq(c.flash_alpha(), SlotCooldown.FLASH_ALPHA, 0.001)
	c._process(SlotCooldown.FLASH_SECONDS + 0.01)
	assert_eq(c.flash_alpha(), 0.0, "gone after the flash")


func test_slot_icon_shows_the_wheels_cooldown() -> void:
	var stub := StubWheel.new()
	var p := _hud_with_wheel(stub)
	var icons: WeaponIcons = p[0].weapon_icons
	assert_true(icons.power_cooldowns.has(WHEEL), "the wheel's slot has a veil")
	var veil: SlotCooldown = icons.power_cooldowns[WHEEL]
	stub.left = 1.0
	veil._process(0.016)
	assert_eq(veil.veil_rect().size.y, 48.0, "spent right after a burst")
	stub.left = 0.5
	veil._process(0.016)
	assert_eq(veil.veil_rect().size.y, 24.0)
	stub.left = 0.0
	veil._process(0.016)
	assert_eq(veil.veil_rect().size.y, 0.0, "full again")


func test_other_slots_have_no_cooldown_drawn() -> void:
	var stub := StubWheel.new()
	var p := _hud_with_wheel(stub)
	p[1].set_power_up_tier("jump", 1)
	stub.left = 1.0
	for id in p[0].weapon_icons.power_cooldowns:
		var veil: SlotCooldown = p[0].weapon_icons.power_cooldowns[id]
		veil._process(0.016)
		if id != WHEEL:
			assert_eq(veil.veil_rect().size.y, 0.0, "%s is unchanged" % id)
